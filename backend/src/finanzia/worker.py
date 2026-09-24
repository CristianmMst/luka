"""Composition root del worker arq: misma imagen Docker, proceso separado (spec 003 SS2.4).

Cablea los 4 consumers del pipeline de captura (spec 006 SS4, F2.2/F2.5/F2.6):
`ingestion.RawMessageReceived` (grupo `parsing`) -> `parsing.TransactionParsed`
(grupo `ledger`) / `parsing.ParseFailed` (grupo `ledger-review`) -> y el
observador `ledger.TransactionCaptured` (grupo `ledger-observer`, F1.8: solo
loguea que llego el evento, nunca su monto ni otros datos sensibles, spec 009
SS5, P1). Este modulo (D7) solo ensambla: las fabricas finas de cada handler
viven en `modules/<m>/infrastructure/consumers.py`; `finanzia.worker` no esta
en la lista de modulos independientes de R4 (import-linter), asi que puede
importarlas directo.

`parsing`: se importa por su fachada (`finanzia.modules.parsing.public`, que
ya reexporta `make_raw_message_received_handler`/`build_llm_parser`/etc.), NO
por `infrastructure.consumers` directo — entrar al modulo por ahi dispara un
import circular real en produccion (`parsing.infrastructure.consumers` ->
`parsing.infrastructure.raw_message_gateway` -> `ingestion.public` ->
`ingestion.infrastructure.sender_policy` -> `parsing.public` ->
`parsing.infrastructure.consumers`, con este ultimo modulo aun a medio
inicializar): en la suite de tests nunca se manifiesta porque algo mas
(`finanzia.app`, u otro test) ya importo `parsing.public` primero, pero en el
proceso del worker (arq), que no importa `finanzia.app`, es el primer punto de
entrada al ciclo y revienta con `ImportError: cannot import name ... from
partially initialized module` (visto en la verificacion Docker de esta tarea).
`ledger`: `ledger.public` NO exporta `make_transaction_parsed_handler`/
`make_parse_failed_handler` (ver su `__all__`), asi que esos dos se importan
desde `finanzia.modules.ledger.infrastructure.consumers` directo (permitido
para un composition root, controller ruling de esta tarea); ese modulo no
tiene el mismo ciclo (no importa `ingestion.public`).
"""

from __future__ import annotations

import asyncio
from typing import TYPE_CHECKING, Any, ClassVar, TypedDict
from uuid import UUID

import httpx
import redis.asyncio as redis_asyncio
import redis.exceptions
import structlog
from arq import Retry, cron
from arq.connections import RedisSettings

from finanzia.events_registry import CONSUMER_GROUPS, build_registry, ensure_consumer_groups
from finanzia.modules.ingestion import public as ingestion_public
from finanzia.modules.ingestion.infrastructure.gmail_client import build_gmail_client
from finanzia.modules.ledger.infrastructure.consumers import (
    make_parse_failed_handler,
    make_transaction_parsed_handler,
)
from finanzia.modules.parsing import public as parsing_public
from finanzia.shared.clock import SystemClock
from finanzia.shared.db.engine import create_engine, create_session_factory
from finanzia.shared.events.consumer import StreamConsumer
from finanzia.shared.events.redis_streams import RedisStreamsEventBus
from finanzia.shared.logging import configure_logging
from finanzia.shared.settings import get_settings

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable

    from finanzia.shared.events.port import EventHandler

_logger = structlog.get_logger()


class _ConsumerKwargs(TypedDict, total=False):
    """Override opcional de `StreamConsumer` (solo `block_ms`, ver `on_startup`).

    `TypedDict` en vez de `dict[str, int]`: con un `dict` homogeneo, pyright
    exige que TODOS los parametros de `StreamConsumer.__init__` acepten `int`
    al esparcir `**consumer_kwargs` (revienta contra `consumer_name: str |
    None`); un `TypedDict` valida por nombre de clave, solo contra `block_ms`.
    """

    block_ms: int


_LEDGER_OBSERVER_EVENT_TYPE = "ledger.TransactionCaptured"
_SUPERVISOR_RESTART_DELAY_S = 1.0

