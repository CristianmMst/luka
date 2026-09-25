"""Errores de dominio de ledger (sin dependencias de framework, P3)."""


class LedgerError(Exception):
    """Base de todos los errores de dominio del modulo ledger."""


class TransactionNotFound(LedgerError):  # noqa: N818 - nombre descriptivo, no de excepcion generica
    """No existe una transaccion con el identificador solicitado."""


class CategoryNotFound(LedgerError):  # noqa: N818
    """No existe una categoria con el identificador solicitado."""


class AccountNotFound(LedgerError):  # noqa: N818
    """No existe una cuenta vinculada con el identificador solicitado."""


class SystemCategoryImmutable(LedgerError):  # noqa: N818
    """Las categorias del sistema (`user_id is None`) no se pueden modificar ni borrar."""


class NotManualTransaction(LedgerError):  # noqa: N818
    """La operacion solicitada solo aplica a transacciones creadas manualmente."""


class DuplicateAccount(LedgerError):  # noqa: N818
    """Ya existe una cuenta vinculada equivalente para el usuario."""


class DuplicateCategoryName(LedgerError):  # noqa: N818
    """Ya existe una categoria con ese nombre para el usuario."""


class TransferPairInvalid(LedgerError):  # noqa: N818
    """El par propuesto no cumple las condiciones para ser una transferencia (spec 004 SS4)."""

    def __init__(self, reason: str) -> None:
        super().__init__(reason)
        self.reason = reason


class AlreadyPaired(LedgerError):  # noqa: N818
    """La transaccion ya tiene una pareja de transferencia asignada."""


class InvalidAmount(LedgerError):  # noqa: N818
    """El monto no es finito o no es mayor que cero."""


class InvalidLast4(LedgerError):  # noqa: N818
    """Los ultimos 4 digitos de la cuenta no cumplen el formato esperado."""


class InvalidCursor(LedgerError):  # noqa: N818
    """El cursor de paginacion recibido no es valido."""


class InvalidKindChange(LedgerError):  # noqa: N818
    """El `kind` solicitado en un PATCH es incompatible con la `direction` de la transaccion."""


class ReviewItemNotFound(LedgerError):  # noqa: N818
    """No existe un item de revision con ese `raw_message_id` para el usuario (o es ajeno)."""


class ReviewAlreadyResolved(LedgerError):  # noqa: N818
    """El item de revision ya fue convertido o descartado."""


class CaptureAlreadyResolved(LedgerError):  # noqa: N818
    """La captura viene de un `raw_message` cuyo item de revision el usuario ya
    convirtio o descarto: registrarla duplicaria la transaccion (spec 006 SS4.4).
    """
