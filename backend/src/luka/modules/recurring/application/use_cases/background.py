"""Casos de uso que corren fuera del request: consumers y crons (spec 011 SS3-SS5)."""

from __future__ import annotations

from dataclasses import dataclass, replace
from uuid import UUID

from luka.modules.recurring.application.ports import (
    ClockPort,
    IdGeneratorPort,
    OccurrenceRepositoryPort,
    RecurringExpenseRepositoryPort,
    RejectionRepositoryPort,
    UnitOfWorkPort,
)
from luka.modules.recurring.application.use_cases._common import (
    ensure_occurrences,
    match_transaction,
    today_in_colombia,
)
from luka.modules.recurring.domain.enums import OccurrenceStatus
from luka.modules.recurring.domain.matcher import TxCandidate
from luka.modules.recurring.domain.schedule import colombia_date


class MatchCapturedTransaction:
    """Consumer de `ledger.TransactionCaptured`: intenta emparejar el pago (AC-12.2)."""

    def __init__(
        self,
        *,
        occurrences: OccurrenceRepositoryPort,
        rejections: RejectionRepositoryPort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._occurrences = occurrences
        self._rejections = rejections
        self._clock = clock
        self._uow = uow

    async def execute(self, user_id: UUID, tx: TxCandidate) -> UUID | None:
        matched = await match_transaction(
            occurrences=self._occurrences,
            rejections=self._rejections,
            clock=self._clock,
            user_id=user_id,
            tx=tx,
        )
        await self._uow.commit()
        return matched


class RevertDeletedTransaction:
    """Consumer de `ledger.TransactionDeleted`: la ocurrencia que pagaba vuelve a `pending`."""

    def __init__(self, *, occurrences: OccurrenceRepositoryPort, uow: UnitOfWorkPort) -> None:
        self._occurrences = occurrences
        self._uow = uow

    async def execute(self, user_id: UUID, transaction_id: UUID) -> bool:
        occurrence = await self._occurrences.find_by_transaction(user_id, transaction_id)
        if occurrence is None:
            return False
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
        return True


@dataclass(frozen=True, slots=True)
class EnsureSummary:
    """Conteos del cron de ocurrencias (solo numeros en los logs, P1)."""

    expenses: int
    created: int


class EnsureAllOccurrences:
    """Cron diario: ocurrencia del mes actual y del siguiente de cada gasto activo."""

    def __init__(
        self,
        *,
        expenses: RecurringExpenseRepositoryPort,
        occurrences: OccurrenceRepositoryPort,
        clock: ClockPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._expenses = expenses
        self._occurrences = occurrences
        self._clock = clock
        self._ids = ids
        self._uow = uow

    async def execute(self) -> EnsureSummary:
        today = today_in_colombia(self._clock)
        active = await self._expenses.list_active()
        created = 0
        for expense in active:
            created += await ensure_occurrences(
                self._occurrences,
                self._ids,
                expense,
                today=today,
                since=colombia_date(expense.created_at),
            )
        await self._uow.commit()
        return EnsureSummary(expenses=len(active), created=created)
