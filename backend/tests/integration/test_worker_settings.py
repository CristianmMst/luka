"""Integration: `arq.Worker` con `luka.worker.WorkerSettings` (spec 003 SS2.4, F1.8).

`luka.worker` calcula `WorkerSettings.redis_settings` a nivel de modulo
(`RedisSettings.from_dsn(str(get_settings().redis_url))`); por eso el import de
`luka.worker` debe ocurrir *despues* de fijar las variables `LUKA_*` de test
(incluida la Redis de test, db 1) y de limpiar el cache de `get_settings`. El
fixture `worker_settings_module` hace ese import de forma perezosa, dentro del
propio test, para garantizar el orden.

En Windows, `arq.Worker(handle_signals=True)` (el default) llama
`loop.add_signal_handler`, no soportado por el loop de asyncio en Windows; por eso
el `Worker` de este test se construye con `handle_signals=False` (produccion corre
en Linux, donde `worker.py` mantiene los defaults).
"""

import asyncio
import signal
from collections.abc import Awaitable, Callable
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import uuid4

import httpx
import pytest
import structlog.testing
from arq import Retry, Worker, create_pool
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.fake_google import FakeGoogle
from support.gmail_connections import insert_gmail_connection
from support.raw_messages import insert_raw_message
from support.settings import GOOGLE_ENV

from luka.modules.ingestion import public as ingestion_public
from luka.modules.ingestion.infrastructure import gmail_sync as gmail_sync_infra
from luka.modules.ingestion.infrastructure.gmail_client import GoogleGmailClient
from luka.modules.ingestion.infrastructure.gmail_sync import SYNC_GMAIL_TIMEOUT_S
from luka.modules.ingestion.infrastructure.token_cipher import AesGcmTokenCipher
from luka.shared.settings import Settings, get_settings

pytestmark = pytest.mark.integration

# Fix round 1 (review Task 9, finding 2): los tests que llaman `on_startup(ctx)`
# directo controlan `ctx` por completo, asi que pueden precargar la clave de
# prueba `_test_consumer_block_ms` (ver `luka.worker`) para que los 4
# `StreamConsumer` respondan a `stop` casi al instante en `on_shutdown`, en vez
# de hasta ~6s (block_ms/1000+1 de produccion) cada uno. Sin esto, cada test que
# arranca+apaga consumers reales tardaba varios segundos, y una tarea que
# tardara justo lo suficiente en volver a chequear `stop` podia solaparse con el
# `redis_clean`/`db_clean` del siguiente test (misma suite, mismo loop de
# asyncio de sesion) y disparar `NOGROUP`/colisiones de datos intermitentes.
_TEST_CONSUMER_BLOCK_MS = 50


def _new_worker_ctx() -> dict[str, Any]:
    """`ctx` base para llamar `on_startup`/`on_shutdown` directo en un test."""
    return {"_test_consumer_block_ms": _TEST_CONSUMER_BLOCK_MS}


@pytest.fixture(autouse=True)
def _sigusr1_shim(monkeypatch: pytest.MonkeyPatch) -> None:
    """Windows no define `signal.SIGUSR1`. `Worker.close()` lo referencia sin
    guardas cuando `handle_signals=False`, solo para loguear un pseudo-shutdown
    (no registra ni envia ninguna senal real). En produccion esto corre en Linux,
    donde `SIGUSR1` siempre existe y `worker.py` no toca este shim.
    """
    if not hasattr(signal, "SIGUSR1"):
        monkeypatch.setattr(signal, "SIGUSR1", signal.SIGTERM, raising=False)


@pytest.fixture
def worker_settings_module(monkeypatch: pytest.MonkeyPatch, settings: Settings):
    monkeypatch.setenv("LUKA_ENV", "test")
    monkeypatch.setenv("LUKA_DATABASE_URL", str(settings.database_url))
    monkeypatch.setenv("LUKA_REDIS_URL", str(settings.redis_url))
    monkeypatch.setenv("LUKA_JWT_SECRET", settings.jwt_secret.get_secret_value())
    for name, value in GOOGLE_ENV.items():
        monkeypatch.setenv(name, value)
    get_settings.cache_clear()

    # Import perezoso, deliberado: `luka.worker` calcula `redis_settings` a
    # nivel de modulo a partir de `get_settings()`, y debe ejecutarse *despues* de
    # fijar las variables LUKA_* de arriba (ver docstring del modulo).
    import luka.worker as worker_module  # noqa: PLC0415

    try:
        yield worker_module
    finally:
        get_settings.cache_clear()


