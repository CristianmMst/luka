"""Eventos de dominio que publica recurring. Puro: solo stdlib."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import ClassVar
from uuid import UUID


@dataclass(frozen=True, slots=True)
class PaymentDueSoon:
    """Toca avisar un gasto fijo pendiente (spec 011 SS5); lo consume notifications.

    `event_id` es determinista por ocurrencia y aviso (1-4): republicarlo no duplica
    el aviso (el `IdempotentHandler` lo absorbe).
    """

    event_id: UUID
    occurred_at: datetime
    user_id: UUID
    occurrence_id: UUID
    name: str
    expected_amount: Decimal
    #: `AAAA-MM-DD`; el codec del bus no serializa `date` (spec 003 SS2.3).
    due_date: str
    #: Que aviso es, 1-4 segun `REMINDER_SLOTS` de recurring. Default para eventos viejos.
    slot: int = 3

    event_type: ClassVar[str] = "recurring.PaymentDueSoon"


__all__ = ["PaymentDueSoon"]
