"""Entidades de dominio de ledger: inmutables, sin dependencias externas (P3)."""

import re
from dataclasses import dataclass
from datetime import datetime
from decimal import ROUND_HALF_UP, Decimal, InvalidOperation
from uuid import UUID

from luka.modules.ledger.domain.classification import derive_kind, resolve_fiscal_tag
from luka.modules.ledger.domain.enums import (
    AccountKind,
    Bank,
    Channel,
    Direction,
    FiscalTag,
    Kind,
)
from luka.modules.ledger.domain.errors import InvalidAmount, InvalidKindChange, InvalidLast4

_CENTS = Decimal("0.01")
_LAST4_PATTERN = re.compile(r"^[0-9]{1,4}$")


def _require_aware(value: datetime) -> None:
    """Exige que `value` sea un datetime tz-aware; helper compartido del dominio."""
    if value.tzinfo is None or value.tzinfo.utcoffset(value) is None:
        raise ValueError("datetime debe ser tz-aware")


def quantize_amount(value: Decimal | int | str) -> Decimal:
    """Redondea `value` a 2 decimales (`ROUND_HALF_UP`); exige un monto finito y > 0."""
    try:
        amount = value if isinstance(value, Decimal) else Decimal(value)
    except InvalidOperation as exc:
        raise InvalidAmount(f"monto invalido: {value!r}") from exc
    if not amount.is_finite():
        raise InvalidAmount(f"monto no finito: {value!r}")
    quantized = amount.quantize(_CENTS, rounding=ROUND_HALF_UP)
    if quantized <= 0:
        raise InvalidAmount(f"monto debe ser mayor que cero: {quantized}")
    return quantized


@dataclass(frozen=True, slots=True)
class Transaction:
    """Movimiento de dinero, capturado o manual (spec 004 SS2.5)."""

    id: UUID
    user_id: UUID
    amount: Decimal
    currency: str
    direction: Direction
    kind: Kind
    occurred_at: datetime
    merchant: str | None
    description: str | None
    bank: Bank | None
    account_id: UUID | None
    category_id: UUID
    fiscal_tag: FiscalTag
    transfer_pair_id: UUID | None
    transfer_auto: bool
    transfer_exclusions: frozenset[UUID]
    dedupe_key: str
    parsed_by: str
    confidence: float | None
    notes: str | None
    created_at: datetime
    updated_at: datetime

    def __post_init__(self) -> None:
        _require_aware(self.occurred_at)
        _require_aware(self.created_at)
        _require_aware(self.updated_at)


@dataclass(frozen=True, slots=True)
class TransactionSource:
    """Fuente cruda (email/notificacion/SMS/manual) que alimento una transaccion."""

    id: UUID
    transaction_id: UUID
    raw_message_id: UUID | None
    channel: Channel
    received_at: datetime

    def __post_init__(self) -> None:
        _require_aware(self.received_at)


@dataclass(frozen=True, slots=True)
class TransactionTombstone:
    """Lapida de una captura borrada por el usuario (spec 004 SS3): lo minimo para
    reconocer otra fuente de la misma compra y no volver a crearla (P6)."""

    id: UUID
    user_id: UUID
    dedupe_key: str
    bank: Bank
    amount: Decimal
    direction: Direction
    occurred_at: datetime
    channels: frozenset[Channel]
    # `dedupe.capture_origin` de su `parsed_by` (p. ej. `rule:bancolombia`).
    origin: str
    deleted_at: datetime

    def __post_init__(self) -> None:
        _require_aware(self.occurred_at)
        _require_aware(self.deleted_at)


@dataclass(frozen=True, slots=True)
class Category:
    """Categoria de clasificacion: del sistema (`user_id is None`) o propia del usuario."""

    id: UUID
    user_id: UUID | None
    slug: str | None
    name: str
    icon: str | None
    color: str | None
    fiscal_tag: FiscalTag

    @property
    def is_system(self) -> bool:
        """`True` si es una categoria del sistema (no pertenece a ningun usuario)."""
        return self.user_id is None


