"""`LedgerPort` sobre `ledger.public` (R4: recurring nunca lee tablas del ledger)."""

from __future__ import annotations

from collections.abc import Sequence
from typing import TYPE_CHECKING

from luka.modules.ledger import public as ledger_public
from luka.modules.recurring.application.dto import TransactionSummary
from luka.modules.recurring.domain.matcher import TxCandidate

if TYPE_CHECKING:
    from datetime import datetime
    from uuid import UUID

    from sqlalchemy.ext.asyncio import AsyncSession


def _candidate(snapshot: ledger_public.TransactionSnapshot) -> TxCandidate:
    return TxCandidate(
        id=snapshot.id,
        amount=snapshot.amount,
        merchant=snapshot.merchant,
        account_id=snapshot.account_id,
        occurred_at=snapshot.occurred_at,
        is_expense_debit=snapshot.is_expense_debit,
    )


class LedgerGateway:
    """Implementacion de `LedgerPort` con la sesion del request o del consumer."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_transaction(self, user_id: UUID, id: UUID) -> TxCandidate | None:
        snapshot = await ledger_public.get_transaction_snapshot(self._session, user_id, id)
        return _candidate(snapshot) if snapshot is not None else None

    async def expenses_in_window(
        self, user_id: UUID, start: datetime, end: datetime
    ) -> list[TxCandidate]:
        rows = await ledger_public.expenses_in_window(self._session, user_id, start, end)
        return [_candidate(row) for row in rows]

    async def summaries(self, user_id: UUID, ids: Sequence[UUID]) -> dict[UUID, TransactionSummary]:
        rows = await ledger_public.transaction_snapshots(self._session, user_id, ids)
        return {
            row.id: TransactionSummary(
                id=row.id, merchant=row.merchant, amount=row.amount, occurred_at=row.occurred_at
            )
            for row in rows
        }

    async def category_visible(self, user_id: UUID, id: UUID) -> bool:
        return await ledger_public.category_visible(self._session, user_id, id)

    async def account_owned(self, user_id: UUID, id: UUID) -> bool:
        return await ledger_public.account_owned(self._session, user_id, id)


__all__ = ["LedgerGateway"]
