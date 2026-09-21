"""Tests unitarios de `LlmResponseSchema` (unico lugar con pydantic, R2)."""

from datetime import datetime, timedelta, timezone
from decimal import Decimal

import pytest
from pydantic import ValidationError

from finanzia.modules.parsing.domain.enums import Direction
from finanzia.modules.parsing.domain.llm_validation import LlmExtraction
from finanzia.modules.parsing.infrastructure.llm.schema import LlmResponseSchema


@pytest.mark.unit
class TestLlmResponseSchema:
    def test_respuesta_valida_produce_extraction_con_decimal_y_direction(self) -> None:
        schema = LlmResponseSchema.model_validate(
            {
                "is_transaction": True,
                "amount": "176824.00",
                "currency": "COP",
                "direction": "debit",
                "merchant": "CARBON Y XILVESTRE T",
                "occurred_at": "2026-05-01T16:00:00-05:00",
                "bank": "bancolombia",
                "last4": "1234",
                "suggested_category": None,
                "confidence": 0.95,
            }
        )

        extraction = schema.to_extraction()

        assert isinstance(extraction, LlmExtraction)
        assert extraction.is_transaction is True
        assert extraction.amount == Decimal("176824.00")
        assert extraction.currency == "COP"
        assert extraction.direction == Direction.DEBIT
        assert extraction.merchant == "CARBON Y XILVESTRE T"
        assert extraction.occurred_at == datetime(
            2026, 5, 1, 16, 0, 0, tzinfo=timezone(timedelta(hours=-5))
        )
        assert extraction.bank == "bancolombia"
        assert extraction.last4 == "1234"
        assert extraction.suggested_category is None
        assert extraction.confidence == 0.95

    def test_todos_los_campos_nulos_son_validos(self) -> None:
        schema = LlmResponseSchema.model_validate({"is_transaction": False, "confidence": 0.0})

        extraction = schema.to_extraction()

        assert extraction.is_transaction is False
        assert extraction.amount is None
        assert extraction.direction is None
        assert extraction.occurred_at is None
        assert extraction.bank is None
        assert extraction.last4 is None

    def test_campos_extra_se_ignoran(self) -> None:
        schema = LlmResponseSchema.model_validate(
            {
                "is_transaction": True,
                "confidence": 0.5,
                "raw_message_id": "no-deberia-viajar-aqui",
                "user_id": "tampoco-esto",
            }
        )

        assert not hasattr(schema, "raw_message_id")
        assert not hasattr(schema, "user_id")

    def test_confidence_fuera_de_rango_es_invalido(self) -> None:
        with pytest.raises(ValidationError):
            LlmResponseSchema.model_validate({"is_transaction": True, "confidence": 1.2})

    def test_confidence_negativa_es_invalida(self) -> None:
        with pytest.raises(ValidationError):
            LlmResponseSchema.model_validate({"is_transaction": True, "confidence": -0.1})

    def test_amount_no_numerico_es_invalido(self) -> None:
        with pytest.raises(ValidationError):
            LlmResponseSchema.model_validate(
                {"is_transaction": True, "amount": "abc", "confidence": 0.5}
            )

    def test_last4_con_letras_es_invalido(self) -> None:
        with pytest.raises(ValidationError):
            LlmResponseSchema.model_validate(
                {"is_transaction": True, "last4": "12ab", "confidence": 0.5}
            )

    def test_direction_invalida_es_invalida(self) -> None:
        with pytest.raises(ValidationError):
            LlmResponseSchema.model_validate(
                {"is_transaction": True, "direction": "lateral", "confidence": 0.5}
            )
