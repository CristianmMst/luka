"""La app cablea `RedisStreamsEventBus` en `app.state.event_bus` (spec 003 SS2.3/2.4)."""

from datetime import UTC, datetime
from decimal import Decimal
from uuid import uuid4

import pytest
from asgi_lifespan import LifespanManager
from fastapi import FastAPI

from finanzia.events_registry import CONSUMER_GROUPS, build_registry, ensure_consumer_groups
from finanzia.modules.ledger.domain.enums import Direction, FiscalTag, Kind
from finanzia.modules.ledger.events import TransactionCaptured
from finanzia.shared.events.redis_streams import RedisStreamsEventBus

pytestmark = pytest.mark.integration


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
