"""Casos de uso que corren fuera del request: consumers y crons (spec 011 SS3-SS5)."""

from __future__ import annotations

import uuid
from dataclasses import dataclass, replace
from datetime import date, timedelta
from uuid import UUID

from luka.modules.recurring.application.ports import (
    ClockPort,
    EventPublisherPort,
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
from luka.modules.recurring.domain.matcher import TxCandidate, reminder_due
from luka.modules.recurring.domain.schedule import colombia_date
from luka.modules.recurring.events import PaymentDueSoon


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


#: Espacio de nombres del `event_id` determinista de `PaymentDueSoon`.
_REMINDER_NAMESPACE = uuid.UUID("0b0a6f0e-4a0e-4b6f-9d0b-6b1d2a6f5e11")


def reminder_event_id(occurrence_id: UUID, today: date) -> UUID:
    """Un `event_id` por ocurrencia y dia: el cron repetido no duplica el aviso."""
    return uuid.uuid5(_REMINDER_NAMESPACE, f"{occurrence_id}:{today.isoformat()}")


class PublishDueReminders:
    """Cron diario: publica `PaymentDueSoon` de cada ocurrencia que toca avisar hoy."""

    def __init__(
        self,
        *,
        occurrences: OccurrenceRepositoryPort,
        events: EventPublisherPort,
        clock: ClockPort,
    ) -> None:
        self._occurrences = occurrences
        self._events = events
        self._clock = clock

    async def execute(self) -> int:
        today = today_in_colombia(self._clock)
        # El aviso mas temprano es 2 dias antes (spec 004 SS2.12): basta mirar hasta ahi.
        rows = await self._occurrences.reminder_candidates(today, today + timedelta(days=2))
        published = 0
        for occurrence, expense in rows:
            if not reminder_due(occurrence, expense, today):
                continue
            await self._events.publish(
                PaymentDueSoon(
                    event_id=reminder_event_id(occurrence.id, today),
                    occurred_at=self._clock.now(),
                    user_id=occurrence.user_id,
                    occurrence_id=occurrence.id,
                    name=expense.name,
                    expected_amount=expense.expected_amount,
                    due_date=occurrence.due_date.isoformat(),
                )
            )
            published += 1
        return published


class ReminderStatus:
    """Consulta y marca del aviso, para el consumer de notifications (via `public`)."""

    def __init__(
        self, *, occurrences: OccurrenceRepositoryPort, clock: ClockPort, uow: UnitOfWorkPort
    ) -> None:
        self._occurrences = occurrences
        self._clock = clock
        self._uow = uow

    async def still_due(self, occurrence_id: UUID) -> bool:
        pair = await self._occurrences.get_with_expense(occurrence_id)
        if pair is None:
            return False
        occurrence, expense = pair
        return reminder_due(occurrence, expense, today_in_colombia(self._clock))

    async def mark_reminded(self, occurrence_id: UUID) -> bool:
        marked = await self._occurrences.mark_reminded(occurrence_id, self._clock.now())
        await self._uow.commit()
        return marked
