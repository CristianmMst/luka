"""Repositorios SQLAlchemy de recurring (spec 004 SS2.12-2.14). Todo filtra por usuario."""

from __future__ import annotations

from collections.abc import Collection
from datetime import date, datetime
from uuid import UUID

from sqlalchemy import delete, or_, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.recurring.domain.entities import Occurrence, RecurringExpense
from luka.modules.recurring.domain.enums import MatchedBy, OccurrenceStatus
from luka.modules.recurring.infrastructure.orm import (
    RecurringExpenseRow,
    RecurringMatchRejectionRow,
    RecurringOccurrenceRow,
)


def expense_row_to_entity(row: RecurringExpenseRow) -> RecurringExpense:
    return RecurringExpense(
        id=row.id,
        user_id=row.user_id,
        name=row.name,
        merchant_keyword=row.merchant_keyword,
        expected_amount=row.expected_amount,
        amount_tolerance_pct=row.amount_tolerance_pct,
        day_of_month=row.day_of_month,
        category_id=row.category_id,
        account_id=row.account_id,
        remind_days_before=row.remind_days_before,
        active=row.active,
        created_at=row.created_at,
        updated_at=row.updated_at,
    )


def occurrence_row_to_entity(row: RecurringOccurrenceRow) -> Occurrence:
    return Occurrence(
        id=row.id,
        user_id=row.user_id,
        recurring_expense_id=row.recurring_expense_id,
        period=row.period,
        due_date=row.due_date,
        status=OccurrenceStatus(row.status),
        transaction_id=row.transaction_id,
        matched_by=MatchedBy(row.matched_by) if row.matched_by is not None else None,
        paid_at=row.paid_at,
        reminded_at=row.reminded_at,
        last_reminder_days=row.last_reminder_days,
    )


