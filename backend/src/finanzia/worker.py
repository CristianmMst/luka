"""Composition root del worker arq: misma imagen Docker, proceso separado (spec 003 SS2.4).

Fase 1 (F1.8): un unico observador (`ledger-observer`) que solo loguea que llego un
`TransactionCaptured`, nunca su monto ni otros datos sensibles (spec 009 SS5, P1).
"""

from __future__ import annotations

import asyncio
from typing import TYPE_CHECKING, Any, ClassVar

import redis.asyncio as redis_asyncio
import structlog
from arq.connections import RedisSettings

from finanzia.events_registry import CONSUMER_GROUPS, build_registry
from finanzia.shared.events.consumer import StreamConsumer
from finanzia.shared.events.redis_streams import RedisStreamsEventBus
from finanzia.shared.logging import configure_logging
from finanzia.shared.settings import get_settings

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable

_logger = structlog.get_logger()

_LEDGER_OBSERVER_EVENT_TYPE = "ledger.TransactionCaptured"
# Nombre del grupo tomado de `CONSUMER_GROUPS` (F2.2/D10): una unica fuente de
# verdad, compartida con `ensure_consumer_groups` en el lifespan de la API.
_LEDGER_OBSERVER_GROUP = dict(CONSUMER_GROUPS)[_LEDGER_OBSERVER_EVENT_TYPE]
_SUPERVISOR_RESTART_DELAY_S = 1.0


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
    """Configura logging y arranca los consumers de eventos como tareas de fondo."""
    settings = get_settings()
    configure_logging(settings)

    redis = redis_asyncio.from_url(str(settings.redis_url), decode_responses=False)
    registry = build_registry()
    bus = RedisStreamsEventBus(redis, registry)
    stop = asyncio.Event()
    consumer = StreamConsumer(
        bus,
        redis,
        registry,
        group=_LEDGER_OBSERVER_GROUP,
        event_type=_LEDGER_OBSERVER_EVENT_TYPE,
        handler=log_transaction_captured,
    )
    task = asyncio.create_task(
        _supervise(
            lambda: consumer.run(stop),
            stop,
            event_type=_LEDGER_OBSERVER_EVENT_TYPE,
            group=_LEDGER_OBSERVER_GROUP,
        )
    )

    # Claves propias (no "redis"/"pool"): arq ya usa `ctx["redis"]` para su propio
    # pool de colas; reusar ese nombre pisaria la conexion que arq necesita.
    ctx["events_redis"] = redis
    ctx["events_stop"] = stop
    ctx["events_tasks"] = [task]


async def on_shutdown(ctx: dict[str, Any]) -> None:
    """Detiene los consumers, espera sus tareas y cierra la conexion de eventos."""
    stop: asyncio.Event | None = ctx.get("events_stop")
    if stop is not None:
        stop.set()
    tasks = ctx.get("events_tasks") or []
    if tasks:
        await asyncio.gather(*tasks, return_exceptions=True)
    redis = ctx.get("events_redis")
    if redis is not None:
        await redis.aclose()


class WorkerSettings:
    """Configuracion de arq (spec 003 SS2.4): mismo Docker image, proceso separado."""

    functions: ClassVar[list[Any]] = [ping]
    redis_settings = RedisSettings.from_dsn(str(get_settings().redis_url))
    on_startup = on_startup
    on_shutdown = on_shutdown
    job_timeout = 300
    max_jobs = 10