async def test_worker_ejecuta_ping_en_modo_burst(worker_settings_module, redis_clean: None) -> None:
    del redis_clean
    worker_settings = worker_settings_module.WorkerSettings

    pool = await create_pool(worker_settings.redis_settings)
    try:
        job = await pool.enqueue_job("ping")
        assert job is not None

        worker = Worker(
            functions=worker_settings.functions,
            redis_settings=worker_settings.redis_settings,
            on_startup=worker_settings.on_startup,
            on_shutdown=worker_settings.on_shutdown,
            burst=True,
            handle_signals=False,
            poll_delay=0,
        )
        try:
            await worker.main()
        finally:
            await worker.close()

        result = await job.result(poll_delay=0.01)
    finally:
        await pool.aclose()

    assert result == "pong"

    lingering = [
        task
        for task in asyncio.all_tasks()
        if task is not asyncio.current_task() and not task.done()
    ]
    assert lingering == []


async def test_supervise_reinicia_tras_una_excepcion_inesperada(worker_settings_module) -> None:
    """Fix round 1 (review Task 14): `_supervise` es la ultima red de seguridad
    sobre un consumer que termina con una excepcion inesperada (no cubierta ya por
    el propio fail-soft de `StreamConsumer.run`): lo reinicia en vez de dejarlo
    muerto en silencio.
    """
    calls = {"n": 0}
    stop = asyncio.Event()

    async def flaky() -> None:
        calls["n"] += 1
        if calls["n"] == 1:
            msg = "boom"
            raise RuntimeError(msg)
        stop.set()  # segundo intento: termina normal, sin excepcion

    await worker_settings_module._supervise(
        flaky, stop, event_type="test.Event", group="test-group"
    )

    assert calls["n"] == 2
    assert stop.is_set()


