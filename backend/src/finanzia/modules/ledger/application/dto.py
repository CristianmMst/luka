"""DTOs de entrada/salida de los casos de uso de ledger (frozen, stdlib puro)."""

from __future__ import annotations

import enum
from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from uuid import UUID

from finanzia.modules.ledger.domain.entities import Transaction, TransactionSource
from finanzia.modules.ledger.domain.enums import (
    AccountKind,
    Bank,
    Channel,
    Direction,
    FiscalTag,
    Kind,
)
from finanzia.modules.ledger.domain.review import ReviewItem, ReviewReason

# --- Sentinel "no establecido" en un PATCH parcial (distinto de `None`) -----------
#
# Se implementa como un `Enum` de un solo miembro (no una clase cualquiera) porque
# es el unico truco que pyright narrows correctamente con `is`/`is not`: al ser un
# valor `Literal`, excluir `UNSET` de una union `T | Unset` dentro de un `if campo is
# not UNSET:` sí reduce el tipo a `T` (una clase normal con una sola instancia no lo
# permite: pyright no la trata como singleton a efectos de narrowing).


class _Unset(enum.Enum):
    """Tipo del sentinel `UNSET`: enum de un solo miembro (narrowing pyright-friendly)."""

    UNSET = enum.auto()

    def __repr__(self) -> str:
        return "UNSET"

    def __bool__(self) -> bool:
        return False


Unset = _Unset
"""Alias de tipo para anotar campos de PATCH: `campo: T | Unset = UNSET`."""

UNSET = _Unset.UNSET
"""Sentinel de valor: unico representante de "campo no enviado" en un PATCH."""


# --- Paginacion (keyset opaco, spec 005 SS1) --------------------------------------


@dataclass(frozen=True, slots=True)
class Cursor:
    """Posicion de paginacion: par `(sort_key, id)` usado como llave de continuacion."""

    sort_key: datetime
    id: UUID


@dataclass(frozen=True, slots=True)
class Filters:
    """Filtros de `ListTransactions` (spec 005 SS6)."""

    from_: datetime | None = None
    to: datetime | None = None
    kind: Kind | None = None
    category_id: UUID | None = None
    bank: Bank | None = None
    account_id: UUID | None = None
    channel: Channel | None = None
    q: str | None = None
    updated_since: datetime | None = None


@dataclass(frozen=True, slots=True)
class Page:
    """Pagina de transacciones: `next_cursor is None` marca el final del listado."""

    items: tuple[Transaction, ...]
    next_cursor: Cursor | None


# --- Captura de transacciones (spec 004 SS3, spec 006) ----------------------------


@dataclass(frozen=True, slots=True)
class SourceInput:
    """Fuente cruda que origino una captura (email/notificacion/SMS/manual/NFC)."""

    channel: Channel
    raw_message_id: UUID | None
    received_at: datetime


@dataclass(frozen=True, slots=True)
class CapturedTransactionCommand:
    """Comando de entrada de `RecordCapturedTransaction`."""

    user_id: UUID
    bank: Bank
    amount: Decimal
    direction: Direction
    occurred_at: datetime
    last4: str | None
    merchant: str | None
    description: str | None
    suggested_category_slug: str | None
    parsed_by: str
    confidence: float | None
    source: SourceInput


@dataclass(frozen=True, slots=True)
class Recorded:
    """Resultado de `RecordCapturedTransaction`: `created=False` en un dedupe hit."""

    transaction: Transaction
    created: bool
    source_attached: bool


@dataclass(frozen=True, slots=True)
class ManualTransactionCommand:
    """Comando de entrada de `CreateManualTransaction`."""

    user_id: UUID
    amount: Decimal
    direction: Direction
    occurred_at: datetime
    category_id: UUID | None
    merchant: str | None
    description: str | None
    account_id: UUID | None
    notes: str | None
    channel: Channel = Channel.MANUAL
    kind: Kind | None = None


# --- Detalle / edicion de una transaccion (spec 005 SS6) --------------------------


