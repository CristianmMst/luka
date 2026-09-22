"""Tests de integracion de `make_raw_message_received_handler` (D7): fila real
de `raw_messages` (Postgres) + evento real en Redis Streams, con
`DisabledLlmParser` (sin red, §5).
"""

from __future__ import annotations

import types
from collections.abc import Awaitable, Callable
from datetime import UTC, datetime
from uuid import UUID

import pytest
import redis.asyncio as redis_asyncio
import redis.exceptions
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser
from support.clock import FixedClock
from support.raw_messages import insert_raw_message

from finanzia.events_registry import build_registry
from finanzia.modules.parsing.infrastructure.config_loader import load_parsing_config
from finanzia.modules.parsing.infrastructure.consumers import make_raw_message_received_handler
from finanzia.modules.parsing.infrastructure.llm.budget_redis import RedisLlmBudget
from finanzia.modules.parsing.infrastructure.llm.disabled import DisabledLlmParser
from finanzia.modules.parsing.infrastructure.metrics import StructlogMetrics
from finanzia.modules.parsing.infrastructure.raw_message_gateway import IngestionRawMessageGateway
from finanzia.shared.events.codec import EventRegistry
from finanzia.shared.events.redis_streams import RedisStreamsEventBus
from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration

# `occurred_at` de la plantilla `compra_tdeb` (America/Bogota, -05:00): fijamos
# `received_at` en el mismo instante para que caiga dentro de la ventana de
# +/- 7 dias que exige `TemplateMatch.to_parsed` (spec 006 §4.1).
_RECEIVED_AT = datetime(2026, 1, 1, 15, 0, tzinfo=UTC)  # == 2026-01-01T10:00:00-05:00
_CLOCK = FixedClock(datetime(2026, 1, 1, 15, 5, tzinfo=UTC))

_PARSED_BODY = (
    "Bancolombia: Compraste $1.000,00 en X con tu T.Deb *1234, el 01/01/2026 a las 10:00."
)
_NON_TEMPLATE_MONETARY_BODY = (
    "Bancolombia: Retiraste $50.000 en cajero El Poblado el 01/01/2026 a las 10:00."
)


class _RaisingBus:
    """Doble de `EventBusPort`: `publish` siempre lanza (simula un Redis caido)."""

    async def publish(self, event: object) -> None:
        del event
        msg = "boom: bus caido"
        raise redis.exceptions.RedisError(msg)


@pytest.fixture
async def redis_client(settings: Settings):
    client = redis_asyncio.from_url(str(settings.redis_url), decode_responses=False)
    try:
        yield client
    finally:
        await client.aclose()


@pytest.fixture
def registry() -> EventRegistry:
    return build_registry()


async def _row_status(
    session_factory: async_sessionmaker[AsyncSession], raw_message_id: UUID
) -> str | None:
    async with session_factory() as session:
        gateway = IngestionRawMessageGateway(session)
        view = await gateway.get_for_parsing(raw_message_id)
    return view.status if view is not None else None


def _handler(
    *,
    session_factory: async_sessionmaker[AsyncSession],
    event_bus: object,
    redis_client: redis_asyncio.Redis,
    settings: Settings,
):
    return make_raw_message_received_handler(
        session_factory=session_factory,
        event_bus=event_bus,  # type: ignore[arg-type]
        clock=_CLOCK,
        llm=DisabledLlmParser(),
        budget=RedisLlmBudget(redis_client),
        registry=load_parsing_config().templates,
        known_banks=load_parsing_config().senders.known_banks(),
        metrics=StructlogMetrics(),
        settings=settings,
    )


async def test_fila_pendiente_bancolombia_matchea_plantilla_queda_parsed(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
    redis_client: redis_asyncio.Redis,
    registry: EventRegistry,
    settings: Settings,
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(
        session_factory,
        user_id=user.id,
        body=_PARSED_BODY,
        received_at=_RECEIVED_AT,
        status="pending",
    )
    bus = RedisStreamsEventBus(redis_client, registry)
    handler = _handler(
        session_factory=session_factory, event_bus=bus, redis_client=redis_client, settings=settings
    )

    event = types.SimpleNamespace(raw_message_id=raw_message_id)
    await handler(event)

    assert await _row_status(session_factory, raw_message_id) == "parsed"

    stream = bus.stream_name("parsing.TransactionParsed")
    entries = await redis_client.xrange(stream)
    assert len(entries) == 1
    _entry_id, fields = entries[0]
    decoded = registry.decode(fields)
    assert decoded.raw_message_id == raw_message_id  # type: ignore[attr-defined]


async def test_fila_pendiente_sin_plantilla_con_llm_disabled_queda_failed(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
    redis_client: redis_asyncio.Redis,
    registry: EventRegistry,
    settings: Settings,
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(
        session_factory,
        user_id=user.id,
        body=_NON_TEMPLATE_MONETARY_BODY,
        received_at=_RECEIVED_AT,
        status="pending",
    )
    bus = RedisStreamsEventBus(redis_client, registry)
    handler = _handler(
        session_factory=session_factory, event_bus=bus, redis_client=redis_client, settings=settings
    )

    event = types.SimpleNamespace(raw_message_id=raw_message_id)
    await handler(event)

    assert await _row_status(session_factory, raw_message_id) == "failed"

    stream = bus.stream_name("parsing.ParseFailed")
    entries = await redis_client.xrange(stream)
    assert len(entries) == 1
    _entry_id, fields = entries[0]
    decoded = registry.decode(fields)
    assert decoded.raw_message_id == raw_message_id  # type: ignore[attr-defined]
    assert decoded.reason.value == "llm_disabled"  # type: ignore[attr-defined]


async def test_publish_que_lanza_propaga_y_la_fila_sigue_pending(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
    redis_client: redis_asyncio.Redis,
    settings: Settings,
) -> None:
    user = await user_factory()
    raw_message_id = await insert_raw_message(
        session_factory,
        user_id=user.id,
        body=_PARSED_BODY,
        received_at=_RECEIVED_AT,
        status="pending",
    )
    handler = _handler(
        session_factory=session_factory,
        event_bus=_RaisingBus(),
        redis_client=redis_client,
        settings=settings,
    )

    event = types.SimpleNamespace(raw_message_id=raw_message_id)
    with pytest.raises(redis.exceptions.RedisError):
        await handler(event)

    assert await _row_status(session_factory, raw_message_id) == "pending"


async def test_evento_sin_raw_message_id_valido_se_ignora_sin_lanzar(
    session_factory: async_sessionmaker[AsyncSession],
    redis_client: redis_asyncio.Redis,
    registry: EventRegistry,
    settings: Settings,
) -> None:
    bus = RedisStreamsEventBus(redis_client, registry)
    handler = _handler(
        session_factory=session_factory, event_bus=bus, redis_client=redis_client, settings=settings
    )

    event = types.SimpleNamespace(raw_message_id="no-es-un-uuid")
    await handler(event)  # no debe lanzar
