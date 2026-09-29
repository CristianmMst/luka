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

    def test_mes_en_espanol_y_hora_am_pm(self) -> None:
        # Nequi: "el 26 de septiembre de 2026 a las 11:21 a.m".
        result = parse_local_datetime("26 de septiembre de 2026", "11:21 a.m", "%d de %m de %Y")
        assert result.isoformat() == "2026-09-26T11:21:00-05:00"

    @pytest.mark.parametrize(
        ("time", "expected"),
        [
            ("11:21 p.m", "23:21"),
            ("1:05 p. m.", "13:05"),
            ("12:05 a.m", "00:05"),
            ("12:30 p.m", "12:30"),
            ("9:00 AM", "09:00"),
            ("16:28", "16:28"),
        ],
    )
    def test_hora_de_12_horas_pasa_a_24(self, time: str, expected: str) -> None:
        result = parse_local_datetime("01/05/2026", time, "%d/%m/%Y")
        assert result.strftime("%H:%M") == expected

    @pytest.mark.parametrize("month", ["SEPTIEMBRE", "Setiembre", "septiembre"])
    def test_mes_en_espanol_sin_importar_mayusculas(self, month: str) -> None:
        result = parse_local_datetime(f"3 de {month} de 2026", "08:00", "%d de %m de %Y")
        assert (result.month, result.day) == (9, 3)

    @pytest.mark.parametrize("time", ["13:00 p.m", "0:30 a.m", "11:75 a.m"])
    def test_hora_am_pm_invalida_lanza_date_invalid(self, time: str) -> None:
        with pytest.raises(DateInvalid):
            parse_local_datetime("01/05/2026", time, "%d/%m/%Y")


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
