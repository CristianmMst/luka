"""Errores de dominio de recurring (mapeados a HTTP en `infrastructure/api/errors.py`)."""


class RecurringError(Exception):
    """Base de los errores de recurring."""


class RecurringExpenseNotFound(RecurringError):  # noqa: N818 - nombre de dominio
    """El gasto fijo no existe o es de otro usuario (404, spec 009 SS4)."""


class OccurrenceNotFound(RecurringError):  # noqa: N818 - nombre de dominio
    """La ocurrencia no existe o es de otro usuario (404)."""


class TransactionNotFound(RecurringError):  # noqa: N818 - nombre de dominio
    """La transaccion elegida no existe o es de otro usuario (404)."""


class CategoryNotFound(RecurringError):  # noqa: N818 - nombre de dominio
    """La categoria no es visible para el usuario (404)."""


class AccountNotFound(RecurringError):  # noqa: N818 - nombre de dominio
    """La cuenta no es del usuario (404)."""


class TransactionNotExpense(RecurringError):  # noqa: N818 - nombre de dominio
    """La transaccion elegida no es un gasto (400, `field=transaction_id`)."""


class TransactionAlreadyPays(RecurringError):  # noqa: N818 - nombre de dominio
    """La transaccion ya paga otra ocurrencia (409, `field=transaction_id`)."""


class OccurrenceNotPaid(RecurringError):  # noqa: N818 - nombre de dominio
    """Deshacer sobre una ocurrencia `pending` (409)."""


class InvalidRecurringExpense(RecurringError):  # noqa: N818 - nombre de dominio
    """Un campo del gasto fijo no cumple las reglas (400 con `field`)."""

    def __init__(self, field: str) -> None:
        super().__init__(field)
        self.field = field


class InvalidMonthRange(RecurringError):  # noqa: N818 - nombre de dominio
    """Rango `from`/`to` invertido o de mas de 12 meses (400, `field=to`)."""
