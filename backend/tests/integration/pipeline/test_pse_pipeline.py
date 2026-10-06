"""Test e2e del pipeline con los correos de PSE (spec 006 SS4.1, spec 004 SS3):
el remitente de ACH Colombia entra como `other`, lo lee la plantilla generica
`pse` y, si el banco tambien avisa del mismo pago, queda una sola transaccion.
"""

from __future__ import annotations

from decimal import Decimal
from typing import TYPE_CHECKING

import pytest
from support.clock import FixedClock
from support.email_fixtures import EmailFixture, bancolombia_fixtures, pse_fixtures
from support.pipeline import (
    InMemoryBudget,
    PipelineHarness,
    count_sources,
    count_transactions,
    fetch_transaction,
    raw_status,
)

from luka.modules.ingestion.application.dto import RawMessageInput
from luka.modules.ingestion.domain.enums import Channel
from luka.modules.ingestion.public import Accepted, ingest_raw_message
from luka.modules.parsing.infrastructure.llm.disabled import DisabledLlmParser

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable
    from uuid import UUID

    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
    from support.auth import AuthedUser

    from luka.shared.events.codec import EventRegistry
    from luka.shared.events.redis_streams import RedisStreamsEventBus
    from luka.shared.settings import Settings

pytestmark = pytest.mark.integration


async def _ingest(
    session_factory: async_sessionmaker[AsyncSession],
    bus: RedisStreamsEventBus,
    clock: FixedClock,
    user_id: UUID,
    fixture: EmailFixture,
) -> UUID:
    async with session_factory() as session:
        outcome = await ingest_raw_message(
            session,
            bus,
            clock,
            RawMessageInput(
                user_id=user_id,
                channel=Channel.EMAIL,
                external_id=fixture.name,
                sender=fixture.sender,
                title=None,
                text=fixture.body,
                received_at=fixture.received_at,
            ),
        )
    assert isinstance(outcome, Accepted), outcome
    assert outcome.bank == "other" or fixture.name.startswith("pago_producto")
    return outcome.raw_message_id


async def _start(  # noqa: PLR0913, PLR0917 - una dependencia por fixture de pytest
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    clock: FixedClock,
) -> PipelineHarness:
    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=clock,
        # La plantilla lee todo: el LLM nunca deberia invocarse.
        llm=DisabledLlmParser(),
        budget=InMemoryBudget(),
        settings=settings,
    )
    return harness


@pytest.mark.parametrize("fixture", pse_fixtures(), ids=lambda f: f.name)
async def test_correo_pse_produce_la_transaccion_esperada(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    fixture: EmailFixture,
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    clock = FixedClock(fixture.received_at)
    harness = await _start(session_factory, redis_client, registry, bus, settings, clock)
    try:
        raw_message_id = await _ingest(session_factory, bus, clock, user.id, fixture)

        async def has_one_transaction() -> bool:
            return await count_transactions(session_factory, user.id) == 1

        assert await harness.wait_for(has_one_transaction)
    finally:
        await harness.stop()

    expected = fixture.expected
    tx = await fetch_transaction(session_factory, user.id)
    assert tx.amount == Decimal(expected["amount"])
    assert tx.direction == "debit"
    assert tx.merchant == expected["merchant"]
    assert tx.occurred_at == expected["occurred_at"]
    assert tx.bank == "other"
    assert tx.parsed_by == "rule:pse:pago:v1"
    assert tx.account_id is None
    assert await raw_status(session_factory, raw_message_id) == "parsed"


async def test_pago_pse_y_correo_del_banco_quedan_en_una_transaccion(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    """El pago de medicina prepagada llega por PSE y por Bancolombia (spec 004 SS3)."""
    user = await user_factory()
    bank_mail = next(f for f in bancolombia_fixtures() if f.name == "pago_producto_2.txt")
    pse_mail = next(f for f in pse_fixtures() if f.name == "pago_aprobado_celdas.txt")
    clock = FixedClock(pse_mail.received_at)
    harness = await _start(session_factory, redis_client, registry, bus, settings, clock)
    try:
        await _ingest(session_factory, bus, clock, user.id, bank_mail)

        async def has_one_transaction() -> bool:
            return await count_transactions(session_factory, user.id) == 1

        assert await harness.wait_for(has_one_transaction)
        pse_raw_id = await _ingest(session_factory, bus, clock, user.id, pse_mail)

        async def pse_parsed() -> bool:
            return await raw_status(session_factory, pse_raw_id) == "parsed"

        assert await harness.wait_for(pse_parsed)
        tx = await fetch_transaction(session_factory, user.id)

        async def two_sources() -> bool:
            return await count_sources(session_factory, tx.id) == 2

        assert await harness.wait_for(two_sources)
    finally:
        await harness.stop()

    assert await count_transactions(session_factory, user.id) == 1
    assert tx.merchant == "Compania de Medicina Prepagada"
    assert tx.bank == "bancolombia"