@dataclass(frozen=True, slots=True)
class LinkedAccount:
    """Cuenta o tarjeta vinculada por el usuario (spec 004 SS2.4)."""

    id: UUID
    user_id: UUID
    bank: Bank
    kind: AccountKind
    last4: str | None
    alias: str | None

    def __post_init__(self) -> None:
        if self.last4 is not None and not _LAST4_PATTERN.match(self.last4):
            raise InvalidLast4(f"last4 invalido: {self.last4!r}")


@dataclass(frozen=True, slots=True)
class MerchantRule:
    """Regla de usuario: patron de comercio normalizado -> categoria."""

    id: UUID
    user_id: UUID
    merchant_pattern: str
    category_id: UUID


def new_manual_transaction(  # noqa: PLR0913 - un parametro por atributo inmutable de Transaction
    *,
    id: UUID,
    user_id: UUID,
    amount: Decimal | int | str,
    direction: Direction,
    occurred_at: datetime,
    category: Category,
    now: datetime,
    dedupe_key: str,
    merchant: str | None = None,
    description: str | None = None,
    bank: Bank | None = None,
    account_id: UUID | None = None,
    notes: str | None = None,
    kind: Kind | None = None,
) -> Transaction:
    """Crea una transaccion registrada manualmente por el usuario (spec 004 SS2.6).

    `kind` es opcional: por defecto se deriva de `direction` (spec 004 SS2.5). Si se
    pasa explicitamente `expense`/`income`, debe coincidir con `derive_kind(direction)`
    o se lanza `InvalidKindChange` (el mismo error que usa el PATCH de `kind` en
    `update_transaction.py`: cubre tanto el cambio post-creacion como la creacion
    inconsistente). Solo `kind=transfer` puede anular la direccion derivada.
    """
    if kind in (Kind.EXPENSE, Kind.INCOME) and kind != derive_kind(direction):
        raise InvalidKindChange("kind incompatible con la direccion de la transaccion")
    resolved_kind = kind or derive_kind(direction)
    return Transaction(
        id=id,
        user_id=user_id,
        amount=quantize_amount(amount),
        currency="COP",
        direction=direction,
        kind=resolved_kind,
        occurred_at=occurred_at,
        merchant=merchant,
        description=description,
        bank=bank,
        account_id=account_id,
        category_id=category.id,
        fiscal_tag=resolve_fiscal_tag(resolved_kind, category.fiscal_tag),
        transfer_pair_id=None,
        transfer_auto=False,
        transfer_exclusions=frozenset(),
        dedupe_key=dedupe_key,
        parsed_by="manual",
        confidence=None,
        notes=notes,
        created_at=now,
        updated_at=now,
    )


def new_captured_transaction(  # noqa: PLR0913 - un parametro por atributo inmutable de Transaction
    *,
    id: UUID,
    user_id: UUID,
    amount: Decimal | int | str,
    direction: Direction,
    occurred_at: datetime,
    category: Category,
    now: datetime,
    bank: Bank,
    last4: str | None,
    merchant: str | None,
    description: str | None,
    account_id: UUID | None,
    parsed_by: str,
    confidence: float | None,
    dedupe_key: str,
) -> Transaction:
    """Crea una transaccion capturada automaticamente (email/notificacion/SMS).

    `last4` no se almacena en la transaccion (solo en `LinkedAccount`): se recibe aqui
    porque el llamador ya lo uso para calcular `dedupe_key` (spec 004 SS3).
    """
    resolved_kind = derive_kind(direction)
    return Transaction(
        id=id,
        user_id=user_id,
        amount=quantize_amount(amount),
        currency="COP",
        direction=direction,
        kind=resolved_kind,
        occurred_at=occurred_at,
        merchant=merchant,
        description=description,
        bank=bank,
        account_id=account_id,
        category_id=category.id,
        fiscal_tag=resolve_fiscal_tag(resolved_kind, category.fiscal_tag),
        transfer_pair_id=None,
        transfer_auto=False,
        transfer_exclusions=frozenset(),
        dedupe_key=dedupe_key,
        parsed_by=parsed_by,
        confidence=confidence,
        notes=None,
        created_at=now,
        updated_at=now,
    )
