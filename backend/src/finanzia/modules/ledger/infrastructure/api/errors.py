"""Mapa de errores de dominio de ledger -> `AppError` HTTP (spec 005 SS1, ruling 7).

Recurso ajeno siempre es `NotFoundError` (404), nunca `ForbiddenError` (009 SS4):
`ForbiddenError` (403) queda reservado para acciones no permitidas sobre un recurso
propio o visible (categoria del sistema, borrar una transaccion no manual).
"""

from finanzia.modules.ledger.domain.errors import (
    AccountNotFound,
    AlreadyPaired,
    CategoryNotFound,
    DuplicateAccount,
    DuplicateCategoryName,
    InvalidAmount,
    InvalidCursor,
    InvalidKindChange,
    InvalidLast4,
    NotManualTransaction,
    ReviewAlreadyResolved,
    ReviewItemNotFound,
    SystemCategoryImmutable,
    TransactionNotFound,
    TransferPairInvalid,
)
from finanzia.shared.errors import (
    ConflictError,
    ExceptionMap,
    ForbiddenError,
    NotFoundError,
    ValidationAppError,
)

LEDGER_EXCEPTION_MAP: ExceptionMap = {
    TransactionNotFound: lambda e: NotFoundError(),
    CategoryNotFound: lambda e: NotFoundError(),
    AccountNotFound: lambda e: NotFoundError(),
    SystemCategoryImmutable: lambda e: ForbiddenError(),
    NotManualTransaction: lambda e: ForbiddenError(),
    # `field` se omite: la unicidad es sobre `(bank, last4)`, no sobre `last4` solo.
    DuplicateAccount: lambda e: ConflictError(message="La cuenta ya existe"),
    DuplicateCategoryName: lambda e: ConflictError(message="El nombre ya existe", field="name"),
    AlreadyPaired: lambda e: ConflictError(message="La transaccion ya esta emparejada"),
    TransferPairInvalid: lambda e: ValidationAppError(message="Par de transferencia invalido"),
    InvalidAmount: lambda e: ValidationAppError(message="Monto invalido", field="amount"),
    InvalidLast4: lambda e: ValidationAppError(message="last4 invalido", field="last4"),
    InvalidCursor: lambda e: ValidationAppError(message="Cursor invalido", field="cursor"),
    InvalidKindChange: lambda e: ValidationAppError(message="kind invalido", field="kind"),
    ReviewItemNotFound: lambda e: NotFoundError(),
    ReviewAlreadyResolved: lambda e: ConflictError(message="El item ya fue resuelto"),
}
