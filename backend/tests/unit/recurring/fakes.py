"""Dobles en memoria de los ports de recurring (solo tests)."""

from __future__ import annotations

import uuid
from collections.abc import Collection, Sequence
from dataclasses import dataclass, field, replace
from datetime import date, datetime
from uuid import UUID

from luka.modules.recurring.application.dto import TransactionSummary
from luka.modules.recurring.domain.entities import Occurrence, RecurringExpense
from luka.modules.recurring.domain.enums import MatchedBy, OccurrenceStatus
from luka.modules.recurring.domain.matcher import TxCandidate


class FixedClock:
    def __init__(self, now: datetime) -> None:
        self._now = now

    def now(self) -> datetime:
        return self._now


class SequenceIds:
    def __init__(self) -> None:
        self._n = 0

    def new_id(self) -> UUID:
        self._n += 1
        return uuid.uuid5(uuid.NAMESPACE_URL, f"https://luka.app/test-recurring/{self._n}")


class NoopUoW:
    def __init__(self) -> None:
        self.commits = 0

    async def commit(self) -> None:
        self.commits += 1


class InMemoryExpenses:
    def __init__(self) -> None:
        self.rows: dict[UUID, RecurringExpense] = {}

    async def get(self, user_id: UUID, id: UUID) -> RecurringExpense | None:
        row = self.rows.get(id)
        return row if row is not None and row.user_id == user_id else None

    async def list(self, user_id: UUID) -> list[RecurringExpense]:
        return [r for r in self.rows.values() if r.user_id == user_id]

    async def list_active(self) -> list[RecurringExpense]:
        return [r for r in self.rows.values() if r.active]

    async def add(self, expense: RecurringExpense) -> None:
        self.rows[expense.id] = expense

    async def update(self, expense: RecurringExpense) -> None:
        self.rows[expense.id] = expense

    async def delete(self, user_id: UUID, id: UUID) -> None:
        if (row := self.rows.get(id)) is not None and row.user_id == user_id:
            del self.rows[id]


class InMemoryOccurrences:
    def __init__(self, expenses: InMemoryExpenses) -> None:
        self.rows: dict[UUID, Occurrence] = {}
        self._expenses = expenses

    async def add_if_absent(self, occurrence: Occurrence) -> bool:
        for row in self.rows.values():
            if (row.recurring_expense_id, row.period) == (
                occurrence.recurring_expense_id,
                occurrence.period,
            ):
                return False
        self.rows[occurrence.id] = occurrence
        return True

    async def get(self, user_id: UUID, id: UUID) -> Occurrence | None:
        row = self.rows.get(id)
        return row if row is not None and row.user_id == user_id else None

    async def list_range(
        self, user_id: UUID, period_from: date, period_to: date
    ) -> list[Occurrence]:
        return [
            r
            for r in self.rows.values()
            if r.user_id == user_id and period_from <= r.period <= period_to
        ]

    async def list_for_user(self, user_id: UUID) -> list[Occurrence]:
        return [r for r in self.rows.values() if r.user_id == user_id]

    async def pending_for_expense(self, expense_id: UUID) -> list[Occurrence]:
        return sorted(
            (
                r
                for r in self.rows.values()
                if r.recurring_expense_id == expense_id and r.status is OccurrenceStatus.PENDING
            ),
            key=lambda r: r.period,
        )

    def _with_expense(self, rows: list[Occurrence]) -> list[tuple[Occurrence, RecurringExpense]]:
        pairs = []
        for row in rows:
            expense = self._expenses.rows.get(row.recurring_expense_id)
            if expense is not None and expense.active:
                pairs.append((row, expense))
        return pairs

    async def candidates(
        self, user_id: UUID, due_from: date, due_to: date
    ) -> list[tuple[Occurrence, RecurringExpense]]:
        return self._with_expense(
            [
                r
                for r in self.rows.values()
                if r.user_id == user_id
                and r.status is OccurrenceStatus.PENDING
                and due_from <= r.due_date <= due_to
            ]
        )

    async def claim_auto(self, occurrence_id: UUID, transaction_id: UUID, now: datetime) -> bool:
        row = self.rows.get(occurrence_id)
        if row is None or row.status is not OccurrenceStatus.PENDING:
            return False
        if any(r.transaction_id == transaction_id for r in self.rows.values()):
            return False
        self.rows[occurrence_id] = replace(
            row,
            status=OccurrenceStatus.PAID,
            transaction_id=transaction_id,
            matched_by=MatchedBy.AUTO,
            paid_at=now,
        )
        return True

    async def save(self, occurrence: Occurrence) -> None:
        self.rows[occurrence.id] = occurrence

    async def find_by_transaction(self, user_id: UUID, transaction_id: UUID) -> Occurrence | None:
        for row in self.rows.values():
            if row.user_id == user_id and row.transaction_id == transaction_id:
                return row
        return None

    async def delete_pending_after(self, expense_id: UUID, period: date) -> None:
        for key, row in list(self.rows.items()):
            if (
                row.recurring_expense_id == expense_id
                and row.status is OccurrenceStatus.PENDING
                and row.period > period
            ):
                del self.rows[key]

    async def reminder_candidates(
        self, due_from: date, due_to: date
    ) -> list[tuple[Occurrence, RecurringExpense]]:
        return self._with_expense(
            [
                r
                for r in self.rows.values()
                if r.status is OccurrenceStatus.PENDING and due_from <= r.due_date <= due_to
            ]
        )

    async def get_with_expense(
        self, occurrence_id: UUID
    ) -> tuple[Occurrence, RecurringExpense] | None:
        row = self.rows.get(occurrence_id)
        if row is None:
            return None
        return row, self._expenses.rows[row.recurring_expense_id]

    async def mark_reminded(self, occurrence_id: UUID, slot: int, now: datetime) -> bool:
        row = self.rows.get(occurrence_id)
        last = row.last_reminder_slot if row is not None else None
        if row is None or (last is not None and last >= slot):
            return False
        self.rows[occurrence_id] = replace(row, reminded_at=now, last_reminder_slot=slot)
        return True


