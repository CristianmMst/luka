"""Validacion post-LLM (spec 006 §4.2). Puro (stdlib solo, P3): el adapter
DeepSeek (infrastructure) mapea su JSON a `LlmExtraction`; este modulo decide
si el resultado se puede convertir en `ParsedTransaction` o debe ir a
revision.
"""

from __future__ import annotations

from dataclasses import dataclass, fields
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Literal

from finanzia.modules.parsing.domain.enums import Direction, ParseFailureReason
from finanzia.modules.parsing.domain.parsed import ParsedTransaction

_MAX_DRIFT = timedelta(days=7)
_OTHER_BANK = "other"


@dataclass(frozen=True, slots=True)
class LlmExtraction:
    """Salida cruda del LLM ya deserializada (spec 006 §4.2, esquema JSON)."""

    is_transaction: bool
    amount: Decimal | None
    currency: str | None
    direction: Direction | None
    merchant: str | None
    occurred_at: datetime | None
    bank: str | None
    last4: str | None
    suggested_category: str | None
    confidence: float


@dataclass(frozen=True, slots=True)
class Rejected:
    """El LLM no produjo una transaccion valida: va a `review_queue` (D12)."""

    reason: ParseFailureReason | Literal["not_transaction"]
    partial: dict[str, str]


def _partial_extract(x: LlmExtraction) -> dict[str, str]:
    """Los campos no-`None` de `x` (salvo `is_transaction`), como strings,
    para `ParseFailed.partial_extract` (D2: nunca se persiste el cuerpo).
    """
    partial: dict[str, str] = {}
    for field in fields(x):
        if field.name == "is_transaction":
            continue
        value = getattr(x, field.name)
        if value is None:
            continue
        if isinstance(value, Direction):
            partial[field.name] = value.value
        elif isinstance(value, datetime):
            partial[field.name] = value.isoformat()
        else:
            partial[field.name] = str(value)
    return partial


def _is_aware(value: datetime) -> bool:
    return value.tzinfo is not None and value.tzinfo.utcoffset(value) is not None


def validate_extraction(
    x: LlmExtraction,
    received_at: datetime,
    known_banks: frozenset[str],
    threshold: float,
) -> ParsedTransaction | Rejected:
    """Valida la salida del LLM y produce un `ParsedTransaction` o `Rejected`.

    `known_banks` son los bancos con allowlist (`SenderAllowlist.known_banks()`);
    `"other"` siempre se acepta como banco valido (mensajes de bancos fuera
    del alcance MVP, p. ej. Nu, spec 001).
    """
    if not x.is_transaction:
        return Rejected(reason="not_transaction", partial=_partial_extract(x))

    invalid_output = (
        x.amount is None
        or x.amount <= 0
        or x.occurred_at is None
        or not _is_aware(x.occurred_at)
        or not (received_at - _MAX_DRIFT <= x.occurred_at <= received_at + _MAX_DRIFT)
        or x.bank is None
        or (x.bank not in known_banks and x.bank != _OTHER_BANK)
        or x.direction is None
    )
    if invalid_output:
        return Rejected(reason=ParseFailureReason.LLM_INVALID_OUTPUT, partial=_partial_extract(x))

    if x.confidence < threshold:
        return Rejected(reason=ParseFailureReason.LLM_LOW_CONFIDENCE, partial=_partial_extract(x))

    assert x.amount is not None  # noqa: S101 - descartado arriba, ayuda a pyright
    assert x.occurred_at is not None  # noqa: S101
    assert x.bank is not None  # noqa: S101
    assert x.direction is not None  # noqa: S101

    return ParsedTransaction(
        bank=x.bank,
        amount=x.amount,
        direction=x.direction,
        occurred_at=x.occurred_at,
        merchant=x.merchant,
        last4=x.last4,
        suggested_category=x.suggested_category,
        parsed_by="llm",
        confidence=x.confidence,
    )


__all__ = ["LlmExtraction", "Rejected", "validate_extraction"]
