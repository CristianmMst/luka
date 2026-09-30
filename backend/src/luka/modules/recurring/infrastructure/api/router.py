"""Router HTTP de recurring: `/recurring-expenses` y `/recurring-occurrences` (spec 005 SS10)."""

from datetime import date
from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status

from luka.modules.recurring.application.dto import (
    UNSET,
    ExpenseInput,
    ExpensePatch,
    OccurrenceView,
)
from luka.modules.recurring.application.use_cases.manage_expenses import (
    CreateExpense,
    DeleteExpense,
    ListExpenses,
    UpdateExpense,
)
from luka.modules.recurring.application.use_cases.occurrences import (
    GetOccurrence,
    ListOccurrences,
    MarkPaid,
    Skip,
    Unmark,
)
from luka.modules.recurring.domain.entities import RecurringExpense
from luka.modules.recurring.domain.schedule import parse_month
from luka.modules.recurring.infrastructure.api.deps import (
    get_create_expense_use_case,
    get_current_user_id,
    get_delete_expense_use_case,
    get_get_occurrence_use_case,
    get_list_expenses_use_case,
    get_list_occurrences_use_case,
    get_mark_paid_use_case,
    get_skip_use_case,
    get_unmark_use_case,
    get_update_expense_use_case,
)
from luka.modules.recurring.infrastructure.api.schemas import (
    CreateRecurringExpenseRequest,
    MarkPaidRequest,
    OccurrenceExpenseResponse,
    OccurrenceResponse,
    OccurrenceTransactionResponse,
    PatchRecurringExpenseRequest,
    RecurringExpenseResponse,
)
from luka.shared.errors import ValidationAppError

router = APIRouter(tags=["recurring"], dependencies=[Depends(get_current_user_id)])

#: Campos que no admiten `null` en un PATCH (solo `category_id`/`account_id` lo aceptan).
_NON_NULLABLE = (
    "name",
    "merchant_keyword",
    "expected_amount",
    "day_of_month",
    "amount_tolerance_pct",
    "remind_days_before",
    "active",
)


def expense_response(expense: RecurringExpense) -> RecurringExpenseResponse:
    return RecurringExpenseResponse(
        id=expense.id,
        name=expense.name,
        merchant_keyword=expense.merchant_keyword,
        expected_amount=str(expense.expected_amount),
        amount_tolerance_pct=expense.amount_tolerance_pct,
        day_of_month=expense.day_of_month,
        category_id=expense.category_id,
        account_id=expense.account_id,
        remind_days_before=expense.remind_days_before,
        active=expense.active,
        created_at=expense.created_at,
        updated_at=expense.updated_at,
    )


def occurrence_response(view: OccurrenceView) -> OccurrenceResponse:
    occ, expense, tx = view.occurrence, view.expense, view.transaction
    return OccurrenceResponse(
        id=occ.id,
        recurring_expense=OccurrenceExpenseResponse(
            id=expense.id,
            name=expense.name,
            merchant_keyword=expense.merchant_keyword,
            expected_amount=str(expense.expected_amount),
            category_id=expense.category_id,
            active=expense.active,
        ),
        period=occ.period.strftime("%Y-%m"),
        due_date=occ.due_date,
        status=occ.status.value,
        matched_by=occ.matched_by.value if occ.matched_by else None,
        paid_at=occ.paid_at,
        reminded_at=occ.reminded_at,
        transaction=(
            OccurrenceTransactionResponse(
                id=tx.id, merchant=tx.merchant, amount=str(tx.amount), occurred_at=tx.occurred_at
            )
            if tx is not None
            else None
        ),
    )


def _month(value: str, field: str) -> date:
    try:
        return parse_month(value)
    except ValueError as exc:
        raise ValidationAppError(message="Mes invalido (AAAA-MM)", field=field) from exc


@router.get("/recurring-expenses")
async def list_recurring_expenses(
    user_id: UUID = Depends(get_current_user_id),
    use_case: ListExpenses = Depends(get_list_expenses_use_case),
) -> list[RecurringExpenseResponse]:
    """Gastos fijos propios, activos y pausados (spec 005 SS10)."""
    return [expense_response(e) for e in await use_case.execute(user_id)]


