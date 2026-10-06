"""Schemas Pydantic de la API de ledger (spec 005 SS6-7, controller ruling 2).

Los requests usan `extra="forbid"`. `AmountStr` valida la forma decimal en el borde
HTTP (`deps.py` la convierte a `Decimal`); el dominio (`quantize_amount`) sigue
siendo la unica fuente de verdad sobre "monto valido" (> 0, finito). Las respuestas
nunca exponen `user_id`/`dedupe_key` de una transaccion (spec 009 SS4/SS5).
"""

from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

from luka.modules.ledger.domain.enums import (
    AccountKind,
    Bank,
    Direction,
    FiscalTag,
    Kind,
)

AmountStr = Annotated[str, Field(pattern=r"^\d{1,12}(\.\d{1,2})?$")]


# --- Requests: transacciones -------------------------------------------------------


class CreateTransactionRequest(BaseModel):
    """Body de `POST /transactions` (spec 005 SS6, alta manual)."""

    model_config = ConfigDict(extra="forbid")

    amount: AmountStr
    direction: Direction
    occurred_at: datetime
    category_id: UUID | None = None
    merchant: str | None = Field(default=None, max_length=200)
    description: str | None = Field(default=None, max_length=500)
    account_id: UUID | None = None
    notes: str | None = Field(default=None, max_length=1000)
    kind: Kind | None = None
    nfc_tag_id: str | None = Field(default=None, max_length=128)

    @field_validator("occurred_at")
    @classmethod
    def _occurred_at_debe_ser_aware(cls, value: datetime) -> datetime:
        if value.tzinfo is None or value.tzinfo.utcoffset(value) is None:
            raise ValueError("occurred_at debe incluir zona horaria")
        return value


class PatchTransactionRequest(BaseModel):
    """Body de `PATCH /transactions/{id}` (spec 005 SS6).

    `model_fields_set` (leido por el router) distingue "no enviado" de "enviado
    como null" para `category_id`/`notes`/`merchant`/`kind`.
    """

    model_config = ConfigDict(extra="forbid")

    category_id: UUID | None = None
    notes: str | None = Field(default=None, max_length=1000)
    merchant: str | None = Field(default=None, max_length=200)
    kind: Kind | None = None
    amount: AmountStr | None = None
    direction: Direction | None = None
    occurred_at: datetime | None = None
    account_id: UUID | None = None
    learn_merchant_rule: bool = True

    @field_validator("occurred_at")
    @classmethod
    def _occurred_at_debe_ser_aware(cls, value: datetime | None) -> datetime | None:
        if value is not None and (value.tzinfo is None or value.tzinfo.utcoffset(value) is None):
            raise ValueError("occurred_at debe incluir zona horaria")
        return value


class TransferPairRequest(BaseModel):
    """Body de `POST /transactions/{id}/transfer-pair`."""

    model_config = ConfigDict(extra="forbid")

    pair_id: UUID


# --- Requests: categorias ------------------------------------------------------------


class CreateCategoryRequest(BaseModel):
    """Body de `POST /categories` (spec 005 SS7)."""

    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=1, max_length=80)
    icon: str | None = None
    color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    fiscal_tag: FiscalTag


class PatchCategoryRequest(BaseModel):
    """Body de `PATCH /categories/{id}` (spec 005 SS7)."""

    model_config = ConfigDict(extra="forbid")

    name: str | None = Field(default=None, min_length=1, max_length=80)
    icon: str | None = None
    color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    fiscal_tag: FiscalTag | None = None


# --- Requests: cuentas -----------------------------------------------------------------


class CreateAccountRequest(BaseModel):
    """Body de `POST /accounts` (spec 005 SS7)."""

    model_config = ConfigDict(extra="forbid")

    bank: Bank
    kind: AccountKind
    last4: str | None = Field(default=None, pattern=r"^[0-9]{1,4}$")
    alias: str | None = Field(default=None, max_length=60)


class PatchAccountRequest(BaseModel):
    """Body de `PATCH /accounts/{id}` (spec 005 SS7; el banco no es editable)."""

    model_config = ConfigDict(extra="forbid")

    kind: AccountKind | None = None
    last4: str | None = Field(default=None, pattern=r"^[0-9]{1,4}$")
    alias: str | None = Field(default=None, max_length=60)


