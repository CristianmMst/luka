"""Tests unitarios de normalizacion de comercios y resolucion de reglas (spec 006 SS4.3)."""

from uuid import uuid4

import pytest

from luka.modules.ledger.domain.entities import MerchantRule
from luka.modules.ledger.domain.merchant import match_rule, normalize_merchant


def _rule(pattern: str) -> MerchantRule:
    return MerchantRule(id=uuid4(), user_id=uuid4(), merchant_pattern=pattern, category_id=uuid4())


@pytest.mark.unit
class TestNormalizeMerchant:
    def test_rappi_corta_en_el_asterisco(self) -> None:
        assert normalize_merchant("RAPPI*RAPPI PRO 4432") == "RAPPI"

    def test_colapsa_espacios_y_mayusculas_con_tildes(self) -> None:
        assert normalize_merchant("  Éxito  Calle 80 ") == "ÉXITO CALLE 80"

    def test_quita_codigo_numerico_final(self) -> None:
        assert normalize_merchant("UBER TRIP 123456") == "UBER TRIP"

    def test_payu_netflix_corta_en_el_asterisco(self) -> None:
        assert normalize_merchant("PAYU*NETFLIX") == "PAYU"

    def test_none_devuelve_cadena_vacia(self) -> None:
        assert normalize_merchant(None) == ""

    def test_blanco_devuelve_cadena_vacia(self) -> None:
        assert normalize_merchant("   ") == ""

    def test_no_quita_numeros_cortos_que_no_son_codigo(self) -> None:
        assert normalize_merchant("TIENDA 80") == "TIENDA 80"

    def test_repite_mientras_el_ultimo_token_sea_codigo(self) -> None:
        assert normalize_merchant("COMERCIO ABC123 999999") == "COMERCIO"


@pytest.mark.unit
class TestMatchRule:
    def test_regla_exacta_gana_sobre_prefijo(self) -> None:
        exact = _rule("RAPPI")
        prefix = _rule("RAP")
        assert match_rule("RAPPI", [prefix, exact]) is exact

    def test_prefijo_mas_largo_gana(self) -> None:
        short = _rule("UBER")
        long = _rule("UBER TRIP")
        assert match_rule("UBER TRIP MEDELLIN", [short, long]) is long

    def test_sin_match_devuelve_none(self) -> None:
        assert match_rule("NETFLIX", [_rule("RAPPI"), _rule("UBER")]) is None

    def test_lista_vacia_devuelve_none(self) -> None:
        assert match_rule("RAPPI", []) is None
