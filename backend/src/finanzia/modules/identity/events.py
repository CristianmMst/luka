"""Eventos de dominio que publica/consume identity. Puro: solo stdlib."""

from dataclasses import dataclass
from datetime import datetime
from typing import ClassVar
from uuid import UUID


@dataclass(frozen=True, slots=True)
class UserDeleted:
    """Se emitira cuando se complete el borrado de una cuenta (aun no emitido)."""

    event_id: UUID
    occurred_at: datetime
    user_id: UUID

    event_type: ClassVar[str] = "identity.UserDeleted"
