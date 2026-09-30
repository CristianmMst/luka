"""Wiring de dependencias FastAPI de recurring: unico lugar que ensambla adapters.

`get_session` es una copia local de la de ledger (R4: los modulos solo se cruzan
por `public.py`/`events.py`).
"""

from collections.abc import AsyncIterator

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.identity.public import get_current_user_id
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
from luka.modules.recurring.infrastructure.id_generator import UuidGenerator
from luka.modules.recurring.infrastructure.ledger_gateway import LedgerGateway
from luka.modules.recurring.infrastructure.repositories import (
    SqlAlchemyOccurrenceRepository,
    SqlAlchemyRecurringExpenseRepository,
    SqlAlchemyRejectionRepository,
)
from luka.modules.recurring.infrastructure.uow import SqlAlchemyUnitOfWork
from luka.shared.clock import SystemClock

__all__ = ["get_current_user_id"]


async def get_session(request: Request) -> AsyncIterator[AsyncSession]:
    """Sesion por request desde `app.state.session_factory`; rollback si queda abierta."""
    async with request.app.state.session_factory() as session:
        try:
            yield session
        finally:
            if session.in_transaction():
                await session.rollback()


def get_clock() -> SystemClock:
    """Reloj real del sistema (UTC, aware)."""
    return SystemClock()


def get_list_expenses_use_case(session: AsyncSession = Depends(get_session)) -> ListExpenses:
    return ListExpenses(expenses=SqlAlchemyRecurringExpenseRepository(session))


def get_create_expense_use_case(
    session: AsyncSession = Depends(get_session), clock: SystemClock = Depends(get_clock)
) -> CreateExpense:
    return CreateExpense(
        expenses=SqlAlchemyRecurringExpenseRepository(session),
        occurrences=SqlAlchemyOccurrenceRepository(session),
        rejections=SqlAlchemyRejectionRepository(session),
        ledger=LedgerGateway(session),
        clock=clock,
        ids=UuidGenerator(),
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_update_expense_use_case(
    session: AsyncSession = Depends(get_session), clock: SystemClock = Depends(get_clock)
) -> UpdateExpense:
    return UpdateExpense(
        expenses=SqlAlchemyRecurringExpenseRepository(session),
        occurrences=SqlAlchemyOccurrenceRepository(session),
        rejections=SqlAlchemyRejectionRepository(session),
        ledger=LedgerGateway(session),
        clock=clock,
        ids=UuidGenerator(),
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_delete_expense_use_case(session: AsyncSession = Depends(get_session)) -> DeleteExpense:
    return DeleteExpense(
        expenses=SqlAlchemyRecurringExpenseRepository(session),
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_list_occurrences_use_case(
    session: AsyncSession = Depends(get_session),
) -> ListOccurrences:
    return ListOccurrences(
        occurrences=SqlAlchemyOccurrenceRepository(session),
        expenses=SqlAlchemyRecurringExpenseRepository(session),
        ledger=LedgerGateway(session),
    )


def get_get_occurrence_use_case(session: AsyncSession = Depends(get_session)) -> GetOccurrence:
    return GetOccurrence(
        occurrences=SqlAlchemyOccurrenceRepository(session),
        expenses=SqlAlchemyRecurringExpenseRepository(session),
        ledger=LedgerGateway(session),
    )


def get_mark_paid_use_case(
    session: AsyncSession = Depends(get_session), clock: SystemClock = Depends(get_clock)
) -> MarkPaid:
    return MarkPaid(
        occurrences=SqlAlchemyOccurrenceRepository(session),
        ledger=LedgerGateway(session),
        clock=clock,
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_unmark_use_case(session: AsyncSession = Depends(get_session)) -> Unmark:
    return Unmark(
        occurrences=SqlAlchemyOccurrenceRepository(session),
        rejections=SqlAlchemyRejectionRepository(session),
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_skip_use_case(session: AsyncSession = Depends(get_session)) -> Skip:
    return Skip(
        occurrences=SqlAlchemyOccurrenceRepository(session),
        uow=SqlAlchemyUnitOfWork(session),
    )
