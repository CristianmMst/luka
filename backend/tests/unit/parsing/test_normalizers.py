"""Tests unitarios de normalizadores de parsing (spec 006 §4.1/§4.3)."""

from datetime import timedelta
from decimal import Decimal

import pytest

from finanzia.modules.parsing.domain.errors import AmountInvalid, DateInvalid
from finanzia.modules.parsing.domain.normalizers import (
    clean_text,
    parse_amount,
    parse_local_datetime,
)

AMOUNT_CASES = [
    ("$176.824,00", "176824.00"),
    ("$2,910,744.00", "2910744.00"),
    ("$45.900", "45900.00"),
    ("$45,90", "45.90"),
    ("$1.234", "1234.00"),
    ("$12", "12.00"),
    ("COP 1.000,50", "1000.50"),
]

AMOUNT_INVALID_CASES = ["", "abc", "$0"]


@pytest.mark.unit
class TestParseAmount:
    @pytest.mark.parametrize(("raw", "expected"), AMOUNT_CASES)
    def test_normaliza_montos_validos(self, raw: str, expected: str) -> None:
        assert parse_amount(raw) == Decimal(expected)

    @pytest.mark.parametrize("raw", AMOUNT_INVALID_CASES)
    def test_rechaza_montos_invalidos(self, raw: str) -> None:
        with pytest.raises(AmountInvalid):
            parse_amount(raw)

    def test_resultado_siempre_cuantizado_a_2_decimales(self) -> None:
        result = parse_amount("$12")
        assert result.as_tuple().exponent == -2


@pytest.mark.unit
class TestParseLocalDatetime:
    def test_formato_d_m_y_produce_offset_bogota(self) -> None:
        result = parse_local_datetime("01/05/2026", "16:00", "%d/%m/%Y")
        assert result.isoformat() == "2026-05-01T16:00:00-05:00"

    def test_formato_d_m_y_corto_produce_offset_bogota(self) -> None:
        result = parse_local_datetime("01/05/26", "16:28", "%d/%m/%y")
        assert result.isoformat() == "2026-05-01T16:28:00-05:00"

    def test_aware(self) -> None:
        result = parse_local_datetime("01/05/2026", "16:00", "%d/%m/%Y")
        assert result.tzinfo is not None
        assert result.utcoffset() == timedelta(hours=-5)

    def test_fecha_invalida_lanza_date_invalid(self) -> None:
        with pytest.raises(DateInvalid):
            parse_local_datetime("31/02/2026", "16:00", "%d/%m/%Y")

    def test_formato_no_coincide_lanza_date_invalid(self) -> None:
        with pytest.raises(DateInvalid):
            parse_local_datetime("2026-05-01", "16:00", "%d/%m/%Y")


@pytest.mark.unit
class TestCleanText:
    def test_colapsa_espacios(self) -> None:
        assert clean_text("CARBON   Y   XILVESTRE") == "CARBON Y XILVESTRE"

    def test_strip_bordes(self) -> None:
        assert clean_text("  MARIA PEREZ  ") == "MARIA PEREZ"

    def test_quita_puntuacion_final(self) -> None:
        assert clean_text("OXXO CALLE 59.") == "OXXO CALLE 59"

    def test_no_altera_texto_limpio(self) -> None:
        assert clean_text("ACME SAS") == "ACME SAS"