async def test_supervise_duerme_si_run_retorna_normal_sin_stop_marcado(
    worker_settings_module, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Review final (item J): si `coro_factory()` retorna sin excepcion y sin que
    `stop` quede marcado (no deberia pasar con `consumer.run`, pero es la ultima
    red de seguridad), `_supervise` debe dormir igual antes de reintentar, en vez
    de reintentar en un loop caliente sin pausa.
    """
    calls = {"n": 0}
    sleep_calls: list[float] = []
    stop = asyncio.Event()

    async def _fake_sleep(delay: float) -> None:
        sleep_calls.append(delay)

    monkeypatch.setattr(worker_settings_module.asyncio, "sleep", _fake_sleep)

    async def returns_without_setting_stop() -> None:
        calls["n"] += 1
        if calls["n"] == 2:
            stop.set()
        # primer intento: retorna normal SIN marcar stop (el caso a cubrir)

    await worker_settings_module._supervise(
        returns_without_setting_stop, stop, event_type="test.Event", group="test-group"
    )

    assert calls["n"] == 2
    assert stop.is_set()
    assert sleep_calls == [worker_settings_module._SUPERVISOR_RESTART_DELAY_S]


async def test_on_startup_sin_api_key_arranca_4_tareas_y_loguea_estado_deshabilitado(
    worker_settings_module,
    monkeypatch: pytest.MonkeyPatch,
    redis_clean: None,
    db_clean: None,
) -> None:
    """Task 9: sin `LUKA_DEEPSEEK_API_KEY` (dev/test), el worker arranca los 4
    consumers igual (`parsing`, `ledger`, `ledger-review`, `ledger-observer`, uno
    por entrada de `CONSUMER_GROUPS`) con el LLM deshabilitado, y lo deja
    explicito en el log de arranque (nunca la api key, P1).

    `redis_clean`/`db_clean` explicitos (fix round 1, finding 2): este test
    arranca consumers reales contra la Redis/DB de test; declararlos aqui deja
    el contrato de aislamiento explicito en vez de depender solo del orden de
    ejecucion con otros archivos.
    """
    del redis_clean, db_clean
    monkeypatch.delenv("LUKA_DEEPSEEK_API_KEY", raising=False)
    get_settings.cache_clear()

    ctx = _new_worker_ctx()
    with structlog.testing.capture_logs() as captured:
        await worker_settings_module.on_startup(ctx)
    try:
        assert len(ctx["events_tasks"]) == 6
        assert all(isinstance(task, asyncio.Task) for task in ctx["events_tasks"])
        assert isinstance(ctx["gmail_client"], GoogleGmailClient)

        status_logs = [e for e in captured if e.get("event") == "worker_llm_status"]
        assert len(status_logs) == 1
        assert status_logs[0]["enabled"] is False
        assert "deepseek_api_key" not in status_logs[0]

        assert any(e.get("event") == "llm_disabled_no_api_key" for e in captured)
    finally:
        await worker_settings_module.on_shutdown(ctx)

    # Fix round 1 (finding 2): antes de que el siguiente test corra su propio
    # `redis_clean`, todas las tareas deben estar `done()` — si alguna sigue viva,
    # su proximo `XREADGROUP`/`ensure_group` puede pisarse con el FLUSHDB del
    # siguiente test (`NOGROUP ResponseError`).
    assert all(task.done() for task in ctx["events_tasks"])


async def test_on_shutdown_cierra_tareas_http_client_engine_y_redis_sin_dejar_nada_colgado(
    worker_settings_module,
    monkeypatch: pytest.MonkeyPatch,
    redis_clean: None,
    db_clean: None,
) -> None:
    """Task 9: `on_shutdown` cancela las 6 tareas supervisadas, cierra el
    `httpx.AsyncClient` compartido y no deja tareas de fondo colgadas.
    """
    del redis_clean, db_clean
    monkeypatch.delenv("LUKA_DEEPSEEK_API_KEY", raising=False)
    get_settings.cache_clear()

    ctx = _new_worker_ctx()
    await worker_settings_module.on_startup(ctx)

    await worker_settings_module.on_shutdown(ctx)

    assert ctx["events_http_client"].is_closed
    assert all(task.done() for task in ctx["events_tasks"])

    lingering = [
        task
        for task in asyncio.all_tasks()
        if task is not asyncio.current_task() and not task.done()
    ]
    assert lingering == []


def test_cron_jobs_tiene_los_seis_jobs_con_sus_horarios(worker_settings_module) -> None:
    """Task 10 (F3.7 adelantado, riesgo 4): purga diaria 08:00 UTC (= 03:00 en
    Bogota, el contenedor corre en UTC) y reencolado cada 15 min
    (`minute={0,15,30,45}`). Task 5 (F3.5): renovacion de watches en el mismo
    horario que la purga. F7.4: ocurrencias de gastos fijos a las 10:00 UTC (= 05:00
    en Bogota). F7.5: recordatorios push a las 14:00 UTC (= 09:00 en Bogota) y purga de
    tokens junto a la de cuerpos. Ninguno corre al arrancar (`run_at_startup=False`).
    """
    cron_jobs = worker_settings_module.WorkerSettings.cron_jobs
    assert len(cron_jobs) == 6

    by_name = {job.name: job for job in cron_jobs}
    assert set(by_name) == {
        "cron:purge_raw_message_bodies",
        "cron:requeue_pending_raw_messages",
        "cron:renew_gmail_watches",
        "cron:ensure_recurring_occurrences",
        "cron:send_recurring_reminders",
        "cron:purge_stale_device_tokens",
    }

    purge_job = by_name["cron:purge_raw_message_bodies"]
    assert purge_job.hour == 8  # UTC = 03:00 America/Bogota (UTC-5 fijo)
    assert purge_job.minute == 0
    assert purge_job.run_at_startup is False

    requeue_job = by_name["cron:requeue_pending_raw_messages"]
    assert requeue_job.minute == {0, 15, 30, 45}
    assert requeue_job.run_at_startup is False

    renew_job = by_name["cron:renew_gmail_watches"]
    assert renew_job.hour == 8
    assert renew_job.minute == 0
    assert renew_job.run_at_startup is False

    recurring_job = by_name["cron:ensure_recurring_occurrences"]
    assert recurring_job.hour == 10  # UTC = 05:00 America/Bogota
    assert recurring_job.minute == 0
    assert recurring_job.run_at_startup is False

    reminders_job = by_name["cron:send_recurring_reminders"]
    assert reminders_job.hour == {14, 22}  # UTC = 09:00 y 17:00 America/Bogota
    assert reminders_job.minute == 0

    tokens_job = by_name["cron:purge_stale_device_tokens"]
    assert tokens_job.hour == 8
    assert tokens_job.minute == 0


@pytest.mark.parametrize(
    "job_name",
    [
        "purge_raw_message_bodies",
        "requeue_pending_raw_messages",
        "renew_gmail_watches",
        "ensure_recurring_occurrences",
        "send_recurring_reminders",
        "purge_stale_device_tokens",
    ],
)
async def test_crons_con_ctx_vacio_loguean_y_no_revientan(worker_settings_module, job_name) -> None:
    """Si `on_startup` murio a mitad, `ctx` no trae las claves de eventos: los crons
    salen temprano con un warning en vez de un `KeyError` (review final A10).
    """
    job = getattr(worker_settings_module, job_name)

    with structlog.testing.capture_logs() as captured:
        await job({})

    logs = [e for e in captured if e.get("event") == "cron_sin_contexto"]
    assert len(logs) == 1
    assert logs[0]["job"] == job_name


async def test_purge_raw_message_bodies_cron_purga_y_loguea_count(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    worker_settings_module,
    monkeypatch: pytest.MonkeyPatch,
    redis_clean: None,
    db_clean: None,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    """El job cron delega en `ingestion.public.purge_expired_bodies` sobre una
    sesion abierta desde `ctx["events_session_factory"]` y loguea solo el conteo
    (nunca el cuerpo purgado, P6).

    `sub`/`email` propios (fix round 1, finding 2): el default de `user_factory`
    (`sub-1`) lo usan decenas de tests de otros archivos; un `sub` propio por
    test de este archivo evita cualquier colision de `uq_users_google_sub` con
    otra suite, con independencia de que `db_clean` ya aisle cada test.
    """
    del redis_clean, db_clean
    monkeypatch.delenv("LUKA_DEEPSEEK_API_KEY", raising=False)
    get_settings.cache_clear()

    user = await user_factory(sub="worker-cron-purge", email="worker-cron-purge@example.com")
    now = datetime.now(UTC)
    vencido = await insert_raw_message(
        session_factory,
        user_id=user.id,
        external_id="cron-purge-vencido",
        received_at=now - timedelta(days=200),
    )

    ctx = _new_worker_ctx()
    await worker_settings_module.on_startup(ctx)
    try:
        with structlog.testing.capture_logs() as captured:
            await worker_settings_module.purge_raw_message_bodies(ctx)

        logs = [e for e in captured if e.get("event") == "raw_message_bodies_purged"]
        assert len(logs) == 1
        # `>= 1` (no `== 1`): el job purga *toda* `raw_messages` (spec 004 §6, no
        # esta acotado por usuario), asi que en una corrida de la suite completa
        # puede sumar filas vencidas de otros tests; lo que importa aqui es que
        # cuenta y loguea, y que nuestra fila vencida especifica quedo purgada
        # (verificado abajo).
        assert logs[0]["count"] >= 1
        assert "body" not in repr(logs[0])
    finally:
        await worker_settings_module.on_shutdown(ctx)

    async with session_factory() as session:
        row = (
            await session.execute(
                text("SELECT body FROM raw_messages WHERE id = :id"), {"id": vencido}
            )
        ).one()
    assert row.body is None


async def test_requeue_pending_raw_messages_cron_republica_huerfanos_y_loguea_count(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    worker_settings_module,
    monkeypatch: pytest.MonkeyPatch,
    redis_clean: None,
    db_clean: None,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    """El job cron delega en `ingestion.public.requeue_pending_raw_messages`, usando
    tanto la sesion (`events_session_factory`) como el bus (`events_bus`) que
    `on_startup` guarda en `ctx` para los consumers.

    `sub`/`email` propios: ver docstring de
    `test_purge_raw_message_bodies_cron_purga_y_loguea_count` (fix round 1,
    finding 2).
    """
    del redis_clean, db_clean
    monkeypatch.delenv("LUKA_DEEPSEEK_API_KEY", raising=False)
    get_settings.cache_clear()

    user = await user_factory(sub="worker-cron-requeue", email="worker-cron-requeue@example.com")
    now = datetime.now(UTC)
    huerfano = await insert_raw_message(
        session_factory, user_id=user.id, external_id="cron-requeue-huerfano", status="pending"
    )
    reciente = await insert_raw_message(
        session_factory, user_id=user.id, external_id="cron-requeue-reciente", status="pending"
    )

    async with session_factory() as session:
        await session.execute(
            text("UPDATE raw_messages SET updated_at = :updated_at WHERE id = :id"),
            {"updated_at": now - timedelta(minutes=20), "id": huerfano},
        )
        await session.execute(
            text("UPDATE raw_messages SET updated_at = :updated_at WHERE id = :id"),
            {"updated_at": now - timedelta(minutes=5), "id": reciente},
        )
        await session.commit()

    ctx = _new_worker_ctx()
    await worker_settings_module.on_startup(ctx)
    try:
        with structlog.testing.capture_logs() as captured:
            await worker_settings_module.requeue_pending_raw_messages(ctx)

        logs = [e for e in captured if e.get("event") == "raw_messages_requeued"]
        assert len(logs) == 1
        assert logs[0]["count"] == 1
    finally:
        await worker_settings_module.on_shutdown(ctx)


# --- renew_gmail_watches (F3.5) --------------------------------------------------------


def test_renew_gmail_watches_esta_registrado_como_cron(worker_settings_module) -> None:
    cron_jobs = worker_settings_module.WorkerSettings.cron_jobs
    assert any(job.name == "cron:renew_gmail_watches" for job in cron_jobs)


async def test_renew_gmail_watches_renueva_y_loguea_solo_contadores(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    worker_settings_module,
    monkeypatch: pytest.MonkeyPatch,
    redis_clean: None,
    db_clean: None,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    """El job cron delega en `ingestion.public.renew_gmail_watches` sobre una
    sesion abierta desde `ctx["events_session_factory"]`, usando el cliente
    Gmail real de `ctx["gmail_client"]` (aqui, sobre `FakeGoogle`), y loguea
    solo los contadores (nunca el email de la cuenta ni el refresh token, P1/P6).
    """
    del redis_clean, db_clean
    monkeypatch.delenv("LUKA_DEEPSEEK_API_KEY", raising=False)
    get_settings.cache_clear()

    user = await user_factory(sub="worker-cron-renew", email="worker-cron-renew@example.com")
    settings = get_settings()
    await insert_gmail_connection(
        session_factory,
        user_id=user.id,
        refresh_token_enc=AesGcmTokenCipher.from_settings(settings).encrypt(
            user.id, "1//refresh-token-secreto"
        ),
        history_id=100,
        watch_expires_at=datetime.now(UTC) + timedelta(hours=10),  # vence en < 48h
    )

    google = FakeGoogle()
    http_client = httpx.AsyncClient(transport=google.transport())

    ctx = _new_worker_ctx()
    await worker_settings_module.on_startup(ctx)
    try:
        ctx["gmail_client"] = worker_settings_module.build_gmail_client(settings, http_client)
        with structlog.testing.capture_logs() as captured:
            await worker_settings_module.renew_gmail_watches(ctx)

        (finished,) = [e for e in captured if e.get("event") == "gmail_watches_renewed"]
        counters = [finished[k] for k in ("renewed", "revoked", "errored", "deferred")]
        assert counters == [1, 0, 0, 0]
        assert "email" not in repr(finished)
        assert "refresh" not in repr(finished)
    finally:
        await http_client.aclose()
        await worker_settings_module.on_shutdown(ctx)

    async with session_factory() as session:
        row = (
            await session.execute(
                text("SELECT watch_expires_at FROM gmail_connections WHERE user_id = :id"),
                {"id": user.id},
            )
        ).one()
    assert row.watch_expires_at is not None


# --- sync_gmail (F3.4) ----------------------------------------------------------------

_FULL_SYNC_CTX_KEYS = (
    "events_session_factory",
    "events_bus",
    "events_redis",
    "gmail_client",
    "redis",
)


def _sync_ctx(**extra: Any) -> dict[str, Any]:
    return {key: object() for key in _FULL_SYNC_CTX_KEYS} | extra


def test_sync_gmail_esta_registrado_como_job(worker_settings_module) -> None:
    functions = worker_settings_module.WorkerSettings.functions
    (job,) = [f for f in functions if getattr(f, "name", None) == "sync_gmail"]
    assert job.coroutine is worker_settings_module.sync_gmail
    # Timeout propio mayor que el global y lock de Redis que lo sobrevive (B5).
    assert job.timeout_s == SYNC_GMAIL_TIMEOUT_S == 900
    assert job.timeout_s > worker_settings_module.WorkerSettings.job_timeout
    assert gmail_sync_infra._LOCK_TTL_S > job.timeout_s


async def test_sync_gmail_con_ctx_vacio_loguea_y_no_revienta(worker_settings_module) -> None:
    with structlog.testing.capture_logs() as captured:
        await worker_settings_module.sync_gmail({}, str(uuid4()), 1)

    assert any(
        e.get("event") == "job_sin_contexto" and e.get("job") == "sync_gmail" for e in captured
    )


async def test_sync_gmail_error_transitorio_pide_reintento_a_arq(
    worker_settings_module, monkeypatch: pytest.MonkeyPatch
) -> None:
    async def transient(**kwargs: Any) -> list[Any]:
        del kwargs
        raise ingestion_public.GmailTransientError("history.list: 503")

    monkeypatch.setattr(ingestion_public, "run_gmail_sync", transient)

    with pytest.raises(Retry) as exc_info:
        await worker_settings_module.sync_gmail(_sync_ctx(job_try=2), str(uuid4()), 5)

    assert exc_info.value.defer_score == 60_000  # backoff lineal: 30 s x intento


async def test_sync_gmail_loguea_solo_contadores(
    worker_settings_module, monkeypatch: pytest.MonkeyPatch
) -> None:
    user_id = uuid4()
    seen: dict[str, Any] = {}

    async def fake_run(**kwargs: Any) -> list[Any]:
        seen.update(kwargs)
        return [ingestion_public.GmailSyncResult("synced", fetched=2, accepted=1, discarded=1)]

    monkeypatch.setattr(ingestion_public, "run_gmail_sync", fake_run)

    with structlog.testing.capture_logs() as captured:
        await worker_settings_module.sync_gmail(_sync_ctx(), str(user_id), 5)

    assert (seen["user_id"], seen["history_id"]) == (user_id, 5)
    (finished,) = [e for e in captured if e.get("event") == "gmail_sync_finished"]
    assert (finished["status"], finished["accepted"], finished["discarded"]) == ("synced", 1, 1)


async def test_sync_gmail_con_el_lock_tomado_loguea_skipped(
    worker_settings_module, monkeypatch: pytest.MonkeyPatch
) -> None:
    async def lock_held(**kwargs: Any) -> list[Any]:
        del kwargs
        return []

    monkeypatch.setattr(ingestion_public, "run_gmail_sync", lock_held)

    with structlog.testing.capture_logs() as captured:
        await worker_settings_module.sync_gmail(_sync_ctx(), str(uuid4()))

    assert any(e.get("event") == "gmail_sync_skipped" for e in captured)
