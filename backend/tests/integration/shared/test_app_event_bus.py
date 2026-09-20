"""La app cablea `RedisStreamsEventBus` en `app.state.event_bus` (spec 003 SS2.3/2.4)."""

from datetime import UTC, datetime
from decimal import Decimal
from uuid import uuid4

import pytest
from asgi_lifespan import LifespanManager
from fastapi import FastAPI

from finanzia.events_registry import build_registry
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