class InMemoryRejections:
    def __init__(self) -> None:
        self.pairs: set[tuple[UUID, UUID]] = set()

    async def add(self, occurrence_id: UUID, transaction_id: UUID) -> None:
        self.pairs.add((occurrence_id, transaction_id))

    async def rejected_occurrences(
        self, transaction_id: UUID, occurrence_ids: Collection[UUID]
    ) -> set[UUID]:
        return {o for o, t in self.pairs if t == transaction_id and o in occurrence_ids}


@dataclass
class FakeLedger:
    txs: dict[UUID, tuple[UUID, TxCandidate]] = field(default_factory=dict)
    categories: set[UUID] = field(default_factory=set)
    accounts: set[UUID] = field(default_factory=set)

    def add(self, user_id: UUID, tx: TxCandidate) -> None:
        self.txs[tx.id] = (user_id, tx)

    async def get_transaction(self, user_id: UUID, id: UUID) -> TxCandidate | None:
        owner, tx = self.txs.get(id, (None, None))
        return tx if owner == user_id else None

    async def expenses_in_window(
        self, user_id: UUID, start: datetime, end: datetime
    ) -> list[TxCandidate]:
        return [
            tx
            for owner, tx in self.txs.values()
            if owner == user_id and tx.is_expense_debit and start <= tx.occurred_at < end
        ]

    async def summaries(self, user_id: UUID, ids: Sequence[UUID]) -> dict[UUID, TransactionSummary]:
        return {
            tx.id: TransactionSummary(tx.id, tx.merchant, tx.amount, tx.occurred_at)
            for owner, tx in self.txs.values()
            if owner == user_id and tx.id in ids
        }

    async def category_visible(self, user_id: UUID, id: UUID) -> bool:
        return id in self.categories

    async def account_owned(self, user_id: UUID, id: UUID) -> bool:
        return id in self.accounts


class RecurringRepos:
    def __init__(self, now: datetime) -> None:
        self.clock = FixedClock(now)
        self.ids = SequenceIds()
        self.uow = NoopUoW()
        self.expenses = InMemoryExpenses()
        self.occurrences = InMemoryOccurrences(self.expenses)
        self.rejections = InMemoryRejections()
        self.ledger = FakeLedger()