# `ensure_consumer_groups` no debe poder colgar el arranque del worker para siempre
# (mismo riesgo/mitigacion que el lifespan de la API, ver `app.py`).
_CONSUMER_GROUPS_TIMEOUT_S = 2.0
# `socket_connect_timeout` mismo valor que `app.py` (deferred finding Task 2): sin
# el, un Redis que acepta la conexion TCP pero nunca responde deja al worker
# colgado para siempre. `socket_timeout`, en cambio, NO puede copiar el de
# `app.py` (5.0s): a diferencia de la API (sin lecturas bloqueantes), este
# cliente lo comparte `StreamConsumer`, cuyo `XREADGROUP ... BLOCK 5000` es
# bloqueante por diseno y ya tiene su propio limite (`_read_new`, `asyncio.
# wait_for(..., timeout=block_ms/1000 + 1)` = 6s con el `block_ms` por defecto).
# Un `socket_timeout` de 5.0s competiria con eso y cortaria la lectura en
# BLOCK antes de que el propio Redis la resuelva, spameando
# `event_consumer_backend_error` cada ciclo de poll en vacio (visto en la
# verificacion Docker de esta tarea). 10s deja margen sobre esos 6s.
_REDIS_CONNECT_TIMEOUT_S = 2.0
_REDIS_SOCKET_TIMEOUT_S = 10.0

# Clave de `ctx` que un test puede precargar antes de llamar `on_startup(ctx)`
# directo, para bajar el `block_ms` de sus `StreamConsumer` (ver el comentario en
# `on_startup`, fix round 1 Task 9). Nunca la usa produccion (arq llama
# `on_startup({})`).
_TEST_CONSUMER_BLOCK_MS_CTX_KEY = "_test_consumer_block_ms"
# Cota dura sobre `asyncio.gather(*tasks)` en `on_shutdown`: sin esto, una tarea
# que por algun motivo no respondiera a `stop` (p. ej. bloqueada dentro de un
# `XREADGROUP ... BLOCK` largo) dejaria `on_shutdown` colgado para siempre. Con
# el `block_ms` de produccion (5000ms) cada consumer responde a `stop` en <=6s
# (ver arriba), asi que 15s deja margen de sobra para los 4 a la vez; fail-soft
# (loguea y sigue cerrando http/engine/redis) en vez de propagar.
_SHUTDOWN_TASKS_TIMEOUT_S = 15.0


async def ping(ctx: dict[str, Any]) -> str:
    """Job de humo: confirma que el worker arq esta vivo y procesa jobs."""
    del ctx
    return "pong"


async def log_transaction_captured(event: object) -> None:
    """Observador Fase 1 de `ledger.TransactionCaptured`: solo metadatos (P1)."""
    _logger.info(
        "transaction_captured_observed",
        event_type=getattr(event, "event_type", None),
        event_id=str(getattr(event, "event_id", "")),
        transaction_id=str(getattr(event, "transaction_id", "")),
    )


async def purge_raw_message_bodies(ctx: dict[str, Any]) -> None:
    """Cron diario 08:00 UTC = 03:00 Bogota: anula `raw_messages.body` vencido
    (spec 004 §6, riesgo P6).

    Nunca loguea el cuerpo purgado ni ningun otro dato crudo del mensaje, solo el
    conteo de filas afectadas.
    """
    session_factory = ctx.get("events_session_factory")
    if session_factory is None:
        # `on_startup` no llego a poblar `ctx` (p. ej. murio a mitad): mejor
        # loguear y salir que reventar el job con un `KeyError`.
        _logger.warning("cron_sin_contexto", job="purge_raw_message_bodies")
        return
    clock = SystemClock()
    async with session_factory() as session:
        count = await ingestion_public.purge_expired_bodies(session, clock.now())
    _logger.info("raw_message_bodies_purged", count=count)


async def renew_gmail_watches(ctx: dict[str, Any]) -> None:
    """Cron diario 08:00 UTC = 03:00 Bogota (mismo horario que la purga, F3.5):
    renueva el watch de Gmail de toda conexion `active` cuyo `watch_expires_at`
    venza dentro de las proximas 48h (spec 006 §2.1).

    Un fallo en una conexion nunca corta las demas (`RenewGmailWatches`): un
    `GmailAuthRevoked` la deja `revoked`, cualquier otro error de Gmail o un
    token indescifrable la deja `error`. Solo loguea contadores, nunca el email
    de la cuenta ni el refresh token (P1/P6).
    """
    session_factory = ctx.get("events_session_factory")
    gmail = ctx.get("gmail_client")
    if session_factory is None or gmail is None:
        _logger.warning("cron_sin_contexto", job="renew_gmail_watches")
        return
    clock = SystemClock()
    async with session_factory() as session:
        summary = await ingestion_public.renew_gmail_watches(session, gmail, clock, get_settings())
    _logger.info(
        "gmail_watches_renewed",
        renewed=summary.renewed,
        revoked=summary.revoked,
        errored=summary.errored,
    )


