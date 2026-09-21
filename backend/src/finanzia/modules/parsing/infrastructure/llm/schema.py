"""Esquema de la respuesta JSON del LLM (spec 006 §4.2). Pydantic solo vive
aqui (R2 prohibe pydantic en `application`); el adapter DeepSeek valida
contra este esquema y `to_extraction()` produce el `LlmExtraction` de dominio
que sí consume `application`.
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, ValidationError

from finanzia.modules.parsing.domain.enums import Direction
from finanzia.modules.parsing.domain.llm_validation import LlmExtraction

_AMOUNT_PATTERN = r"^\d{1,12}(\.\d{1,2})?$"
_LAST4_PATTERN = r"^\d{1,4}$"


class LlmSchemaInvalid(ValueError):  # noqa: N818 - nombre descriptivo, no de excepcion generica
    """El JSON del LLM no matchea `LlmResponseSchema` (envuelve `ValidationError`).

    El resto de `infrastructure` (p. ej. `llm/deepseek.py`) nunca importa
    `pydantic` directamente: solo este modulo lo hace (controller ruling §1).
    """


class LlmResponseSchema(BaseModel):
    """Forma esperada del JSON que devuelve DeepSeek (`response_format=json_object`).

    `extra="ignore"`: cualquier campo extra que el LLM invente (p. ej. si por
    error ecoa `user_id`/`raw_message_id` del prompt, cosa que nunca deberia
    pasar porque no se le pasan) se descarta silenciosamente en vez de fallar
    la validacion.
    """

    model_config = ConfigDict(extra="ignore")

    is_transaction: bool
    amount: str | None = Field(default=None, pattern=_AMOUNT_PATTERN)
    currency: str | None = None
    direction: Literal["debit", "credit"] | None = None
    merchant: str | None = None
    occurred_at: datetime | None = None
    bank: str | None = None
    last4: str | None = Field(default=None, pattern=_LAST4_PATTERN)
    suggested_category: str | None = None
    confidence: float = Field(ge=0, le=1)

    def to_extraction(self) -> LlmExtraction:
        """Mapea a `LlmExtraction` (dominio): `Decimal` para el monto, `Direction`
        (o `None`) para el sentido.
        """
        return LlmExtraction(
            is_transaction=self.is_transaction,
            amount=Decimal(self.amount) if self.amount is not None else None,
            currency=self.currency,
            direction=Direction(self.direction) if self.direction is not None else None,
            merchant=self.merchant,
            occurred_at=self.occurred_at,
            bank=self.bank,
            last4=self.last4,
            suggested_category=self.suggested_category,
            confidence=self.confidence,
        )


def parse_llm_response(data: object) -> LlmResponseSchema:
    """`LlmResponseSchema.model_validate(data)`, envolviendo `ValidationError` en
    `LlmSchemaInvalid` (para que los llamadores no necesiten importar pydantic).
    """
    try:
        return LlmResponseSchema.model_validate(data)
    except ValidationError as exc:
        raise LlmSchemaInvalid(str(exc)) from exc


__all__ = ["LlmResponseSchema", "LlmSchemaInvalid", "parse_llm_response"]
