"""Entidades de dominio de ingestion: inmutables, sin dependencias externas (P3)."""

from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from finanzia.modules.ingestion.domain.enums import Channel, GmailConnectionStatus, RawMessageStatus


def _require_aware(value: datetime) -> None:
    """Exige que `value` sea un datetime tz-aware; helper compartido del dominio."""
    if value.tzinfo is None or value.tzinfo.utcoffset(value) is None:
        raise ValueError("datetime debe ser tz-aware")


@dataclass(frozen=True, slots=True)
class RawMessage:
    """Un mensaje crudo capturado por email/notificacion/SMS (spec 004 §2.7)."""

    id: UUID
    user_id: UUID
    channel: Channel
    external_id: str
    sender: str
    bank: str | None
    body: str | None
    status: RawMessageStatus
    received_at: datetime
    purge_after: datetime
    #: Republicaciones hechas por el cron de reencolado (riesgo 4 / D9); a partir de
    #: `RequeuePendingRawMessages.max_attempts` la fila deja de reencolarse.
    requeue_attempts: int = 0

    def __post_init__(self) -> None:
        _require_aware(self.received_at)
        _require_aware(self.purge_after)


@dataclass(frozen=True, slots=True)
class GmailConnection:
    """Conexion Gmail de un usuario, 1:1 con `users` (spec 004 §2.3, F3.2).

    `refresh_token_enc` es el blob cifrado con AES-256-GCM (`shared/crypto`); el
    dominio nunca ve el refresh token en claro ni la llave de cifrado.
    """

    user_id: UUID
    email: str
    refresh_token_enc: bytes
    history_id: int | None
    watch_expires_at: datetime | None
    status: GmailConnectionStatus
    last_sync_at: datetime | None
    created_at: datetime
    updated_at: datetime

    def __post_init__(self) -> None:
        _require_aware(self.created_at)
        _require_aware(self.updated_at)
        if self.watch_expires_at is not None:
            _require_aware(self.watch_expires_at)
        if self.last_sync_at is not None:
            _require_aware(self.last_sync_at)


__all__ = ["GmailConnection", "RawMessage"]
