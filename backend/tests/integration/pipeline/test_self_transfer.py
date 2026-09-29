"""Test e2e: una transferencia entre personas cuya contraparte es el titular
queda como transferencia propia (spec 004 §4.1), con el correo real de Nequi
Bre-B (F2.7): ingest -> parsing (plantilla, sin LLM) -> ledger.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import pytest
from sqlalchemy import text
from support.clock import FixedClock
from support.email_fixtures import nequi_fixtures
from support.pipeline import InMemoryBudget, PipelineHarness, count_transactions

from finanzia.modules.ingestion.application.dto import RawMessageInput
from finanzia.modules.ingestion.domain.enums import Channel
from finanzia.modules.ingestion.public import Accepted, ingest_raw_message
from finanzia.modules.parsing.infrastructure.llm.disabled import DisabledLlmParser

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable

    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
    from support.auth import AuthedUser

    from finanzia.shared.events.codec import EventRegistry
    from finanzia.shared.events.redis_streams import RedisStreamsEventBus
    from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration


@pytest.mark.parametrize(
    ("display_name", "kind", "fiscal_tag"),
    [
        # El fixture dice "Recibiste 2.600 de Ana Maria Perez Gomez".
        ("Ana Perez", "transfer", "transferencia"),
        ("Beatriz Rojas", "income", None),
    ],
)
async def test_nequi_breb_del_titular_es_transferencia(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    display_name: str,
    kind: str,
    fiscal_tag: str | None,
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    async with session_factory() as session:
        await session.execute(
            text("UPDATE users SET display_name = :n WHERE id = :u"),
            {"n": display_name, "u": str(user.id)},
        )
        await session.commit()

    fixture = nequi_fixtures()[0]
    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=FixedClock(fixture.received_at),
        # La plantilla de Nequi matchea: el LLM nunca deberia invocarse.
        llm=DisabledLlmParser(),
        budget=InMemoryBudget(),
        settings=settings,
    )
    try:
        async with session_factory() as session:
            outcome = await ingest_raw_message(
                session,
                bus,
                FixedClock(fixture.received_at),
                RawMessageInput(
                    user_id=user.id,
                    channel=Channel.EMAIL,
                    external_id=fixture.name,
                    sender=fixture.sender,
                    title=None,
                    text=fixture.body,
                    received_at=fixture.received_at,
                ),
            )
        assert isinstance(outcome, Accepted), outcome

        async def has_one_transaction() -> bool:
            return await count_transactions(session_factory, user.id) == 1

        assert await harness.wait_for(has_one_transaction)
    finally:
        await harness.stop()

    async with session_factory() as session:
        row = (
            await session.execute(
                text(
                    "SELECT kind, fiscal_tag, parsed_by, bank FROM transactions WHERE user_id = :u"
                ),
                {"u": str(user.id)},
            )
        ).one()

    assert row.parsed_by == "rule:nequi:breb_recibida:v1"
    assert row.bank == "nequi"
    assert row.kind == kind
    if fiscal_tag is not None:
        assert row.fiscal_tag == fiscal_tag
    else:
        assert row.fiscal_tag != "transferencia"
