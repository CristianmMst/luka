"""Tests unitarios de `ParsedTransaction` (validacion de invariantes, spec 006 §4)."""

from datetime import UTC, datetime
from decimal import Decimal

import pytest

from luka.modules.parsing.domain.enums import Direction
from luka.modules.parsing.domain.parsed import ParsedTransaction

OCCURRED_AT = datetime(2026, 8, 5, 14, 30, 0, tzinfo=UTC)


def _make(**overrides: object) -> ParsedTransaction:
    fields: dict[str, object] = {
        "bank": "bancolombia",
        "amount": Decimal("45900.00"),
        "direction": Direction.DEBIT,
        "occurred_at": OCCURRED_AT,
        "merchant": "RAPPI",
        "last4": "1234",
        "suggested_category": None,
        "parsed_by": "rule:bancolombia:compra_tdeb:v1",
        "confidence": None,
    }
    fields.update(overrides)
    return ParsedTransaction(**fields)  # type: ignore[arg-type]


@pytest.mark.unit
class TestParsedTransaction:
    def test_construye_con_datos_validos(self) -> None:
        parsed = _make()
        assert parsed.bank == "bancolombia"
        assert parsed.amount == Decimal("45900.00")

    def test_occurred_at_naive_lanza_value_error(self) -> None:
        with pytest.raises(ValueError, match="tz-aware"):
            _make(occurred_at=datetime(2026, 8, 5, 14, 30, 0))

    def test_amount_cero_lanza_value_error(self) -> None:
        with pytest.raises(ValueError, match="amount"):
            _make(amount=Decimal("0"))

    def test_amount_negativo_lanza_value_error(self) -> None:
        with pytest.raises(ValueError, match="amount"):
            _make(amount=Decimal("-10.00"))

    def test_last4_invalido_lanza_value_error(self) -> None:
        with pytest.raises(ValueError, match="last4"):
            _make(last4="abcd")

    def test_last4_none_es_valido(self) -> None:
        assert _make(last4=None).last4 is None

    def test_confidence_fuera_de_rango_lanza_value_error(self) -> None:
        with pytest.raises(ValueError, match="confidence"):
            _make(confidence=1.5)

    def test_confidence_negativo_lanza_value_error(self) -> None:
        with pytest.raises(ValueError, match="confidence"):
            _make(confidence=-0.1)

    def test_confidence_none_es_valido(self) -> None:
        assert _make(confidence=None).confidence is None

    def test_confidence_en_rango_es_valido(self) -> None:
        assert _make(confidence=0.8).confidence == 0.8
