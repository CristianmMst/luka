"""Eventos de dominio que publica/consume ledger. Puro: solo stdlib."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import ClassVar
from uuid import UUID

from luka.modules.ledger.domain.enums import Direction, FiscalTag, Kind


@dataclass(frozen=True, slots=True)
class TransactionCaptured:
    """Una transaccion nueva quedo registrada (spec 004 SS3; nunca en un dedupe hit)."""

    event_id: UUID
    occurred_at: datetime
    user_id: UUID
    transaction_id: UUID
    kind: Kind
    fiscal_tag: FiscalTag
    amount: Decimal
    direction: Direction
    category_id: UUID
    transaction_occurred_at: datetime
    created: bool
    # Para el matcher de gastos fijos (spec 011 SS4): comercio ya normalizado y
    # cuenta vinculada. Con default para decodificar eventos viejos del stream.
    merchant: str | None = None
    account_id: UUID | None = None

    event_type: ClassVar[str] = "ledger.TransactionCaptured"


@dataclass(frozen=True, slots=True)
class TransactionDeleted:
    """Se borro una transaccion manual (spec 005 SS6); recurring libera su ocurrencia."""

    event_id: UUID
    occurred_at: datetime
    user_id: UUID
    transaction_id: UUID

    event_type: ClassVar[str] = "ledger.TransactionDeleted"


__all__ = ["TransactionCaptured", "TransactionDeleted"]
