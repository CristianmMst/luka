"""Tests unitarios de validacion post-LLM (spec 006 §4.2, D12)."""

from datetime import UTC, datetime, timedelta
from decimal import Decimal

import pytest
from support.email_fixtures import FIXTURES_DIR, load_email_fixtures

from finanzia.modules.parsing.domain.enums import Direction, ParseFailureReason
from finanzia.modules.parsing.domain.llm_validation import (
    LlmExtraction,
    Rejected,
    validate_extraction,
)
from finanzia.modules.parsing.domain.parsed import ParsedTransaction

RECEIVED_AT = datetime(2026, 8, 5, 14, 30, 0, tzinfo=UTC)
KNOWN_BANKS = frozenset({"bancolombia", "nequi", "davivienda", "daviplata", "bbva", "banco_bogota"})
THRESHOLD = 0.8


def _valid_extraction(**overrides: object) -> LlmExtraction:
    fields: dict[str, object] = {
        "is_transaction": True,
        "amount": Decimal("45900.00"),
        "currency": "COP",
        "direction": Direction.DEBIT,
        "merchant": "RAPPI",
        "occurred_at": datetime(2026, 8, 5, 14, 30, 0, tzinfo=UTC),
        "bank": "bancolombia",
        "last4": "1234",
        "suggested_category": "restaurantes",
        "confidence": 0.93,
    }
    fields.update(overrides)
    return LlmExtraction(**fields)  # type: ignore[arg-type]


@pytest.mark.unit
class TestValidateExtraction:
    def test_transaccion_valida_produce_parsed_transaction(self) -> None:
        result = validate_extraction(_valid_extraction(), RECEIVED_AT, KNOWN_BANKS, THRESHOLD)
        assert isinstance(result, ParsedTransaction)
        assert result.parsed_by == "llm"
        assert result.confidence == 0.93
        assert result.bank == "bancolombia"
        assert result.amount == Decimal("45900.00")

    def test_is_transaction_false_rechaza_como_not_transaction(self) -> None:
        result = validate_extraction(
            _valid_extraction(is_transaction=False), RECEIVED_AT, KNOWN_BANKS, THRESHOLD
        )
        assert isinstance(result, Rejected)
        assert result.reason == "not_transaction"

    def test_amount_none_rechaza_llm_invalid_output(self) -> None:
        result = validate_extraction(
            _valid_extraction(amount=None), RECEIVED_AT, KNOWN_BANKS, THRESHOLD
        )
        assert isinstance(result, Rejected)
        assert result.reason == ParseFailureReason.LLM_INVALID_OUTPUT

    def test_amount_cero_rechaza_llm_invalid_output(self) -> None:
        result = validate_extraction(
            _valid_extraction(amount=Decimal("0")), RECEIVED_AT, KNOWN_BANKS, THRESHOLD
        )
        assert isinstance(result, Rejected)
        assert result.reason == ParseFailureReason.LLM_INVALID_OUTPUT

    def test_occurred_at_none_rechaza_llm_invalid_output(self) -> None:
        result = validate_extraction(
            _valid_extraction(occurred_at=None), RECEIVED_AT, KNOWN_BANKS, THRESHOLD
        )
        assert isinstance(result, Rejected)
        assert result.reason == ParseFailureReason.LLM_INVALID_OUTPUT

    def test_occurred_at_naive_rechaza_llm_invalid_output(self) -> None:
        result = validate_extraction(
            _valid_extraction(occurred_at=datetime(2026, 8, 5, 14, 30, 0)),
            RECEIVED_AT,
            KNOWN_BANKS,
            THRESHOLD,
        )
        assert isinstance(result, Rejected)
        assert result.reason == ParseFailureReason.LLM_INVALID_OUTPUT

    def test_occurred_at_fuera_de_ventana_rechaza_llm_invalid_output(self) -> None:
        result = validate_extraction(
            _valid_extraction(occurred_at=RECEIVED_AT + timedelta(days=30)),
            RECEIVED_AT,
            KNOWN_BANKS,
            THRESHOLD,
        )
        assert isinstance(result, Rejected)
        assert result.reason == ParseFailureReason.LLM_INVALID_OUTPUT

    def test_bank_none_rechaza_llm_invalid_output(self) -> None:
        result = validate_extraction(
            _valid_extraction(bank=None), RECEIVED_AT, KNOWN_BANKS, THRESHOLD
        )
        assert isinstance(result, Rejected)
        assert result.reason == ParseFailureReason.LLM_INVALID_OUTPUT

    def test_bank_desconocido_rechaza_llm_invalid_output(self) -> None:
        result = validate_extraction(
            _valid_extraction(bank="banco_fantasma"), RECEIVED_AT, KNOWN_BANKS, THRESHOLD
        )
        assert isinstance(result, Rejected)
        assert result.reason == ParseFailureReason.LLM_INVALID_OUTPUT

    def test_direction_none_rechaza_llm_invalid_output(self) -> None:
        result = validate_extraction(
            _valid_extraction(direction=None), RECEIVED_AT, KNOWN_BANKS, THRESHOLD
        )
        assert isinstance(result, Rejected)
        assert result.reason == ParseFailureReason.LLM_INVALID_OUTPUT

    def test_confianza_baja_rechaza_llm_low_confidence(self) -> None:
        result = validate_extraction(
            _valid_extraction(confidence=0.5), RECEIVED_AT, KNOWN_BANKS, THRESHOLD
        )
        assert isinstance(result, Rejected)
        assert result.reason == ParseFailureReason.LLM_LOW_CONFIDENCE

    def test_partial_extract_excluye_none_y_is_transaction(self) -> None:
        result = validate_extraction(
            _valid_extraction(is_transaction=False, merchant=None),
            RECEIVED_AT,
            KNOWN_BANKS,
            THRESHOLD,
        )
        assert isinstance(result, Rejected)
        assert "is_transaction" not in result.partial
        assert "merchant" not in result.partial
        assert result.partial["bank"] == "bancolombia"
        assert result.partial["direction"] == "debit"


@pytest.mark.unit
class TestValidateExtractionNuFixture:
    """El cuerpo de `other/nu_pago.txt` (descartado por remitente, D5) se
    reutiliza como input de una extraccion LLM fake: verifica que el 4xmil
    no contamine el monto y que `bank="other"` (fuera del MVP) sea aceptado.
    """

    def test_extraccion_fake_del_cuerpo_nu_produce_parsed_transaction(self) -> None:
        fixtures = load_email_fixtures(FIXTURES_DIR / "other")
        nu_fixture = next(f for f in fixtures if f.name == "nu_pago.txt")
        assert "16.285.200" in nu_fixture.body
        assert "65.140" in nu_fixture.body  # el 4xmil no debe colarse como monto

        fake_extraction = LlmExtraction(
            is_transaction=True,
            amount=Decimal("16285200.00"),
            currency="COP",
            direction=Direction.DEBIT,
            merchant="CORREDORES DAVIVIENDA S A COMISIONISTA DE BOLSA",
            occurred_at=nu_fixture.received_at,
            bank="other",
            last4=None,
            suggested_category=None,
            confidence=0.9,
        )
        result = validate_extraction(
            fake_extraction, nu_fixture.received_at, KNOWN_BANKS, THRESHOLD
        )
        assert isinstance(result, ParsedTransaction)
        assert result.bank == "other"
        assert result.amount == Decimal("16285200.00")
        assert result.parsed_by == "llm"
