"""Dominio de la cola de revision (spec 004 SS2.10, D1, D12): mensajes crudos que
parsing no pudo convertir en transaccion y esperan una accion manual del usuario.

Solo stdlib (P3). `ReviewReason` duplica por nombre a
`parsing.domain.enums.ParseFailureReason` (mismos 8 valores): R4 prohibe que ledger
importe internals de parsing, asi que el consumidor (`infrastructure/consumers.py`)
convierte `ReviewReason(event.reason.value)` en el borde.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from uuid import UUID


class ReviewReason(StrEnum):
    """Motivo por el que un mensaje crudo cayo en revision (controller ruling SS5, D12).

    Lista cerrada de 8 valores; un motivo nuevo requiere un ruling explicito.
    """

    NO_TEMPLATE = "no_template"
    LLM_DISABLED = "llm_disabled"
    LLM_BUDGET_EXCEEDED = "llm_budget_exceeded"
    LLM_INVALID_JSON = "llm_invalid_json"
    LLM_INVALID_OUTPUT = "llm_invalid_output"
    LLM_LOW_CONFIDENCE = "llm_low_confidence"
    LLM_ERROR = "llm_error"
    BODY_PURGED = "body_purged"


class ReviewResolution(StrEnum):
    """Como se cerro un item de revision."""

    CONVERTED = "converted"
    DISCARDED = "discarded"


def _require_aware(value: datetime) -> None:
    """Exige que `value` sea un datetime tz-aware (mismo contrato que `entities.py`)."""
    if value.tzinfo is None or value.tzinfo.utcoffset(value) is None:
        raise ValueError("datetime debe ser tz-aware")


@dataclass(frozen=True, slots=True)
class ReviewItem:
    """Un mensaje crudo en la cola de revision del usuario (spec 004 SS2.10).

    `is_open` es la unica fuente de verdad sobre si el item sigue pendiente: el
    invariante `(resolved_at IS NULL) = (resolution IS NULL)` vive en la tabla
    (`resolucion_consistente`) y aqui se refleja en el tipado (`None`/`None`
    juntos, o ambos con valor).
    """

    raw_message_id: UUID
    user_id: UUID
    reason: ReviewReason
    partial_extract: Mapping[str, str]
    created_at: datetime
    resolved_at: datetime | None
    resolution: ReviewResolution | None

    def __post_init__(self) -> None:
        _require_aware(self.created_at)
        if self.resolved_at is not None:
            _require_aware(self.resolved_at)
        if (self.resolved_at is None) != (self.resolution is None):
            raise ValueError("resolved_at y resolution deben ir juntos (ambos o ninguno)")

    @property
    def is_open(self) -> bool:
        """`True` si el item aun no fue convertido ni descartado."""
        return self.resolved_at is None


__all__ = ["ReviewItem", "ReviewReason", "ReviewResolution"]