class SqlAlchemyRecurringExpenseRepository:
    """Implementacion de `RecurringExpenseRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get(self, user_id: UUID, id: UUID) -> RecurringExpense | None:
        stmt = select(RecurringExpenseRow).where(
            RecurringExpenseRow.id == id, RecurringExpenseRow.user_id == user_id
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return expense_row_to_entity(row) if row is not None else None

    async def list(self, user_id: UUID) -> list[RecurringExpense]:
        stmt = select(RecurringExpenseRow).where(RecurringExpenseRow.user_id == user_id)
        return [expense_row_to_entity(r) for r in (await self._session.execute(stmt)).scalars()]

    async def list_active(self) -> list[RecurringExpense]:
        stmt = select(RecurringExpenseRow).where(RecurringExpenseRow.active.is_(True))
        return [expense_row_to_entity(r) for r in (await self._session.execute(stmt)).scalars()]

    async def add(self, expense: RecurringExpense) -> None:
        self._session.add(
            RecurringExpenseRow(
                id=expense.id,
                user_id=expense.user_id,
                name=expense.name,
                merchant_keyword=expense.merchant_keyword,
                expected_amount=expense.expected_amount,
                amount_tolerance_pct=expense.amount_tolerance_pct,
                day_of_month=expense.day_of_month,
                category_id=expense.category_id,
                account_id=expense.account_id,
                remind_days_before=expense.remind_days_before,
                active=expense.active,
                created_at=expense.created_at,
                updated_at=expense.updated_at,
            )
        )
        await self._session.flush()

    async def update(self, expense: RecurringExpense) -> None:
        row = await self._session.get(RecurringExpenseRow, expense.id)
        if row is None or row.user_id != expense.user_id:
            return
        row.name = expense.name
        row.merchant_keyword = expense.merchant_keyword
        row.expected_amount = expense.expected_amount
        row.amount_tolerance_pct = expense.amount_tolerance_pct
        row.day_of_month = expense.day_of_month
        row.category_id = expense.category_id
        row.account_id = expense.account_id
        row.remind_days_before = expense.remind_days_before
        row.active = expense.active
        row.updated_at = expense.updated_at
        await self._session.flush()

    async def delete(self, user_id: UUID, id: UUID) -> None:
        stmt = delete(RecurringExpenseRow).where(
            RecurringExpenseRow.id == id, RecurringExpenseRow.user_id == user_id
        )
        await self._session.execute(stmt)


class SqlAlchemyOccurrenceRepository:
    """Implementacion de `OccurrenceRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def add_if_absent(self, occurrence: Occurrence) -> bool:
        stmt = (
            insert(RecurringOccurrenceRow)
            .values(
                id=occurrence.id,
                user_id=occurrence.user_id,
                recurring_expense_id=occurrence.recurring_expense_id,
                period=occurrence.period,
                due_date=occurrence.due_date,
                status=occurrence.status.value,
            )
            .on_conflict_do_nothing(index_elements=["recurring_expense_id", "period"])
            .returning(RecurringOccurrenceRow.id)
        )
        inserted = (await self._session.execute(stmt)).scalar_one_or_none()
        return inserted is not None

    async def get(self, user_id: UUID, id: UUID) -> Occurrence | None:
        stmt = select(RecurringOccurrenceRow).where(
            RecurringOccurrenceRow.id == id, RecurringOccurrenceRow.user_id == user_id
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return occurrence_row_to_entity(row) if row is not None else None

    async def list_range(
        self, user_id: UUID, period_from: date, period_to: date
    ) -> list[Occurrence]:
        stmt = select(RecurringOccurrenceRow).where(
            RecurringOccurrenceRow.user_id == user_id,
            RecurringOccurrenceRow.period >= period_from,
            RecurringOccurrenceRow.period <= period_to,
        )
        return [occurrence_row_to_entity(r) for r in (await self._session.execute(stmt)).scalars()]

    async def list_for_user(self, user_id: UUID) -> list[Occurrence]:
        stmt = (
            select(RecurringOccurrenceRow)
            .where(RecurringOccurrenceRow.user_id == user_id)
            .order_by(RecurringOccurrenceRow.period, RecurringOccurrenceRow.due_date)
        )
        return [occurrence_row_to_entity(r) for r in (await self._session.execute(stmt)).scalars()]

    async def pending_for_expense(self, expense_id: UUID) -> list[Occurrence]:
        stmt = (
            select(RecurringOccurrenceRow)
            .where(
                RecurringOccurrenceRow.recurring_expense_id == expense_id,
                RecurringOccurrenceRow.status == OccurrenceStatus.PENDING.value,
            )
            .order_by(RecurringOccurrenceRow.period)
        )
        return [occurrence_row_to_entity(r) for r in (await self._session.execute(stmt)).scalars()]

    async def candidates(
        self, user_id: UUID, due_from: date, due_to: date
    ) -> list[tuple[Occurrence, RecurringExpense]]:
        stmt = (
            select(RecurringOccurrenceRow, RecurringExpenseRow)
            .join(
                RecurringExpenseRow,
                RecurringExpenseRow.id == RecurringOccurrenceRow.recurring_expense_id,
            )
            .where(
                RecurringOccurrenceRow.user_id == user_id,
                RecurringOccurrenceRow.status == OccurrenceStatus.PENDING.value,
                RecurringOccurrenceRow.due_date >= due_from,
                RecurringOccurrenceRow.due_date <= due_to,
                RecurringExpenseRow.active.is_(True),
            )
        )
        result = await self._session.execute(stmt)
        return [
            (occurrence_row_to_entity(occ), expense_row_to_entity(exp))
            for occ, exp in result.tuples()
        ]

    async def claim_auto(self, occurrence_id: UUID, transaction_id: UUID, now: datetime) -> bool:
        stmt = (
            update(RecurringOccurrenceRow)
            .where(
                RecurringOccurrenceRow.id == occurrence_id,
                RecurringOccurrenceRow.status == OccurrenceStatus.PENDING.value,
            )
            .values(
                status=OccurrenceStatus.PAID.value,
                transaction_id=transaction_id,
                matched_by=MatchedBy.AUTO.value,
                paid_at=now,
                updated_at=now,
            )
            .returning(RecurringOccurrenceRow.id)
        )
        try:
            async with self._session.begin_nested():
                claimed = (await self._session.execute(stmt)).scalar_one_or_none()
        except IntegrityError:
            # La transaccion ya paga otra ocurrencia (indice unico parcial): otro
            # worker gano la carrera. No es un error del evento (P2).
            return False
        return claimed is not None

    async def save(self, occurrence: Occurrence) -> None:
        stmt = (
            update(RecurringOccurrenceRow)
            .where(
                RecurringOccurrenceRow.id == occurrence.id,
                RecurringOccurrenceRow.user_id == occurrence.user_id,
            )
            .values(
                status=occurrence.status.value,
                transaction_id=occurrence.transaction_id,
                matched_by=occurrence.matched_by.value if occurrence.matched_by else None,
                paid_at=occurrence.paid_at,
                due_date=occurrence.due_date,
                reminded_at=occurrence.reminded_at,
            )
        )
        await self._session.execute(stmt)

    async def find_by_transaction(self, user_id: UUID, transaction_id: UUID) -> Occurrence | None:
        stmt = select(RecurringOccurrenceRow).where(
            RecurringOccurrenceRow.user_id == user_id,
            RecurringOccurrenceRow.transaction_id == transaction_id,
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return occurrence_row_to_entity(row) if row is not None else None

    async def delete_pending_after(self, expense_id: UUID, period: date) -> None:
        stmt = delete(RecurringOccurrenceRow).where(
            RecurringOccurrenceRow.recurring_expense_id == expense_id,
            RecurringOccurrenceRow.status == OccurrenceStatus.PENDING.value,
            RecurringOccurrenceRow.period > period,
        )
        await self._session.execute(stmt)

    async def reminder_candidates(
        self, due_from: date, due_to: date
    ) -> list[tuple[Occurrence, RecurringExpense]]:
        stmt = (
            select(RecurringOccurrenceRow, RecurringExpenseRow)
            .join(
                RecurringExpenseRow,
                RecurringExpenseRow.id == RecurringOccurrenceRow.recurring_expense_id,
            )
            .where(
                RecurringOccurrenceRow.status == OccurrenceStatus.PENDING.value,
                RecurringOccurrenceRow.due_date >= due_from,
                RecurringOccurrenceRow.due_date <= due_to,
                RecurringExpenseRow.active.is_(True),
            )
        )
        result = await self._session.execute(stmt)
        return [
            (occurrence_row_to_entity(occ), expense_row_to_entity(exp))
            for occ, exp in result.tuples()
        ]

    async def get_with_expense(
        self, occurrence_id: UUID
    ) -> tuple[Occurrence, RecurringExpense] | None:
        stmt = (
            select(RecurringOccurrenceRow, RecurringExpenseRow)
            .join(
                RecurringExpenseRow,
                RecurringExpenseRow.id == RecurringOccurrenceRow.recurring_expense_id,
            )
            .where(RecurringOccurrenceRow.id == occurrence_id)
        )
        row = (await self._session.execute(stmt)).tuples().one_or_none()
        if row is None:
            return None
        occ, exp = row
        return occurrence_row_to_entity(occ), expense_row_to_entity(exp)

    async def mark_reminded(self, occurrence_id: UUID, days_before: int, now: datetime) -> bool:
        last = RecurringOccurrenceRow.last_reminder_days
        stmt = (
            update(RecurringOccurrenceRow)
            .where(
                RecurringOccurrenceRow.id == occurrence_id,
                or_(last.is_(None), last > days_before),
            )
            .values(reminded_at=now, last_reminder_days=days_before)
            .returning(RecurringOccurrenceRow.id)
        )
        return (await self._session.execute(stmt)).scalar_one_or_none() is not None


class SqlAlchemyRejectionRepository:
    """Implementacion de `RejectionRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def add(self, occurrence_id: UUID, transaction_id: UUID) -> None:
        stmt = (
            insert(RecurringMatchRejectionRow)
            .values(occurrence_id=occurrence_id, transaction_id=transaction_id)
            .on_conflict_do_nothing()
        )
        await self._session.execute(stmt)

    async def rejected_occurrences(
        self, transaction_id: UUID, occurrence_ids: Collection[UUID]
    ) -> set[UUID]:
        if not occurrence_ids:
            return set()
        stmt = select(RecurringMatchRejectionRow.occurrence_id).where(
            RecurringMatchRejectionRow.transaction_id == transaction_id,
            RecurringMatchRejectionRow.occurrence_id.in_(list(occurrence_ids)),
        )
        return set((await self._session.execute(stmt)).scalars())
