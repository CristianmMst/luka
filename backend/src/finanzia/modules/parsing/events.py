"""Eventos de dominio que publica/consume parsing.

Puro (R3a): solo stdlib y el propio `parsing.domain.enums` (permitido explicitamente
por el controller ruling de la Task 2 — R3a solo prohibe `shared`, `application`,
`infrastructure` y terceros, no el `domain` del propio modulo).
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import ClassVar
from uuid import NAMESPACE_URL, UUID, uuid5

from finanzia.modules.parsing.domain.enums import Direction, ParseFailureReason


@dataclass(frozen=True, slots=True)
class TransactionParsed:
    """Parsing extrajo con exito una transaccion candidata (D2: solo ids/valores).

    `channel`/`bank` van como `str` (no el enum) porque son metadatos de paso: el
    consumidor (ledger) es quien decide como tipar/normalizar el banco (D4).
    """

    event_id: UUID
    occurred_at: datetime
    raw_message_id: UUID
    user_id: UUID
    channel: str
    bank: str
    amount: Decimal
    direction: Direction
    transaction_occurred_at: datetime
    last4: str | None
    merchant: str | None
    suggested_category: str | None
    parsed_by: str
    confidence: float | None
    received_at: datetime

    event_type: ClassVar[str] = "parsing.TransactionParsed"


@dataclass(frozen=True, slots=True)
class ParseFailed:
    """Parsing no pudo extraer una transaccion; el mensaje va a revision (ledger)."""

    event_id: UUID
    occurred_at: datetime
    raw_message_id: UUID
    user_id: UUID
    channel: str
    bank: str | None
    reason: ParseFailureReason
    partial_extract: dict[str, str]
    received_at: datetime

    event_type: ClassVar[str] = "parsing.ParseFailed"


def deterministic_event_id(outcome: str, raw_message_id: UUID) -> UUID:
    """`event_id` determinista por resultado + `raw_message_id` (D8).

    Un reproceso del mismo `raw_message_id` con el mismo `outcome` (p. ej.
    "transaction_parsed" o el `reason` de un `ParseFailed`) produce el mismo
    `event_id`, asi que el `IdempotentHandler` absorbe la reentrega aunque el
    evento haya llegado en una entrada de stream distinta.
    """
    return uuid5(NAMESPACE_URL, f"finanzia:parsing:{outcome}:{raw_message_id}")


__all__ = ["ParseFailed", "TransactionParsed", "deterministic_event_id"]
