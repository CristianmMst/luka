"""Tests e2e de los caminos del LLM (spec 006 SS4.2, D11/D12, F2.2/F2.5/F2.6):
texto Bancolombia no reconocido por ninguna plantilla -> el LLM decide.
"""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest
from support.clock import FixedClock
from support.pipeline import (
    FakeLlmParser,
    InMemoryBudget,
    PipelineHarness,
    count_transactions,
    fetch_transaction,
    raw_status,
    review_reason,
)
from support.raw_messages import insert_raw_message

from luka.modules.ingestion.events import RawMessageReceived
from luka.modules.parsing.application.dto import LlmOutput
from luka.modules.parsing.domain.enums import Direction as ParsingDirection
from luka.modules.parsing.domain.llm_validation import LlmExtraction
from luka.shared.clock import SystemClock

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable
    from uuid import UUID

    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
    from support.auth import AuthedUser

    from luka.shared.events.codec import EventRegistry
    from luka.shared.events.redis_streams import RedisStreamsEventBus
    from luka.shared.settings import Settings

pytestmark = pytest.mark.integration

# Excerpt de Bancolombia que ninguna plantilla matchea pero que "parece" un monto
# (contiene "$"): el mismo texto que ejercita el camino LLM en
# `tests/integration/parsing/test_consumer_handler.py`.
_UNRECOGNIZED_BODY = (
    "Bancolombia: Retiraste $50.000 en cajero El Poblado el 01/01/2026 a las 10:00."
)
_RECEIVED_AT = datetime(2026, 1, 1, 15, 0, tzinfo=UTC)  # == 2026-01-01T10:00:00-05:00


async def _insert_and_publish(
    session_factory: async_sessionmaker[AsyncSession],
    bus: RedisStreamsEventBus,
    *,
    user_id: UUID,
) -> UUID:
    """Inserta el `raw_message` (pending, sin plantilla) y publica `RawMessageReceived`."""
    raw_message_id = await insert_raw_message(
        session_factory,
        user_id=user_id,
        body=_UNRECOGNIZED_BODY,
        received_at=_RECEIVED_AT,
        status="pending",
    )
    await bus.publish(
        RawMessageReceived(
            event_id=uuid4(),
            occurred_at=SystemClock().now(),
            raw_message_id=raw_message_id,
            user_id=user_id,
            channel="email",
            bank="bancolombia",
            received_at=_RECEIVED_AT,
        )
    )
    return raw_message_id


def _extraction(*, is_transaction: bool, confidence: float) -> LlmExtraction:
    """`LlmExtraction` de guion: transaccion valida dentro de la ventana +/-7 dias
    (`_RECEIVED_AT`) o `is_transaction=False` (D12: descarte sin revision).
    """
    if not is_transaction:
        return LlmExtraction(
            is_transaction=False,
            amount=None,
            currency=None,
            direction=None,
            merchant=None,
            occurred_at=None,
            bank=None,
            last4=None,
            suggested_category=None,
            confidence=confidence,
        )
    return LlmExtraction(
        is_transaction=True,
        amount=Decimal("50000.00"),
        currency="COP",
        direction=ParsingDirection.DEBIT,
        merchant="Cajero El Poblado",
        occurred_at=_RECEIVED_AT,
        bank="bancolombia",
        last4=None,
        suggested_category=None,
        confidence=confidence,
    )


async def test_llm_confianza_alta_crea_transaccion_parsed_by_llm(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    clock = FixedClock(_RECEIVED_AT)
    llm = FakeLlmParser(
        [LlmOutput(extraction=_extraction(is_transaction=True, confidence=0.93), tokens=123)]
    )
    budget = InMemoryBudget()
    month_key = clock.now().strftime("%Y%m")

    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=clock,
        llm=llm,
        budget=budget,
        settings=settings,
    )
    try:
        await _insert_and_publish(session_factory, bus, user_id=user.id)

        async def has_one_transaction() -> bool:
            return await count_transactions(session_factory, user.id) == 1

        assert await harness.wait_for(has_one_transaction)
    finally:
        await harness.stop()

    tx = await fetch_transaction(session_factory, user.id)
    assert tx.parsed_by == "llm"
    assert tx.confidence == pytest.approx(0.93)
    assert await budget.used(user.id, month_key) == 123