@router.post("/recurring-expenses", status_code=status.HTTP_201_CREATED)
async def create_recurring_expense(
    body: CreateRecurringExpenseRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: CreateExpense = Depends(get_create_expense_use_case),
) -> RecurringExpenseResponse:
    """Crea el gasto fijo con sus ocurrencias y barre los pagos ya capturados."""
    expense = await use_case.execute(
        user_id,
        ExpenseInput(
            name=body.name,
            merchant_keyword=body.merchant_keyword,
            expected_amount=Decimal(body.expected_amount),
            day_of_month=body.day_of_month,
            amount_tolerance_pct=body.amount_tolerance_pct,
            remind_days_before=body.remind_days_before,
            category_id=body.category_id,
            account_id=body.account_id,
        ),
    )
    return expense_response(expense)


@router.patch("/recurring-expenses/{id}")
async def patch_recurring_expense(
    id: UUID,
    body: PatchRecurringExpenseRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: UpdateExpense = Depends(get_update_expense_use_case),
) -> RecurringExpenseResponse:
    """Edita, pausa o reanuda un gasto fijo propio."""
    sent = body.model_fields_set
    for field in _NON_NULLABLE:
        if field in sent and getattr(body, field) is None:
            raise ValidationAppError(message=f"{field} no puede ser null", field=field)
    patch = ExpensePatch(
        name=body.name if body.name is not None else UNSET,
        merchant_keyword=body.merchant_keyword if body.merchant_keyword is not None else UNSET,
        expected_amount=(
            Decimal(body.expected_amount) if body.expected_amount is not None else UNSET
        ),
        day_of_month=body.day_of_month if body.day_of_month is not None else UNSET,
        amount_tolerance_pct=(
            body.amount_tolerance_pct if body.amount_tolerance_pct is not None else UNSET
        ),
        remind_days_before=(
            body.remind_days_before if body.remind_days_before is not None else UNSET
        ),
        category_id=body.category_id if "category_id" in sent else UNSET,
        account_id=body.account_id if "account_id" in sent else UNSET,
        active=body.active if body.active is not None else UNSET,
    )
    return expense_response(await use_case.execute(user_id, id, patch))


@router.delete("/recurring-expenses/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_recurring_expense(
    id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    use_case: DeleteExpense = Depends(get_delete_expense_use_case),
) -> None:
    """Borra el gasto fijo y sus ocurrencias; los movimientos no cambian."""
    await use_case.execute(user_id, id)


@router.get("/recurring-occurrences")
async def list_recurring_occurrences(
    from_: str = Query(alias="from"),
    to: str = Query(),
    user_id: UUID = Depends(get_current_user_id),
    use_case: ListOccurrences = Depends(get_list_occurrences_use_case),
) -> list[OccurrenceResponse]:
    """Ocurrencias con `period` entre `from` y `to` (AAAA-MM, incluidos, <= 12 meses)."""
    views = await use_case.execute(user_id, _month(from_, "from"), _month(to, "to"))
    return [occurrence_response(v) for v in views]


@router.post("/recurring-occurrences/{id}/mark-paid")
async def mark_occurrence_paid(
    id: UUID,
    body: MarkPaidRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: MarkPaid = Depends(get_mark_paid_use_case),
    get_occurrence: GetOccurrence = Depends(get_get_occurrence_use_case),
) -> OccurrenceResponse:
    """Pagada a mano, con o sin el movimiento que la pago (spec 011 SS4.1)."""
    await use_case.execute(user_id, id, body.transaction_id)
    return occurrence_response(await get_occurrence.execute(user_id, id))


@router.post("/recurring-occurrences/{id}/unmark")
async def unmark_occurrence(
    id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    use_case: Unmark = Depends(get_unmark_use_case),
    get_occurrence: GetOccurrence = Depends(get_get_occurrence_use_case),
) -> OccurrenceResponse:
    """Vuelve a `pending`; un emparejamiento automatico deshecho no se repite."""
    await use_case.execute(user_id, id)
    return occurrence_response(await get_occurrence.execute(user_id, id))


@router.post("/recurring-occurrences/{id}/skip")
async def skip_occurrence(
    id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    use_case: Skip = Depends(get_skip_use_case),
    get_occurrence: GetOccurrence = Depends(get_get_occurrence_use_case),
) -> OccurrenceResponse:
    """Omite la ocurrencia este mes."""
    await use_case.execute(user_id, id)
    return occurrence_response(await get_occurrence.execute(user_id, id))
