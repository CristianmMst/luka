"""Integration: `arq.Worker` con `finanzia.worker.WorkerSettings` (spec 003 SS2.4, F1.8).

`finanzia.worker` calcula `WorkerSettings.redis_settings` a nivel de modulo
(`RedisSettings.from_dsn(str(get_settings().redis_url))`); por eso el import de
`finanzia.worker` debe ocurrir *despues* de fijar las variables `FINANZIA_*` de test
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

import pytest
import structlog.testing
from arq import Worker, create_pool
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.raw_messages import insert_raw_message

from finanzia.shared.settings import Settings, get_settings

pytestmark = pytest.mark.integration


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
    monkeypatch.setenv("FINANZIA_ENV", "test")
    monkeypatch.setenv("FINANZIA_DATABASE_URL", str(settings.database_url))
    monkeypatch.setenv("FINANZIA_REDIS_URL", str(settings.redis_url))
    monkeypatch.setenv("FINANZIA_JWT_SECRET", settings.jwt_secret.get_secret_value())
    monkeypatch.setenv("FINANZIA_GOOGLE_CLIENT_ID", settings.google_client_id)
    monkeypatch.setenv("FINANZIA_GOOGLE_VERIFIER", "fake")
    get_settings.cache_clear()

    # Import perezoso, deliberado: `finanzia.worker` calcula `redis_settings` a
    # nivel de modulo a partir de `get_settings()`, y debe ejecutarse *despues* de
    # fijar las variables FINANZIA_* de arriba (ver docstring del modulo).
    import finanzia.worker as worker_module  # noqa: PLC0415

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
    worker_settings_module, monkeypatch: pytest.MonkeyPatch, redis_clean: None
) -> None:
    """Task 9: sin `FINANZIA_DEEPSEEK_API_KEY` (dev/test), el worker arranca los 4
    consumers igual (`parsing`, `ledger`, `ledger-review`, `ledger-observer`, uno
    por entrada de `CONSUMER_GROUPS`) con el LLM deshabilitado, y lo deja
    explicito en el log de arranque (nunca la api key, P1).
    """
    del redis_clean
    monkeypatch.delenv("FINANZIA_DEEPSEEK_API_KEY", raising=False)
    get_settings.cache_clear()

    ctx: dict[str, Any] = {}
    with structlog.testing.capture_logs() as captured:
        await worker_settings_module.on_startup(ctx)
    try:
        assert len(ctx["events_tasks"]) == 4
        assert all(isinstance(task, asyncio.Task) for task in ctx["events_tasks"])

        status_logs = [e for e in captured if e.get("event") == "worker_llm_status"]
        assert len(status_logs) == 1
        assert status_logs[0]["enabled"] is False
        assert "deepseek_api_key" not in status_logs[0]

        assert any(e.get("event") == "llm_disabled_no_api_key" for e in captured)
    finally:
        await worker_settings_module.on_shutdown(ctx)


async def test_on_shutdown_cierra_tareas_http_client_engine_y_redis_sin_dejar_nada_colgado(
    worker_settings_module, monkeypatch: pytest.MonkeyPatch, redis_clean: None
) -> None:
    """Task 9: `on_shutdown` cancela las 4 tareas supervisadas, cierra el
    `httpx.AsyncClient` compartido y no deja tareas de fondo colgadas.
    """
    del redis_clean
    monkeypatch.delenv("FINANZIA_DEEPSEEK_API_KEY", raising=False)
    get_settings.cache_clear()

    ctx: dict[str, Any] = {}
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


def test_cron_jobs_tiene_los_dos_jobs_de_task_10_con_sus_horarios(worker_settings_module) -> None:
    """Task 10 (F3.7 adelantado, riesgo 4): purga diaria 03:00 y reencolado cada 15
    min (`minute={0,15,30,45}`), ninguno corre al arrancar (`run_at_startup=False`).
    """
    cron_jobs = worker_settings_module.WorkerSettings.cron_jobs
    assert len(cron_jobs) == 2

    by_name = {job.name: job for job in cron_jobs}
    assert set(by_name) == {"cron:purge_raw_message_bodies", "cron:requeue_pending_raw_messages"}

    purge_job = by_name["cron:purge_raw_message_bodies"]
    assert purge_job.hour == 3
    assert purge_job.minute == 0
    assert purge_job.run_at_startup is False

    requeue_job = by_name["cron:requeue_pending_raw_messages"]
    assert requeue_job.minute == {0, 15, 30, 45}
    assert requeue_job.run_at_startup is False


async def test_purge_raw_message_bodies_cron_purga_y_loguea_count(
    worker_settings_module,
    monkeypatch: pytest.MonkeyPatch,
    redis_clean: None,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    """El job cron delega en `ingestion.public.purge_expired_bodies` sobre una
    sesion abierta desde `ctx["events_session_factory"]` y loguea solo el conteo
    (nunca el cuerpo purgado, P6).
    """
    del redis_clean
    monkeypatch.delenv("FINANZIA_DEEPSEEK_API_KEY", raising=False)
    get_settings.cache_clear()

    user = await user_factory()
    now = datetime.now(UTC)
    vencido = await insert_raw_message(
        session_factory,
        user_id=user.id,
        external_id="cron-purge-vencido",
        received_at=now - timedelta(days=200),
    )

    ctx: dict[str, Any] = {}
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


async def test_requeue_pending_raw_messages_cron_republica_huerfanos_y_loguea_count(
    worker_settings_module,
    monkeypatch: pytest.MonkeyPatch,
    redis_clean: None,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    """El job cron delega en `ingestion.public.requeue_pending_raw_messages`, usando
    tanto la sesion (`events_session_factory`) como el bus (`events_bus`) que
    `on_startup` guarda en `ctx` para los consumers.
    """
    del redis_clean
    monkeypatch.delenv("FINANZIA_DEEPSEEK_API_KEY", raising=False)
    get_settings.cache_clear()

    user = await user_factory()
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

    ctx: dict[str, Any] = {}
    await worker_settings_module.on_startup(ctx)
    try:
        with structlog.testing.capture_logs() as captured:
            await worker_settings_module.requeue_pending_raw_messages(ctx)

        logs = [e for e in captured if e.get("event") == "raw_messages_requeued"]
        assert len(logs) == 1
        assert logs[0]["count"] == 1
    finally:
        await worker_settings_module.on_shutdown(ctx)
