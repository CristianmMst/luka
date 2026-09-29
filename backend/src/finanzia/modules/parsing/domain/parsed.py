"""`ParsedTransaction`: resultado uniforme de una plantilla regex o del LLM
(spec 006 §4). Frozen/slotted, stdlib solo (P3); mismo estilo que
`ledger.domain.entities` (no se importa: R4/D4).
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal

from finanzia.modules.parsing.domain.enums import Direction

_LAST4_RE = re.compile(r"^\d{1,4}$")


def _require_aware(value: datetime) -> None:
    """Exige que `value` sea un datetime tz-aware (mismo contrato que ledger)."""
    if value.tzinfo is None or value.tzinfo.utcoffset(value) is None:
        raise ValueError("occurred_at debe ser tz-aware")


@dataclass(frozen=True, slots=True)
class ParsedTransaction:
    """Transaccion candidata extraida por una plantilla (`parsed_by="rule:..."`)
    o por el LLM (`parsed_by="llm"`).
    """

    bank: str
    amount: Decimal
    direction: Direction
    occurred_at: datetime
    merchant: str | None
    last4: str | None
    suggested_category: str | None
    parsed_by: str
    confidence: float | None
    # `merchant` es una persona (plantilla con `counterparty: true`): ledger
    # la compara con el titular para detectar transferencias propias.
    merchant_is_person: bool = False

    def __post_init__(self) -> None:
        _require_aware(self.occurred_at)
        if self.amount <= 0:
            raise ValueError(f"amount debe ser mayor que cero: {self.amount}")
        if self.last4 is not None and not _LAST4_RE.match(self.last4):
            raise ValueError(f"last4 invalido: {self.last4!r}")
        if self.confidence is not None and not (0.0 <= self.confidence <= 1.0):
            raise ValueError(f"confidence debe estar entre 0 y 1: {self.confidence}")


__all__ = ["ParsedTransaction"]
