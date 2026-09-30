"""Casos de uso sobre ocurrencias: listar, marcar, deshacer, omitir (spec 011 SS4.1)."""

from __future__ import annotations

from dataclasses import replace
from datetime import date
from uuid import UUID

from luka.modules.recurring.application.dto import OccurrenceView
from luka.modules.recurring.application.ports import (
    ClockPort,
    LedgerPort,
    OccurrenceRepositoryPort,
    RecurringExpenseRepositoryPort,
    RejectionRepositoryPort,
    UnitOfWorkPort,
)
from luka.modules.recurring.application.use_cases._common import get_owned_occurrence
from luka.modules.recurring.domain.enums import MatchedBy, OccurrenceStatus
from luka.modules.recurring.domain.errors import (
    InvalidMonthRange,
    OccurrenceNotPaid,
    RecurringExpenseNotFound,
    TransactionAlreadyPays,
    TransactionNotExpense,
    TransactionNotFound,
)
from luka.modules.recurring.domain.schedule import months_between

#: Rango maximo de `GET /recurring-occurrences` (spec 005 SS10).
MAX_MONTHS = 12


def _pending(occurrence_status: OccurrenceStatus) -> bool:
    return occurrence_status is OccurrenceStatus.PENDING


class ListOccurrences:
    """Ocurrencias entre dos meses (incluidos) con su gasto fijo y su transaccion."""

    def __init__(
        self,
        *,
        occurrences: OccurrenceRepositoryPort,
        expenses: RecurringExpenseRepositoryPort,
        ledger: LedgerPort,
    ) -> None:
        self._occurrences = occurrences
        self._expenses = expenses
        self._ledger = ledger

    async def execute(
        self, user_id: UUID, period_from: date, period_to: date
    ) -> list[OccurrenceView]:
        span = months_between(period_from, period_to)
        if span < 0 or span >= MAX_MONTHS:
            raise InvalidMonthRange
        rows = await self._occurrences.list_range(user_id, period_from, period_to)
        expenses = {e.id: e for e in await self._expenses.list(user_id)}
        tx_ids = [o.transaction_id for o in rows if o.transaction_id is not None]
        summaries = await self._ledger.summaries(user_id, tx_ids) if tx_ids else {}
        views = [
            OccurrenceView(
                occurrence=o,
                expense=expenses[o.recurring_expense_id],
                transaction=summaries.get(o.transaction_id) if o.transaction_id else None,
            )
            for o in rows
            if o.recurring_expense_id in expenses
        ]
        return sorted(
            views,
            key=lambda v: (v.occurrence.due_date, v.expense.name.casefold(), str(v.occurrence.id)),
        )


class GetOccurrence:
    """Una ocurrencia con su gasto y transaccion (respuesta de las acciones)."""

    def __init__(
        self,
        *,
        occurrences: OccurrenceRepositoryPort,
        expenses: RecurringExpenseRepositoryPort,
        ledger: LedgerPort,
    ) -> None:
        self._occurrences = occurrences
        self._expenses = expenses
        self._ledger = ledger

    async def execute(self, user_id: UUID, id: UUID) -> OccurrenceView:
        occurrence = await get_owned_occurrence(self._occurrences, user_id, id)
        expense = await self._expenses.get(user_id, occurrence.recurring_expense_id)
        if expense is None:  # la FK CASCADE lo impide; defensa ante carreras
            raise RecurringExpenseNotFound
        summary = None
        if occurrence.transaction_id is not None:
            summaries = await self._ledger.summaries(user_id, [occurrence.transaction_id])
            summary = summaries.get(occurrence.transaction_id)
        return OccurrenceView(occurrence=occurrence, expense=expense, transaction=summary)


class MarkPaid:
    """Marca pagada a mano, con o sin la transaccion que la pago."""

    def __init__(
        self,
        *,
        occurrences: OccurrenceRepositoryPort,
        ledger: LedgerPort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._occurrences = occurrences
        self._ledger = ledger
        self._clock = clock
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID, transaction_id: UUID | None) -> None:
        occurrence = await get_owned_occurrence(self._occurrences, user_id, id)
        if transaction_id is not None:
            tx = await self._ledger.get_transaction(user_id, transaction_id)
            if tx is None:
                raise TransactionNotFound
            if not tx.is_expense_debit:
                raise TransactionNotExpense
            other = await self._occurrences.find_by_transaction(user_id, transaction_id)
            if other is not None and other.id != occurrence.id:
                raise TransactionAlreadyPays
        await self._occurrences.save(
            replace(
                occurrence,
                status=OccurrenceStatus.PAID,
                transaction_id=transaction_id,
                matched_by=MatchedBy.MANUAL,
                paid_at=self._clock.now(),
            )
        )
        await self._uow.commit()


class Unmark:
    """Vuelve a `pending`; si era automatico, registra el rechazo del par (AC-12.4)."""

    def __init__(
        self,
        *,
        occurrences: OccurrenceRepositoryPort,
        rejections: RejectionRepositoryPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._occurrences = occurrences
        self._rejections = rejections
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID) -> None:
        occurrence = await get_owned_occurrence(self._occurrences, user_id, id)
        if _pending(occurrence.status):
            raise OccurrenceNotPaid
        if occurrence.matched_by is MatchedBy.AUTO and occurrence.transaction_id is not None:
            await self._rejections.add(occurrence.id, occurrence.transaction_id)
        await self._occurrences.save(
            replace(
                occurrence,
                status=OccurrenceStatus.PENDING,
                transaction_id=None,
                matched_by=None,
                paid_at=None,
            )
        )
        await self._uow.commit()


class Skip:
    """Omite la ocurrencia este mes: no se empareja ni se avisa."""

    def __init__(self, *, occurrences: OccurrenceRepositoryPort, uow: UnitOfWorkPort) -> None:
        self._occurrences = occurrences
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID) -> None:
        occurrence = await get_owned_occurrence(self._occurrences, user_id, id)
        await self._occurrences.save(
            replace(
                occurrence,
                status=OccurrenceStatus.SKIPPED,
                transaction_id=None,
                matched_by=None,
                paid_at=None,
            )
        )
        await self._uow.commit()
