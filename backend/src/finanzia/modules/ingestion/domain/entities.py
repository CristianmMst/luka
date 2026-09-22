"""Entidades de dominio de ingestion: inmutables, sin dependencias externas (P3)."""

from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus


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


__all__ = ["RawMessage"]
