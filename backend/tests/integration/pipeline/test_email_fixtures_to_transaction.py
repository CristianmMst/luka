"""Test e2e del pipeline completo (spec 003 SS4, F2.2/F2.5/F2.6): un fixture de
correo Bancolombia real -> `ingest_raw_message` -> los 3 consumers -> transaccion
visible, con cuenta/categoria resueltas (spec 006 SS4.1, SS4.3).
"""

from __future__ import annotations

from decimal import Decimal
from typing import TYPE_CHECKING

import pytest
from sqlalchemy import text
from support.clock import FixedClock
from support.email_fixtures import EmailFixture, bancolombia_fixtures
from support.pipeline import (
    InMemoryBudget,
    PipelineHarness,
    count_transactions,
    fetch_transaction,
    raw_status,
)

from finanzia.modules.ingestion.application.dto import RawMessageInput
from finanzia.modules.ingestion.domain.enums import Channel
from finanzia.modules.ingestion.public import Accepted, ingest_raw_message
from finanzia.modules.parsing.infrastructure.llm.disabled import DisabledLlmParser

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable

    from httpx import AsyncClient
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
    from support.auth import AuthedUser

    from finanzia.shared.events.codec import EventRegistry
    from finanzia.shared.events.redis_streams import RedisStreamsEventBus
    from finanzia.shared.settings import Settings

pytestmark = pytest.mark.integration


def _template_id(fixture_name: str) -> str:
    """Deriva el `template_id` esperado del nombre del fixture (controller ruling 3)."""
    if fixture_name.startswith("compra_tdeb"):
        return "compra_tdeb"
    if fixture_name.startswith("transferencia_llave_recibida"):
        return "transferencia_llave_recibida"
    if fixture_name.startswith("transferencia_llave"):
        return "transferencia_llave"
    if fixture_name.startswith("nomina"):
        return "nomina"
    msg = f"fixture sin template_id mapeado: {fixture_name}"
    raise AssertionError(msg)


async def _ensure_accounts(client: AsyncClient, headers: dict[str, str]) -> None:
    """Cuentas `(bancolombia, <last4>)` usadas por los fixtures reales/anonimizados."""
    for last4 in ("1234", "4455", "9081", "5533"):
        response = await client.post(
            "/v1/accounts",
            json={"bank": "bancolombia", "kind": "savings", "last4": last4},
            headers=headers,
        )
        assert response.status_code == 201, response.text


@pytest.mark.parametrize("fixture", bancolombia_fixtures(), ids=lambda f: f.name)
async def test_fixture_bancolombia_produce_la_transaccion_esperada(  # noqa: PLR0913, PLR0917 - un parametro por fixture inyectada (patron pytest)
    fixture: EmailFixture,
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    redis_client,
    registry: EventRegistry,
    bus: RedisStreamsEventBus,
    settings: Settings,
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    await _ensure_accounts(client, user.headers)

    clock = FixedClock(fixture.received_at)
    harness = PipelineHarness()
    await harness.start(
        session_factory=session_factory,
        redis=redis_client,
        registry=registry,
        bus=bus,
        clock=clock,
        # Todos los fixtures de Bancolombia matchean plantilla (F2.3): el LLM
        # (y su presupuesto) nunca deberian invocarse.
        llm=DisabledLlmParser(),
        budget=InMemoryBudget(),
        settings=settings,
    )
    try:
        async with session_factory() as session:
            outcome = await ingest_raw_message(
                session,
                bus,
                clock,
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
        raw_message_id = outcome.raw_message_id

        async def has_one_transaction() -> bool:
            return await count_transactions(session_factory, user.id) == 1

        assert await harness.wait_for(has_one_transaction)
    finally:
        await harness.stop()

    expected = fixture.expected
    tx = await fetch_transaction(session_factory, user.id)
    async with session_factory() as session:
        source = (
            await session.execute(
                text(
                    "SELECT raw_message_id, channel FROM transaction_sources "
                    "WHERE transaction_id = :t"
                ),
                {"t": str(tx.id)},
            )
        ).one()
        review_count = (
            await session.execute(
                text("SELECT count(*) FROM review_queue WHERE user_id = :u"), {"u": str(user.id)}
            )
        ).scalar_one()

    assert tx.amount == Decimal(expected["amount"])
    assert tx.direction == expected["direction"]
    assert tx.merchant == expected["merchant"]
    assert tx.occurred_at == expected["occurred_at"]
    assert tx.bank == "bancolombia"
    assert tx.parsed_by == f"rule:bancolombia:{_template_id(fixture.name)}:v1"
    if expected.get("last4") is None:
        assert tx.account_id is None
    else:
        assert tx.account_id is not None
    assert tx.category_slug == (expected.get("suggested_category") or "sin_categoria")

    assert source.channel == "email"
    assert source.raw_message_id == raw_message_id
    assert await raw_status(session_factory, raw_message_id) == "parsed"
    assert review_count == 0