async def test_llm_confianza_baja_va_a_revision(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    client: AsyncClient,
) -> None:
    user = await user_factory()
    clock = FixedClock(_RECEIVED_AT)
    llm = FakeLlmParser(
        [LlmOutput(extraction=_extraction(is_transaction=True, confidence=0.5), tokens=80)]
    )
    budget = InMemoryBudget()

    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=clock,
        llm=llm,
        budget=budget,
        settings=settings,
    )
    try:
        raw_message_id = await _insert_and_publish(session_factory, bus, user_id=user.id)

        async def has_review_entry() -> bool:
            return await review_reason(session_factory, raw_message_id) is not None

        assert await harness.wait_for(has_review_entry)
    finally:
        await harness.stop()

    assert await review_reason(session_factory, raw_message_id) == "llm_low_confidence"
    assert await raw_status(session_factory, raw_message_id) == "failed"
    assert await count_transactions(session_factory, user.id) == 0

    response = await client.get("/v1/review", headers=user.headers)
    assert response.status_code == 200, response.text
    items = response.json()["items"]
    assert len(items) == 1
    assert items[0]["raw_message_id"] == str(raw_message_id)
    assert items[0]["reason"] == "llm_low_confidence"
    assert items[0]["text"] == _UNRECOGNIZED_BODY
    assert items[0]["partial_extract"]


async def test_presupuesto_agotado_no_invoca_al_llm(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    clock = FixedClock(_RECEIVED_AT)
    month_key = clock.now().strftime("%Y%m")
    # Script vacio: si el codigo llamara al LLM de todos modos, `parse()` lanzaria
    # `IndexError` (nunca capturado por `ParseRawMessage`) y el mensaje quedaria
    # pendiente (PEL) en vez de ir a revision -> el `wait_for` de abajo expira.
    llm = FakeLlmParser([])
    budget = InMemoryBudget({(user.id, month_key): settings.llm_monthly_token_budget_per_user})

    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=clock,
        llm=llm,
        budget=budget,
        settings=settings,
    )
    try:
        raw_message_id = await _insert_and_publish(session_factory, bus, user_id=user.id)

        async def has_review_entry() -> bool:
            return await review_reason(session_factory, raw_message_id) is not None

        assert await harness.wait_for(has_review_entry)
    finally:
        await harness.stop()

    assert await review_reason(session_factory, raw_message_id) == "llm_budget_exceeded"
    assert llm.calls == []


async def test_llm_deshabilitado_va_a_revision_sin_invocar_al_llm(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    clock = FixedClock(_RECEIVED_AT)
    llm = FakeLlmParser([], enabled=False)
    budget = InMemoryBudget()

    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=clock,
        llm=llm,
        budget=budget,
        settings=settings,
    )
    try:
        raw_message_id = await _insert_and_publish(session_factory, bus, user_id=user.id)

        async def has_review_entry() -> bool:
            return await review_reason(session_factory, raw_message_id) is not None

        assert await harness.wait_for(has_review_entry)
    finally:
        await harness.stop()

    assert await review_reason(session_factory, raw_message_id) == "llm_disabled"
    assert llm.calls == []


async def test_llm_dice_que_no_es_transaccion_descarta_sin_revision(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    clock = FixedClock(_RECEIVED_AT)
    llm = FakeLlmParser(
        [LlmOutput(extraction=_extraction(is_transaction=False, confidence=0.99), tokens=40)]
    )
    budget = InMemoryBudget()

    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=clock,
        llm=llm,
        budget=budget,
        settings=settings,
    )
    try:
        raw_message_id = await _insert_and_publish(session_factory, bus, user_id=user.id)

        async def is_discarded() -> bool:
            return await raw_status(session_factory, raw_message_id) == "discarded"

        assert await harness.wait_for(is_discarded)
    finally:
        await harness.stop()

    assert await count_transactions(session_factory, user.id) == 0
    assert await review_reason(session_factory, raw_message_id) is None
