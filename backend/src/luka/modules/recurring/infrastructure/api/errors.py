"""Mapa de errores de dominio de recurring -> `AppError` HTTP (spec 005 SS1, SS10).

Un recurso ajeno siempre es 404, nunca 403 (spec 009 SS4).
"""

from luka.modules.recurring.domain.errors import (
    AccountNotFound,
    CategoryNotFound,
    InvalidMonthRange,
    InvalidRecurringExpense,
    OccurrenceNotFound,
    OccurrenceNotPaid,
    RecurringExpenseNotFound,
    TransactionAlreadyPays,
    TransactionNotExpense,
    TransactionNotFound,
)
from luka.shared.errors import ConflictError, ExceptionMap, NotFoundError, ValidationAppError


def _invalid_field(exc: Exception) -> ValidationAppError:
    field = exc.field if isinstance(exc, InvalidRecurringExpense) else None
    return ValidationAppError(message="Campo invalido", field=field)


RECURRING_EXCEPTION_MAP: ExceptionMap = {
    RecurringExpenseNotFound: lambda e: NotFoundError(),
    OccurrenceNotFound: lambda e: NotFoundError(),
    TransactionNotFound: lambda e: NotFoundError(field="transaction_id"),
    CategoryNotFound: lambda e: NotFoundError(field="category_id"),
    AccountNotFound: lambda e: NotFoundError(field="account_id"),
    TransactionNotExpense: lambda e: ValidationAppError(
        message="La transaccion no es un gasto", field="transaction_id"
    ),
    TransactionAlreadyPays: lambda e: ConflictError(
        message="La transaccion ya paga otro gasto fijo", field="transaction_id"
    ),
    OccurrenceNotPaid: lambda e: ConflictError(message="La ocurrencia ya esta pendiente"),
    InvalidRecurringExpense: _invalid_field,
    InvalidMonthRange: lambda e: ValidationAppError(message="Rango de meses invalido", field="to"),
}