async def requeue_pending_raw_messages(ctx: dict[str, Any]) -> None:
    """Cron cada 15 min: republica `RawMessageReceived` para `raw_messages` `pending`
    huerfanos (riesgo 4 / D9, mitiga la falta de outbox sin outbox).
    """
    session_factory = ctx.get("events_session_factory")
    bus = ctx.get("events_bus")
    if session_factory is None or bus is None:
        _logger.warning("cron_sin_contexto", job="requeue_pending_raw_messages")
        return
    clock = SystemClock()
    async with session_factory() as session:
        summary = await ingestion_public.requeue_pending_raw_messages(session, bus, clock)
    _logger.info("raw_messages_requeued", count=summary.requeued, exhausted=summary.exhausted)


# Reintentos de `sync_gmail` ante un `GmailTransientError` (red, 5xx, 429, 401 de
# Gmail): arq solo reintenta si el job lanza `Retry`, hasta `max_tries` (5 por
# defecto) intentos en total; el backoff es lineal (30 s, 60 s, ...).
_SYNC_GMAIL_RETRY_BASE_S = 30


async def sync_gmail(ctx: dict[str, Any], user_id: str, history_id: int | None = None) -> None:
    """Job encolado por el webhook push (spec 006 §2.1, F3.4): sincroniza el buzon
    del usuario desde su cursor e ingiere los correos nuevos.

    Solo loguea contadores y el estado de cada pasada; nunca el email de la cuenta,
    remitentes, asuntos ni cuerpos (spec 009 §5).
    """
    session_factory = ctx.get("events_session_factory")
    bus = ctx.get("events_bus")
    redis_client = ctx.get("events_redis")
    gmail = ctx.get("gmail_client")
    if session_factory is None or bus is None or redis_client is None or gmail is None:
        _logger.warning("job_sin_contexto", job="sync_gmail")
        return
    try:
        results = await ingestion_public.run_gmail_sync(
            session_factory=session_factory,
            redis_client=redis_client,
            event_bus=bus,
            gmail=gmail,
            clock=SystemClock(),
            settings=get_settings(),
            user_id=UUID(user_id),
            history_id=history_id,
        )
    except ingestion_public.GmailTransientError as exc:
        job_try = int(ctx.get("job_try") or 1)
        _logger.warning("gmail_sync_retry", error_type=type(exc).__name__, job_try=job_try)
        raise Retry(defer=_SYNC_GMAIL_RETRY_BASE_S * job_try) from exc
    if not results:
        _logger.info("gmail_sync_skipped", reason="lock_held")
    for result in results:
        _logger.info(
            "gmail_sync_finished",
            status=result.status,
            resync=result.resync,
            fetched=result.fetched,
            accepted=result.accepted,
            duplicates=result.duplicates,
            discarded=result.discarded,
            skipped=result.skipped,
        )


async def _supervise(
    coro_factory: Callable[[], Awaitable[None]],
    stop: asyncio.Event,
    *,
    event_type: str,
    group: str,
) -> None:
    """Ultima red de seguridad sobre `coro_factory()` (normalmente `consumer.run(stop)`).

    `StreamConsumer.run` ya es fail-soft ante errores de Redis (los loguea y
    reintenta sin retornar), pero esto cubre cualquier otra excepcion inesperada
    que la termine: en vez de dejar el consumer muerto en silencio para siempre,
    se loguea y se reinicia tras `_SUPERVISOR_RESTART_DELAY_S`, hasta que `stop`
    se marque.
    """
    while not stop.is_set():
        try:
            await coro_factory()
        except Exception as exc:  # cualquier falla inesperada reinicia el consumer
            if stop.is_set():
                return
            _logger.warning(
                "event_consumer_restarted",
                event_type=event_type,
                group=group,
                error_type=type(exc).__name__,
            )
            await asyncio.sleep(_SUPERVISOR_RESTART_DELAY_S)
        else:
            # `coro_factory()` no deberia retornar sin excepcion mientras `stop` este
            # sin marcar (`consumer.run(stop)` solo retorna cuando `stop` se marca),
            # pero si ocurre, dormir igual evita un loop caliente reintentando sin
            # pausa (review final, item J).
            if not stop.is_set():
                _logger.warning(
                    "event_consumer_returned_unexpectedly", event_type=event_type, group=group
                )
                await asyncio.sleep(_SUPERVISOR_RESTART_DELAY_S)


