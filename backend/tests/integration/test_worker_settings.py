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

import pytest
from arq import Worker, create_pool

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
