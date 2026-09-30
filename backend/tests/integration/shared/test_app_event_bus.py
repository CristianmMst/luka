"""La app cablea `RedisStreamsEventBus` en `app.state.event_bus` (spec 003 SS2.3/2.4)."""

import asyncio
from datetime import UTC, datetime
from decimal import Decimal
from uuid import uuid4

import pytest
import structlog.testing
from asgi_lifespan import LifespanManager
from fastapi import FastAPI

from luka import app as app_module
from luka.app import create_app
from luka.events_registry import CONSUMER_GROUPS, build_registry, ensure_consumer_groups
from luka.modules.ledger.domain.enums import Direction, FiscalTag, Kind
from luka.modules.ledger.events import TransactionCaptured
from luka.shared.events.redis_streams import RedisStreamsEventBus
from luka.shared.settings import Settings

pytestmark = pytest.mark.integration

_LIFESPAN_WAIT_S = 10.0


async def _run_lifespan_once(app: FastAPI) -> None:
    async with LifespanManager(app):
        pass


async def test_lifespan_crea_event_bus_y_publica_en_el_stream_correcto(
    app: FastAPI, redis_clean: None
) -> None:
    del redis_clean
    async with LifespanManager(app):
        assert isinstance(app.state.event_bus, RedisStreamsEventBus)

        event = TransactionCaptured(
            event_id=uuid4(),
            occurred_at=datetime.now(UTC),
            user_id=uuid4(),
            transaction_id=uuid4(),
            kind=Kind.EXPENSE,
            fiscal_tag=FiscalTag.NO_DEDUCIBLE,
            amount=Decimal("50.00"),
            direction=Direction.DEBIT,
            category_id=uuid4(),
            transaction_occurred_at=datetime.now(UTC),
            created=True,
        )

        await app.state.event_bus.publish(event)

        stream = app.state.event_bus.stream_name(TransactionCaptured.event_type)
        assert await app.state.redis.xlen(stream) == 1

        [(_message_id, fields)] = await app.state.redis.xrange(stream)
        decoded = build_registry().decode(fields)
        assert decoded == event


async def test_lifespan_crea_los_4_grupos_de_consumidores(app: FastAPI, redis_clean: None) -> None:
    """D10: los grupos ya existen tras el lifespan, via MKSTREAM (streams vacios)."""
    del redis_clean
    async with LifespanManager(app):
        for event_type, group in CONSUMER_GROUPS:
            stream = app.state.event_bus.stream_name(event_type)
            raw_groups = await app.state.redis.xinfo_groups(stream)
            names = {info["name"].decode() for info in raw_groups}
            assert group in names, f"grupo {group!r} no existe en {stream!r}: {names!r}"


async def test_ensure_consumer_groups_es_idempotente(app: FastAPI, redis_clean: None) -> None:
    del redis_clean
    async with LifespanManager(app):
        await ensure_consumer_groups(app.state.event_bus)  # no debe levantar (BUSYGROUP)
        await ensure_consumer_groups(app.state.event_bus)


async def test_lifespan_no_bloquea_con_redis_inalcanzable_y_loguea_advertencia(
    settings: Settings,
) -> None:
    """Fix round 1 (finding Important): el arranque de la API sigue terminando
    (y avisando por log) aunque Redis no responda a `ensure_consumer_groups`.
    """
    unreachable_settings = settings.model_copy(update={"redis_url": "redis://localhost:1/1"})
    app = create_app(unreachable_settings)

    with structlog.testing.capture_logs() as logs:
        await asyncio.wait_for(_run_lifespan_once(app), timeout=_LIFESPAN_WAIT_S)

    warnings = [entry for entry in logs if entry.get("event") == "consumer_groups_not_ensured"]
    assert warnings


async def test_lifespan_no_bloquea_si_ensure_group_nunca_responde(
    settings: Settings, monkeypatch: pytest.MonkeyPatch
) -> None:
    """A diferencia de un connection-refused (rapido), un Redis que acepta la
    conexion TCP pero nunca contesta podia colgar el arranque indefinidamente
    antes de este fix: `asyncio.wait_for` en `app.py` lo corta a los
    `_CONSUMER_GROUPS_TIMEOUT_S` segundos. Se acorta ese timeout a 0.1s aqui
    para no alargar la suite, y se cuelga `ensure_group` en vez de tumbar la
    conexion, para simular ese escenario ("Redis vivo, mudo").
    """
    monkeypatch.setattr(app_module, "_CONSUMER_GROUPS_TIMEOUT_S", 0.1)

    async def _hangs_forever(self: RedisStreamsEventBus, stream: str, group: str) -> None:
        del self, stream, group
        await asyncio.sleep(100)

    monkeypatch.setattr(RedisStreamsEventBus, "ensure_group", _hangs_forever)

    app = create_app(settings)

    with structlog.testing.capture_logs() as logs:
        await asyncio.wait_for(_run_lifespan_once(app), timeout=5.0)

    warnings = [entry for entry in logs if entry.get("event") == "consumer_groups_not_ensured"]
    assert warnings
    assert warnings[0].get("error_type") == "TimeoutError"