async def on_startup(ctx: dict[str, Any]) -> None:
    """Ensambla engine/redis/bus/LLM y arranca los 4 consumers como tareas de fondo."""
    settings = get_settings()
    configure_logging(settings)

    engine = create_engine(settings)
    session_factory = create_session_factory(engine)
    # Nombrado `redis_client` (no `redis`, controller ruling): el modulo `redis`
    # (import de arriba, usado abajo para `redis.exceptions.RedisError`) quedaria
    # tapado por la variable local en el resto de esta funcion (fix round 1).
    redis_client = redis_asyncio.from_url(
        str(settings.redis_url),
        decode_responses=False,
        socket_connect_timeout=_REDIS_CONNECT_TIMEOUT_S,
        socket_timeout=_REDIS_SOCKET_TIMEOUT_S,
    )
    registry = build_registry()
    bus = RedisStreamsEventBus(redis_client, registry)
    try:
        await asyncio.wait_for(ensure_consumer_groups(bus), timeout=_CONSUMER_GROUPS_TIMEOUT_S)
    except (redis.exceptions.RedisError, OSError, TimeoutError) as exc:
        _logger.warning("consumer_groups_not_ensured", error_type=type(exc).__name__)

    clock = SystemClock()
    http_client = httpx.AsyncClient(timeout=settings.llm_timeout_seconds)
    llm = parsing_public.build_llm_parser(settings, http_client)
    # Mismo cliente httpx: `GoogleGmailClient` fija su propio timeout por request.
    # Lo usaran los jobs de Gmail (renovar watch, sync); se construye aqui para
    # que el worker tenga un unico punto de composicion (F3.3).
    gmail_client = build_gmail_client(settings, http_client)
    budget = parsing_public.RedisLlmBudget(redis_client)
    metrics = parsing_public.StructlogMetrics()
    config = parsing_public.load_parsing_config()

    _logger.info(
        "worker_llm_status", enabled=llm.enabled, model=settings.deepseek_model
    )  # nunca la api key (P1)
    if not llm.enabled:
        _logger.warning("llm_disabled_no_api_key")

    parsing_handler = parsing_public.make_raw_message_received_handler(
        session_factory=session_factory,
        event_bus=bus,
        clock=clock,
        llm=llm,
        budget=budget,
        registry=config.templates,
        known_banks=config.senders.known_banks(),
        metrics=metrics,
        settings=settings,
    )
    ledger_transaction_handler = make_transaction_parsed_handler(
        session_factory=session_factory, event_bus=bus, clock=clock
    )
    ledger_review_handler = make_parse_failed_handler(session_factory=session_factory, clock=clock)

    handlers_by_event_type: dict[str, EventHandler] = {
        "ingestion.RawMessageReceived": parsing_handler,
        "parsing.TransactionParsed": ledger_transaction_handler,
        "parsing.ParseFailed": ledger_review_handler,
        _LEDGER_OBSERVER_EVENT_TYPE: log_transaction_captured,
    }

    # `_TEST_CONSUMER_BLOCK_MS_CTX_KEY` (fix round 1, Task 9): un test que llama a
    # `on_startup(ctx)` directo puede precargar `ctx` con esta clave para bajar el
    # `block_ms` de sus `StreamConsumer` (p. ej. a 200ms, igual que
    # `PipelineHarness`) y asi hacer que `on_shutdown` responda a `stop` casi al
    # instante en vez de esperar hasta ~6s (block_ms/1000+1 de
    # `StreamConsumer._read_new`) por consumer. arq nunca pasa esta clave (llama
    # `on_startup({})`), asi que en produccion el kwarg se omite del todo y
    # `StreamConsumer` usa su propio default — cero riesgo de drift.
    test_block_ms = ctx.get(_TEST_CONSUMER_BLOCK_MS_CTX_KEY)
    consumer_kwargs: _ConsumerKwargs = (
        {"block_ms": test_block_ms} if test_block_ms is not None else {}
    )

    stop = asyncio.Event()
    tasks: list[asyncio.Task[None]] = []
    for event_type, group in CONSUMER_GROUPS:
        consumer = StreamConsumer(
            bus,
            redis_client,
            registry,
            group=group,
            event_type=event_type,
            handler=handlers_by_event_type[event_type],
            **consumer_kwargs,
        )
        tasks.append(
            asyncio.create_task(
                _supervise(lambda c=consumer: c.run(stop), stop, event_type=event_type, group=group)
            )
        )

    # Claves propias (no "redis"/"pool"): arq ya usa `ctx["redis"]` para su propio
    # pool de colas; reusar ese nombre pisaria la conexion que arq necesita.
    ctx["events_engine"] = engine
    ctx["events_redis"] = redis_client
    ctx["events_http_client"] = http_client
    ctx["events_stop"] = stop
    ctx["events_tasks"] = tasks
    # Task 10: los crons (`purge_raw_message_bodies`, `requeue_pending_raw_messages`)
    # necesitan abrir su propia sesion por corrida y publicar en el mismo bus que los
    # consumers; se guardan aqui (additive, no restructura lo de arriba).
    ctx["events_session_factory"] = session_factory
    ctx["events_bus"] = bus
    ctx["gmail_client"] = gmail_client