# --- Requests: revision (spec 005 SS7, D1) -----------------------------------------


class ConvertReviewRequest(BaseModel):
    """Body de `POST /review/{raw_message_id}/convert`: igual a `CreateTransactionRequest`
    salvo `nfc_tag_id` (la fuente es siempre el `raw_message`, no NFC).
    """

    model_config = ConfigDict(extra="forbid")

    amount: AmountStr
    direction: Direction
    occurred_at: datetime
    category_id: UUID | None = None
    merchant: str | None = Field(default=None, max_length=200)
    description: str | None = Field(default=None, max_length=500)
    account_id: UUID | None = None
    notes: str | None = Field(default=None, max_length=1000)
    kind: Kind | None = None

    @field_validator("occurred_at")
    @classmethod
    def _occurred_at_debe_ser_aware(cls, value: datetime) -> datetime:
        if value.tzinfo is None or value.tzinfo.utcoffset(value) is None:
            raise ValueError("occurred_at debe incluir zona horaria")
        return value


# --- Respuestas ------------------------------------------------------------------------


class TransactionSourceResponse(BaseModel):
    """Una fuente cruda adjunta a una transaccion (spec 005 SS6)."""

    id: UUID
    channel: str
    raw_message_id: UUID | None
    received_at: datetime


class TransactionSummary(BaseModel):
    """Resumen de una transaccion, usado como `pair` en `TransactionResponse`."""

    id: UUID
    amount: str
    direction: str
    kind: str
    occurred_at: datetime
    merchant: str | None
    bank: str | None
    account_id: UUID | None
    category_id: UUID
    fiscal_tag: str


class TransactionListItem(BaseModel):
    """Item de `GET /transactions` (spec 005 SS6): sin `sources`/`pair`.

    `sources` solo se expone en `GET /transactions/{id}` (RNF-3 p95 < 300 ms: cargarlas
    por fila haria del listado una consulta N+1). Comparte todos los demas campos con
    `TransactionResponse`, que hereda de esta clase y agrega `sources`/`pair`.
    `channels` son los valores unicos de `Channel` de sus fuentes, en el orden estable
    del enum (`email`, `notification`, `sms_notification`, `manual`, `nfc`); `[]` si la
    transaccion no tiene fuentes (F4.2).
    """

    id: UUID
    amount: str
    currency: str
    direction: str
    kind: str
    occurred_at: datetime
    merchant: str | None
    description: str | None
    bank: str | None
    account_id: UUID | None
    category_id: UUID
    fiscal_tag: str
    transfer_pair_id: UUID | None
    transfer_auto: bool
    parsed_by: str
    confidence: float | None
    notes: str | None
    created_at: datetime
    updated_at: datetime
    channels: list[str]


class TransactionResponse(TransactionListItem):
    """Representacion publica completa de una transaccion (spec 005 SS6, SS9.3).

    Omite deliberadamente `user_id` y `dedupe_key`: son detalles de persistencia
    del propio usuario autenticado, sin valor para el cliente (spec 009 SS4/SS5).
    """

    sources: list[TransactionSourceResponse]
    pair: TransactionSummary | None


class CategoryResponse(BaseModel):
    """Representacion publica de una categoria (spec 005 SS7)."""

    id: UUID
    user_id: UUID | None
    slug: str | None
    name: str
    icon: str | None
    color: str | None
    fiscal_tag: str
    is_system: bool


class AccountResponse(BaseModel):
    """Representacion publica de una cuenta vinculada (spec 005 SS7)."""

    id: UUID
    bank: str
    kind: str
    last4: str | None
    alias: str | None


class ReviewEntryResponse(BaseModel):
    """Item de `GET /review` (spec 005 SS7, D1): mensaje crudo + motivo de la cola."""

    raw_message_id: UUID
    channel: str
    bank: str | None
    sender: str
    received_at: datetime
    reason: str
    partial_extract: dict[str, str]
    text: str | None
    created_at: datetime


class DiscardReviewResponse(BaseModel):
    """Respuesta de `POST /review/{raw_message_id}/discard` (spec 005 SS7)."""

    raw_message_id: UUID
    resolution: str
    resolved_at: datetime
