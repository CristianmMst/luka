"""Lecturas de transacciones para otros modulos (recurring, spec 011 SS4) via `ledger.public`.

Solo lectura y siempre filtradas por `user_id` (spec 009 SS4). Devuelven un DTO
propio, `TransactionSnapshot`, para que el consumidor no dependa de las entidades
internas del ledger.
"""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.ledger.infrastructure.orm import CategoryRow, LinkedAccountRow, TransactionRow


@dataclass(frozen=True, slots=True)
class TransactionSnapshot:
    """Lo que otro modulo puede leer de una transaccion propia."""

    id: UUID
    amount: Decimal
    merchant: str | None
    account_id: UUID | None
    occurred_at: datetime
    kind: str
    direction: str

    @property
    def is_expense_debit(self) -> bool:
        return self.kind == "expense" and self.direction == "debit"


def _snapshot(row: TransactionRow) -> TransactionSnapshot:
    return TransactionSnapshot(
        id=row.id,
        amount=row.amount,
        merchant=row.merchant,
        account_id=row.account_id,
        occurred_at=row.occurred_at,
        kind=row.kind,
        direction=row.direction,
    )


async def get_snapshot(
    session: AsyncSession, user_id: UUID, id: UUID
) -> TransactionSnapshot | None:
    stmt = select(TransactionRow).where(TransactionRow.id == id, TransactionRow.user_id == user_id)
    row = (await session.execute(stmt)).scalar_one_or_none()
    return _snapshot(row) if row is not None else None


async def snapshots(
    session: AsyncSession, user_id: UUID, ids: Sequence[UUID]
) -> list[TransactionSnapshot]:
    if not ids:
        return []
    stmt = select(TransactionRow).where(
        TransactionRow.user_id == user_id, TransactionRow.id.in_(list(ids))
    )
    return [_snapshot(row) for row in (await session.execute(stmt)).scalars()]


async def expenses_in_window(
    session: AsyncSession, user_id: UUID, start: datetime, end: datetime
) -> list[TransactionSnapshot]:
    """Gastos (`expense` + `debit`) del usuario con `start <= occurred_at < end`."""
    stmt = select(TransactionRow).where(
        TransactionRow.user_id == user_id,
        TransactionRow.kind == "expense",
        TransactionRow.direction == "debit",
        TransactionRow.occurred_at >= start,
        TransactionRow.occurred_at < end,
    )
    return [_snapshot(row) for row in (await session.execute(stmt)).scalars()]


async def category_visible(session: AsyncSession, user_id: UUID, id: UUID) -> bool:
    """Categoria del sistema o propia del usuario."""
    stmt = (
        select(func.count())
        .select_from(CategoryRow)
        .where(
            CategoryRow.id == id,
            or_(CategoryRow.user_id.is_(None), CategoryRow.user_id == user_id),
        )
    )
    return (await session.execute(stmt)).scalar_one() > 0


async def account_owned(session: AsyncSession, user_id: UUID, id: UUID) -> bool:
    stmt = (
        select(func.count())
        .select_from(LinkedAccountRow)
        .where(LinkedAccountRow.id == id, LinkedAccountRow.user_id == user_id)
    )
    return (await session.execute(stmt)).scalar_one() > 0


__all__ = [
    "TransactionSnapshot",
    "account_owned",
    "category_visible",
    "expenses_in_window",
    "get_snapshot",
    "snapshots",
]
