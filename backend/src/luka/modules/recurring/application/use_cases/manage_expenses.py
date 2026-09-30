"""Casos de uso del CRUD de gastos fijos (spec 005 SS10, spec 011 SS3)."""

from __future__ import annotations

from dataclasses import replace
from uuid import UUID

from luka.modules.recurring.application.dto import UNSET, ExpenseInput, ExpensePatch
from luka.modules.recurring.application.ports import (
    ClockPort,
    IdGeneratorPort,
    LedgerPort,
    OccurrenceRepositoryPort,
    RecurringExpenseRepositoryPort,
    RejectionRepositoryPort,
    UnitOfWorkPort,
)
from luka.modules.recurring.application.use_cases._common import (
    ensure_occurrences,
    sweep_expense,
    today_in_colombia,
)
from luka.modules.recurring.domain.entities import RecurringExpense, validate_expense_fields
from luka.modules.recurring.domain.errors import (
    AccountNotFound,
    CategoryNotFound,
    RecurringExpenseNotFound,
)
from luka.modules.recurring.domain.schedule import due_date, month_start

#: Campos cuyo cambio vuelve a correr el barrido retroactivo (spec 005 SS10).
_MATCHING_FIELDS = (
    "merchant_keyword",
    "expected_amount",
    "amount_tolerance_pct",
    "day_of_month",
    "account_id",
)
_PATCHABLE_FIELDS = (
    "name",
    "merchant_keyword",
    "expected_amount",
    "day_of_month",
    "amount_tolerance_pct",
    "remind_days_before",
    "category_id",
    "account_id",
    "active",
)


async def _check_references(
    ledger: LedgerPort, user_id: UUID, category_id: UUID | None, account_id: UUID | None
) -> None:
    if category_id is not None and not await ledger.category_visible(user_id, category_id):
        raise CategoryNotFound
    if account_id is not None and not await ledger.account_owned(user_id, account_id):
        raise AccountNotFound


class ListExpenses:
    """Gastos fijos propios, activos y pausados, por dia y nombre."""

    def __init__(self, *, expenses: RecurringExpenseRepositoryPort) -> None:
        self._expenses = expenses

    async def execute(self, user_id: UUID) -> list[RecurringExpense]:
        items = await self._expenses.list(user_id)
        return sorted(items, key=lambda e: (e.day_of_month, e.name.casefold(), str(e.id)))