@dataclass(frozen=True, slots=True)
class TransactionDetail:
    """Detalle de una transaccion: sus fuentes y, si esta emparejada, su contraparte."""

    transaction: Transaction
    sources: tuple[TransactionSource, ...]
    pair: Transaction | None


@dataclass(frozen=True, slots=True)
class TransactionPatch:
    """PATCH parcial de una transaccion; los campos no enviados quedan en `UNSET`."""

    category_id: UUID | Unset = UNSET
    notes: str | Unset | None = UNSET
    merchant: str | Unset | None = UNSET
    kind: Kind | Unset = UNSET
    learn_merchant_rule: bool = True


# --- Categorias (spec 005 SS7) ----------------------------------------------------


@dataclass(frozen=True, slots=True)
class CategoryInput:
    """Datos de entrada de `CreateCategory`."""

    name: str
    icon: str | None
    color: str | None
    fiscal_tag: FiscalTag


@dataclass(frozen=True, slots=True)
class CategoryPatch:
    """PATCH parcial de una categoria propia."""

    name: str | Unset = UNSET
    icon: str | Unset | None = UNSET
    color: str | Unset | None = UNSET
    fiscal_tag: FiscalTag | Unset = UNSET


# --- Cuentas vinculadas (spec 005 SS7) ---------------------------------------------


@dataclass(frozen=True, slots=True)
class AccountInput:
    """Datos de entrada de `CreateAccount`."""

    bank: Bank
    kind: AccountKind
    last4: str | None
    alias: str | None


@dataclass(frozen=True, slots=True)
class AccountPatch:
    """PATCH parcial de una cuenta vinculada (el banco no es editable)."""

    kind: AccountKind | Unset = UNSET
    last4: str | Unset | None = UNSET
    alias: str | Unset | None = UNSET


# --- Cola de revision (spec 004 SS2.10, D1) ---------------------------------------


@dataclass(frozen=True, slots=True)
class ReviewSourceView:
    """Proyeccion del `raw_message` asociado a un item de revision (via `ReviewSourcePort`)."""

    raw_message_id: UUID
    channel: Channel
    bank: Bank | None
    sender: str
    text: str | None
    received_at: datetime


@dataclass(frozen=True, slots=True)
class ReviewEntry:
    """Un item de la cola junto con la vista de su mensaje crudo (si aun existe)."""

    item: ReviewItem
    source: ReviewSourceView | None


@dataclass(frozen=True, slots=True)
class ReviewPage:
    """Pagina de `ListReview`: `next_cursor is None` marca el final del listado."""

    items: tuple[ReviewEntry, ...]
    next_cursor: Cursor | None


@dataclass(frozen=True, slots=True)
class EnqueueForReviewCommand:
    """Comando de entrada de `EnqueueForReview` (publicado por `ParseFailed`)."""

    raw_message_id: UUID
    user_id: UUID
    reason: ReviewReason
    partial_extract: Mapping[str, str]


@dataclass(frozen=True, slots=True)
class ConvertReviewCommand:
    """Comando de entrada de `ConvertReviewItem`: mismos campos que un alta manual."""

    user_id: UUID
    raw_message_id: UUID
    amount: Decimal
    direction: Direction
    occurred_at: datetime
    category_id: UUID | None
    merchant: str | None
    description: str | None
    account_id: UUID | None
    notes: str | None
    kind: Kind | None


__all__ = [
    "UNSET",
    "AccountInput",
    "AccountPatch",
    "CapturedTransactionCommand",
    "CategoryInput",
    "CategoryPatch",
    "ConvertReviewCommand",
    "Cursor",
    "EnqueueForReviewCommand",
    "Filters",
    "ManualTransactionCommand",
    "Page",
    "Recorded",
    "ReviewEntry",
    "ReviewPage",
    "ReviewSourceView",
    "SourceInput",
    "TransactionDetail",
    "TransactionPatch",
    "Unset",
]
