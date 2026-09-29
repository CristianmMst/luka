"""Integracion: `ledger.public.mark_self_transfers` contra Postgres real
(spec 004 §4.1): una captura vieja al propio titular pasa a transferencia; la
de otra persona y la editada a mano no cambian.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import uuid4

import pytest
from sqlalchemy import text
from support.clock import FixedClock

from finanzia.modules.ledger import public as ledger_public
from finanzia.modules.ledger.domain.enums import Bank, Channel, Direction
from finanzia.modules.parsing import public as parsing_public
from finanzia.tools.mark_self_transfers import parse_args

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable
    from uuid import UUID

    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
    from support.auth import AuthedUser

pytestmark = pytest.mark.integration

NOW = datetime(2026, 9, 28, 16, 53, tzinfo=UTC)


class _NullBus:
    """`EventBusPort` que descarta: aqui solo importa lo que queda en la base."""

    async def publish(self, event: object) -> None:
        del event


async def _capture(
    session_factory: async_sessionmaker[AsyncSession],
    user_id: UUID,
    merchant: str,
    amount: str,
) -> UUID:
    """Captura como antes de esta regla (sin `merchant_is_person`)."""
    async with session_factory() as session:
        recorded = await ledger_public.record_captured_transaction(
            session,
            _NullBus(),
            FixedClock(NOW),
            ledger_public.CapturedTransactionCommand(
                user_id=user_id,
                bank=Bank.BANCOLOMBIA,
                amount=Decimal(amount),
                direction=Direction.DEBIT,
                occurred_at=NOW,
                last4="8761",
                merchant=merchant,
                description=None,
                suggested_category_slug=None,
                parsed_by="rule:bancolombia:transferencia_llave:v1",
                confidence=None,
                source=ledger_public.SourceInput(Channel.EMAIL, None, NOW),
            ),
        )
    return recorded.transaction.id


async def _kind(session_factory: async_sessionmaker[AsyncSession], tx_id: UUID) -> str:
    async with session_factory() as session:
        return (
            await session.execute(
                text("SELECT kind FROM transactions WHERE id = :t"), {"t": str(tx_id)}
            )
        ).scalar_one()


async def test_marca_solo_las_del_titular_sin_editar(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    async with session_factory() as session:
        await session.execute(
            text("UPDATE users SET display_name = 'Cristian Steve Mora Moreno' WHERE id = :u"),
            {"u": str(user.id)},
        )
        await session.commit()

    own = await _capture(session_factory, user.id, "CRISTIAN MORA", "128283")
    other = await _capture(session_factory, user.id, "Alejandro Herrera Feria", "8000")
    edited = await _capture(session_factory, user.id, "CRISTIAN MORA", "50000")
    async with session_factory() as session:
        await session.execute(
            text("UPDATE transactions SET updated_at = :at WHERE id = :t"),
            {"at": NOW + timedelta(hours=1), "t": str(edited)},
        )
        await session.commit()

    async with session_factory() as session:
        summary = await ledger_public.mark_self_transfers(
            session,
            FixedClock(NOW + timedelta(days=1)),
            person_parsed_by=parsing_public.person_transfer_parsed_by(),
            user_id=None,
        )

    assert (summary.marked, summary.skipped_edited) == (1, 1)
    assert await _kind(session_factory, own) == "transfer"
    assert await _kind(session_factory, other) == "expense"
    assert await _kind(session_factory, edited) == "expense"

    # Idempotente: una segunda corrida no marca nada mas.
    async with session_factory() as session:
        again = await ledger_public.mark_self_transfers(
            session,
            FixedClock(NOW + timedelta(days=2)),
            person_parsed_by=parsing_public.person_transfer_parsed_by(),
            user_id=user.id,
        )
    assert again.marked == 0


def test_cli_acepta_usuario_opcional() -> None:
    assert parse_args([]).user is None
    user_id = uuid4()
    assert parse_args(["--user", str(user_id)]).user == user_id
