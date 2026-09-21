"""Schemas Pydantic de la API de ingestion (spec 006 §3.1-3.2, controller ruling 1).

Los requests usan `extra="forbid"`. `client_hash` es el `external_id` del canal
`notification`/`sms_notification` (sha256 hex, spec 006 §4.4): la forma se valida
aqui (borde HTTP) y de nuevo en el dominio (`validate_external_id`), que es la
unica fuente de verdad. Las respuestas nunca exponen datos crudos del mensaje
(P1/P6): `IngestNotificationsResponse` es solo contadores agregados.
"""

from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

_PACKAGE_PATTERN = r"^[a-zA-Z0-9_.]+$"
_CLIENT_HASH_PATTERN = r"^[a-f0-9]{64}$"
_MAX_ITEMS_PER_BATCH = 50
_MAX_TEXT_LEN = 65536
_MAX_TITLE_LEN = 500


# --- Requests: notificaciones --------------------------------------------------------


class NotificationItem(BaseModel):
    """Un item de `POST /v1/ingest/notifications` (spec 006 §3.2, F4.3)."""

    model_config = ConfigDict(extra="forbid")

    package: str = Field(min_length=1, max_length=200, pattern=_PACKAGE_PATTERN)
    channel: Literal["notification", "sms_notification"]
    posted_at: datetime
    title: str | None = Field(default=None, max_length=_MAX_TITLE_LEN)
    text: str = Field(min_length=1, max_length=_MAX_TEXT_LEN)
    client_hash: str = Field(pattern=_CLIENT_HASH_PATTERN)

    @field_validator("posted_at")
    @classmethod
    def _posted_at_debe_ser_aware(cls, value: datetime) -> datetime:
        if value.tzinfo is None or value.tzinfo.utcoffset(value) is None:
            raise ValueError("posted_at debe incluir zona horaria")
        return value


class IngestNotificationsRequest(BaseModel):
    """Body de `POST /v1/ingest/notifications` (spec 005 §5, enmendado)."""

    model_config = ConfigDict(extra="forbid")

    items: list[NotificationItem] = Field(min_length=1, max_length=_MAX_ITEMS_PER_BATCH)


# --- Respuestas -----------------------------------------------------------------------


class IngestNotificationsResponse(BaseModel):
    """200 de `POST /v1/ingest/notifications` (spec 005 §5, enmendado con `discarded`)."""

    accepted: int
    duplicates: int
    discarded: int


class CaptureConfigResponse(BaseModel):
    """200 de `GET /v1/config/capture` (spec 006 §3.1, D6).

    Forma plana derivada de `parsing.public.capture_config()`: listas de strings
    en vez de listas de objetos (`banking_apps`/`sms_sender_patterns` pierden el
    campo `bank` acoplado a `finanzia.modules.ledger.domain.enums.Bank`, que este
    modulo no puede importar, R4).
    """

    version: int
    banking_apps: list[str]
    messages_apps: list[str]
    sms_sender_patterns: list[str]
    email_senders: dict[str, list[str]]


__all__ = [
    "CaptureConfigResponse",
    "IngestNotificationsRequest",
    "IngestNotificationsResponse",
    "NotificationItem",
]