class CreateExpense:
    """Crea el gasto fijo, sus ocurrencias del mes actual y siguiente, y barre lo ya pagado."""

    def __init__(  # noqa: PLR0913 - puertos del caso de uso por nombre
        self,
        *,
        expenses: RecurringExpenseRepositoryPort,
        occurrences: OccurrenceRepositoryPort,
        rejections: RejectionRepositoryPort,
        ledger: LedgerPort,
        clock: ClockPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._expenses = expenses
        self._occurrences = occurrences
        self._rejections = rejections
        self._ledger = ledger
        self._clock = clock
        self._ids = ids
        self._uow = uow

    async def execute(self, user_id: UUID, input: ExpenseInput) -> RecurringExpense:
        own_keyword = input.merchant_keyword is not None
        name, keyword, amount = validate_expense_fields(
            name=input.name,
            merchant_keyword=input.merchant_keyword or input.name,
            expected_amount=input.expected_amount,
            amount_tolerance_pct=input.amount_tolerance_pct,
            day_of_month=input.day_of_month,
            remind_days_before=input.remind_days_before,
            keyword_field="merchant_keyword" if own_keyword else "name",
        )
        await _check_references(self._ledger, user_id, input.category_id, input.account_id)
        now = self._clock.now()
        expense = RecurringExpense(
            id=self._ids.new_id(),
            user_id=user_id,
            name=name,
            merchant_keyword=keyword,
            expected_amount=amount,
            amount_tolerance_pct=input.amount_tolerance_pct,
            day_of_month=input.day_of_month,
            category_id=input.category_id,
            account_id=input.account_id,
            remind_days_before=input.remind_days_before,
            active=True,
            created_at=now,
            updated_at=now,
        )
        await self._expenses.add(expense)
        today = today_in_colombia(self._clock)
        await ensure_occurrences(self._occurrences, self._ids, expense, today=today, since=today)
        await sweep_expense(
            occurrences=self._occurrences,
            rejections=self._rejections,
            ledger=self._ledger,
            clock=self._clock,
            expense=expense,
        )
        await self._uow.commit()
        return expense


class UpdateExpense:
    """Edita un gasto fijo; recalcula vencimientos, pausa/reanuda y repite el barrido."""

    def __init__(  # noqa: PLR0913 - puertos del caso de uso por nombre
        self,
        *,
        expenses: RecurringExpenseRepositoryPort,
        occurrences: OccurrenceRepositoryPort,
        rejections: RejectionRepositoryPort,
        ledger: LedgerPort,
        clock: ClockPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._expenses = expenses
        self._occurrences = occurrences
        self._rejections = rejections
        self._ledger = ledger
        self._clock = clock
        self._ids = ids
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID, patch: ExpensePatch) -> RecurringExpense:
        current = await self._expenses.get(user_id, id)
        if current is None:
            raise RecurringExpenseNotFound
        updated = _apply(current, patch)
        # Renombrar sin mandar keyword: la keyword sigue al nombre (spec 011 SS4).
        follows_name = patch.name is not UNSET and patch.merchant_keyword is UNSET
        if follows_name:
            updated = replace(updated, merchant_keyword=updated.name)
        name, keyword, amount = validate_expense_fields(
            name=updated.name,
            merchant_keyword=updated.merchant_keyword,
            expected_amount=updated.expected_amount,
            amount_tolerance_pct=updated.amount_tolerance_pct,
            day_of_month=updated.day_of_month,
            remind_days_before=updated.remind_days_before,
            keyword_field="name" if follows_name else "merchant_keyword",
        )
        await _check_references(
            self._ledger,
            user_id,
            updated.category_id if patch.category_id is not UNSET else None,
            updated.account_id if patch.account_id is not UNSET else None,
        )
        updated = replace(
            updated,
            name=name,
            merchant_keyword=keyword,
            expected_amount=amount,
            updated_at=self._clock.now(),
        )
        await self._expenses.update(updated)

        today = today_in_colombia(self._clock)
        this_month = month_start(today)
        if updated.day_of_month != current.day_of_month:
            for occurrence in await self._occurrences.pending_for_expense(id):
                if occurrence.period >= this_month:
                    new_due = due_date(occurrence.period, updated.day_of_month)
                    await self._occurrences.save(replace(occurrence, due_date=new_due))
        reactivated = not current.active and updated.active
        if current.active and not updated.active:
            await self._occurrences.delete_pending_after(id, this_month)
        elif reactivated:
            await ensure_occurrences(
                self._occurrences, self._ids, updated, today=today, since=today
            )
        changed = any(getattr(current, f) != getattr(updated, f) for f in _MATCHING_FIELDS)
        if updated.active and (reactivated or changed):
            await sweep_expense(
                occurrences=self._occurrences,
                rejections=self._rejections,
                ledger=self._ledger,
                clock=self._clock,
                expense=updated,
            )
        await self._uow.commit()
        return updated


def _apply(expense: RecurringExpense, patch: ExpensePatch) -> RecurringExpense:
    changes: dict[str, object] = {}
    for field in _PATCHABLE_FIELDS:
        value = getattr(patch, field)
        if value is not UNSET:
            changes[field] = value
    return replace(expense, **changes)  # type: ignore[arg-type]


class DeleteExpense:
    """Borra el gasto fijo y sus ocurrencias (CASCADE); las transacciones no se tocan."""

    def __init__(self, *, expenses: RecurringExpenseRepositoryPort, uow: UnitOfWorkPort) -> None:
        self._expenses = expenses
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID) -> None:
        if await self._expenses.get(user_id, id) is None:
            raise RecurringExpenseNotFound
        await self._expenses.delete(user_id, id)
        await self._uow.commit()
