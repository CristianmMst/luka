"""Enums de dominio de parsing (spec 003 §2.3, spec 006). Solo stdlib (P3).

`RawMessageStatus` NO vive aqui: es de ingestion, que es quien la persiste y
transiciona (controller ruling, Task 2).
"""

from enum import StrEnum


class Direction(StrEnum):
    """Sentido del movimiento extraido por una plantilla o el LLM.

    Propio de parsing (D4): no importa `ledger.domain.enums.Direction` aunque
    comparta valores; `R4` prohibe que un modulo dependa de internals de otro.
    """

    DEBIT = "debit"
    CREDIT = "credit"


class Channel(StrEnum):
    """Canal de origen del mensaje crudo que parsing procesa (D4)."""

    EMAIL = "email"
    NOTIFICATION = "notification"
    SMS_NOTIFICATION = "sms_notification"


class ParseFailureReason(StrEnum):
    """Motivo cerrado de `ParseFailed` (controller ruling §5, D12): lista cerrada
    de 8 valores, sin comodin. Un motivo nuevo requiere ruling explicito.
    """

    NO_TEMPLATE = "no_template"
    LLM_DISABLED = "llm_disabled"
    LLM_BUDGET_EXCEEDED = "llm_budget_exceeded"
    LLM_INVALID_JSON = "llm_invalid_json"
    LLM_INVALID_OUTPUT = "llm_invalid_output"
    LLM_LOW_CONFIDENCE = "llm_low_confidence"
    LLM_ERROR = "llm_error"
    BODY_PURGED = "body_purged"


__all__ = ["Channel", "Direction", "ParseFailureReason"]
