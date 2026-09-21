"""DTOs de entrada/salida del caso de uso de parsing (frozen, stdlib puro).

`RawMessageView` duplica adrede la forma de `ingestion.application.dto.RawMessageView`
(mismos nombres de campo): parsing no puede importar `ingestion` (R4), asi que define
su propia proyeccion de lectura; el adapter de infrastructure (Task 7) mapea entre
ambas contra `ingestion.public`.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

from finanzia.modules.parsing.domain.enums import ParseFailureReason
from finanzia.modules.parsing.domain.llm_validation import LlmExtraction

# --- Lectura del raw_message (D2) ---------------------------------------------------


@dataclass(frozen=True, slots=True)
class RawMessageView:
    """Proyeccion de solo lectura de un `raw_message`, expuesta via un gateway port.

    `channel`/`status` son `str` (no enums de ingestion, R4): el gateway adapter
    (Task 7) los mapea desde `ingestion.public.RawMessageView`.
    """

    id: UUID
    user_id: UUID
    channel: str
    bank: str | None
    sender: str
    body: str | None
    status: str
    received_at: datetime


# --- Resultado del LLM (spec 006 SS4.2) ---------------------------------------------


@dataclass(frozen=True, slots=True)
class LlmOutput:
    """El LLM devolvio un JSON valido/deserializable (aun por validar semanticamente)."""

    extraction: LlmExtraction
    tokens: int


@dataclass(frozen=True, slots=True)
class LlmInvalidOutput:
    """El LLM devolvio algo que no se pudo deserializar contra el esquema esperado."""

    tokens: int


LlmResult = LlmOutput | LlmInvalidOutput


# --- Resultado de `ParseRawMessage` --------------------------------------------------


@dataclass(frozen=True, slots=True)
class Skipped:
    """Reentrega o estado inconsistente: no se toca nada (idempotencia, D8/D9)."""

    reason: str


@dataclass(frozen=True, slots=True)
class Parsed:
    """Se extrajo una transaccion candidata y se publico `TransactionParsed`."""

    parsed_by: str
    transaction_event_id: UUID


@dataclass(frozen=True, slots=True)
class Failed:
    """No se pudo extraer una transaccion: se publico `ParseFailed(reason)`."""

    reason: ParseFailureReason


@dataclass(frozen=True, slots=True)
class Discarded:
    """El LLM determino que el mensaje no es una transaccion (D12): sin evento."""


ParseOutcome = Skipped | Parsed | Failed | Discarded


__all__ = [
    "Discarded",
    "Failed",
    "LlmInvalidOutput",
    "LlmOutput",
    "LlmResult",
    "ParseOutcome",
    "Parsed",
    "RawMessageView",
    "Skipped",
]