async def on_shutdown(ctx: dict[str, Any]) -> None:
    """Detiene los consumers, espera sus tareas (acotado) y cierra http/engine/redis."""
    stop: asyncio.Event | None = ctx.get("events_stop")
    if stop is not None:
        stop.set()
    tasks: list[asyncio.Task[None]] = ctx.get("events_tasks") or []
    if tasks:
        try:
            await asyncio.wait_for(
                asyncio.gather(*tasks, return_exceptions=True), timeout=_SHUTDOWN_TASKS_TIMEOUT_S
            )
        except TimeoutError:
            # Fail-soft (fix round 1, Task 9): no deberia pasar nunca (cada consumer
            # responde a `stop` en <=block_ms/1000+1s), pero si pasa, no dejar
            # `on_shutdown` colgado para siempre — loguear y seguir cerrando
            # http/engine/redis igual. Las tareas que no llegaron a tiempo siguen
            # vivas (no se cancelan a la fuerza): `asyncio.Task.cancel()` sobre un
            # consumer a medio `XACK`/commit podria dejar estado a medias.
            still_running = sum(1 for task in tasks if not task.done())
            _logger.warning("event_consumer_shutdown_timed_out", still_running=still_running)

    http_client = ctx.get("events_http_client")
    if http_client is not None:
        await http_client.aclose()

    engine = ctx.get("events_engine")
    if engine is not None:
        await engine.dispose()

    redis_client = ctx.get("events_redis")
    if redis_client is not None:
        await redis_client.aclose()


class WorkerSettings:
    """Configuracion de arq (spec 003 SS2.4): mismo Docker image, proceso separado."""

    functions: ClassVar[list[Any]] = [ping, sync_gmail]
    # Task 10 (F3.7 adelantado, riesgo 4): purga diaria de cuerpos (spec 004 §6) y
    # reencolado de `raw_messages` `pending` huerfanos (cada 15 min, D9).
    #
    # `arq.cron` agenda contra el reloj del PROCESO, y la imagen slim no define
    # `TZ`, asi que el contenedor corre en UTC: `hour=8` = 03:00 en Colombia
    # (America/Bogota, UTC-5 fijo, sin horario de verano), la hora tranquila que
    # documenta la spec. Con `hour=3` la purga caia a las 22:00 de Bogota, en
    # plena franja de uso. No se usa un cron con zona horaria (arq no lo soporta):
    # el offset de Colombia es constante, asi que la conversion fija alcanza.
    cron_jobs: ClassVar[list[Any]] = [
        cron(purge_raw_message_bodies, hour=8, minute=0, run_at_startup=False),
        cron(requeue_pending_raw_messages, minute={0, 15, 30, 45}, run_at_startup=False),
        # F3.5: mismo horario que la purga (08:00 UTC = 03:00 Bogota, ver arriba).
        cron(renew_gmail_watches, hour=8, minute=0, run_at_startup=False),
    ]
    redis_settings = RedisSettings.from_dsn(str(get_settings().redis_url))
    on_startup = on_startup
    on_shutdown = on_shutdown
    job_timeout = 300
    max_jobs = 10
