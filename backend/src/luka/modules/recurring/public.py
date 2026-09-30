"""API publica de recurring: unico punto de entrada para otros modulos (spec 011)."""

from __future__ import annotations

from typing import TYPE_CHECKING

from luka.modules.recurring.application.use_cases.background import (
    EnsureAllOccurrences,
    EnsureSummary,
)
from luka.modules.recurring.infrastructure.consumers import (
    make_transaction_captured_handler,
    make_transaction_deleted_handler,
)
from luka.modules.recurring.infrastructure.id_generator import UuidGenerator
from luka.modules.recurring.infrastructure.repositories import (
    SqlAlchemyOccurrenceRepository,
    SqlAlchemyRecurringExpenseRepository,
)
from luka.modules.recurring.infrastructure.uow import SqlAlchemyUnitOfWork

if TYPE_CHECKING:
    from uuid import UUID

    from sqlalchemy.ext.asyncio import AsyncSession

    from luka.modules.recurring.application.ports import ClockPort

__all__ = [
    "EnsureSummary",
    "ensure_occurrences",
    "export_user_data",
    "make_transaction_captured_handler",
    "make_transaction_deleted_handler",
]


async def ensure_occurrences(session: AsyncSession, clock: ClockPort) -> EnsureSummary:
    """Cron diario: crea (idempotente) las ocurrencias del mes actual y del siguiente."""
    use_case = EnsureAllOccurrences(
        expenses=SqlAlchemyRecurringExpenseRepository(session),
        occurrences=SqlAlchemyOccurrenceRepository(session),
        clock=clock,
        ids=UuidGenerator(),
        uow=SqlAlchemyUnitOfWork(session),
    )
    return await use_case.execute()


async def export_user_data(session: AsyncSession, user_id: UUID) -> dict[str, object]:
    """Gastos fijos y ocurrencias de `user_id` para `GET /v1/me/export` (RF-11.2)."""
    expenses = await SqlAlchemyRecurringExpenseRepository(session).list(user_id)
    occurrences = await SqlAlchemyOccurrenceRepository(session).list_for_user(user_id)
    return {
        "recurring_expenses": [
            {
                "id": str(e.id),
                "name": e.name,
                "merchant_keyword": e.merchant_keyword,
                "expected_amount": str(e.expected_amount),
                "amount_tolerance_pct": e.amount_tolerance_pct,
                "day_of_month": e.day_of_month,
                "category_id": str(e.category_id) if e.category_id else None,
                "account_id": str(e.account_id) if e.account_id else None,
                "remind_days_before": e.remind_days_before,
                "active": e.active,
                "created_at": e.created_at.isoformat(),
            }
            for e in sorted(expenses, key=lambda e: (e.day_of_month, e.name))
        ],
        "recurring_occurrences": [
            {
                "id": str(o.id),
                "recurring_expense_id": str(o.recurring_expense_id),
                "period": o.period.strftime("%Y-%m"),
                "due_date": o.due_date.isoformat(),
                "status": o.status.value,
                "transaction_id": str(o.transaction_id) if o.transaction_id else None,
                "matched_by": o.matched_by.value if o.matched_by else None,
                "paid_at": o.paid_at.isoformat() if o.paid_at else None,
            }
            for o in occurrences
        ],
    }
