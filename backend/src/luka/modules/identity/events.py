"""Eventos de dominio que publica/consume identity. Puro: solo stdlib."""

from dataclasses import dataclass
from datetime import datetime
from typing import ClassVar
from uuid import UUID


@dataclass(frozen=True, slots=True)
class UserDeleted:
    """La cuenta se borro (`DELETE /v1/me`, RF-11.3): el CASCADE ya se llevo
    sus datos. Lo publica `DeleteAccount` despues del commit."""

    event_id: UUID
    occurred_at: datetime
    user_id: UUID

    event_type: ClassVar[str] = "identity.UserDeleted"
