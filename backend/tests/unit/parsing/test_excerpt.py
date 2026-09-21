"""Tests unitarios de extraccion de extracto (spec 006 §2.3/§4.1)."""

import pytest
from support.email_fixtures import bancolombia_fixtures

from finanzia.modules.parsing.domain.excerpt import extract_excerpt, looks_monetary

PREFIX = "Bancolombia:"


@pytest.mark.unit
class TestExtractExcerptBancolombia:
    @pytest.mark.parametrize(
        "fixture", bancolombia_fixtures(), ids=lambda f: f.name if hasattr(f, "name") else str(f)
    )
    def test_extracto_es_exactamente_la_linea_bancolombia(self, fixture) -> None:
        excerpt = extract_excerpt(fixture.body, PREFIX)
        lines = [line for line in fixture.body.splitlines() if line.startswith(PREFIX)]
        assert lines, f"fixture {fixture.name} deberia tener una linea 'Bancolombia:'"
        assert excerpt == "\n".join(lines)
        assert excerpt.count("\n") == 0


@pytest.mark.unit
class TestExtractExcerptFallback:
    def test_sin_prefijo_configurado_usa_fallback(self) -> None:
        body = "Hola\n\nCompraste $10.000 en TIENDA\n\nGracias por tu compra."
        excerpt = extract_excerpt(body, None)
        assert "Compraste $10.000 en TIENDA" in excerpt
        assert "Hola" in excerpt

    def test_prefijo_sin_match_usa_fallback(self) -> None:
        body = "Compraste $10.000 en TIENDA\nVisita www.banco.com"
        excerpt = extract_excerpt(body, "Nequi:")
        assert "Compraste $10.000 en TIENDA" in excerpt

    def test_fallback_descarta_urls(self) -> None:
        body = "Compraste $10.000 en TIENDA\nVisita https://banco.com/seguridad"
        excerpt = extract_excerpt(body, None)
        assert "https://banco.com" not in excerpt

    def test_fallback_descarta_www(self) -> None:
        body = "Compraste $10.000 en TIENDA\nEntra a www.bancolombia.com"
        excerpt = extract_excerpt(body, None)
        assert "www.bancolombia.com" not in excerpt

    def test_fallback_descarta_telefonos(self) -> None:
        body = "Compraste $10.000 en TIENDA\nLlamanos al 6045109095 o al 018 000 931 987"
        excerpt = extract_excerpt(body, None)
        assert "6045109095" not in excerpt

    def test_fallback_descarta_lineas_vacias(self) -> None:
        body = "Compraste $10.000 en TIENDA\n\n\nGracias"
        excerpt = extract_excerpt(body, None)
        assert excerpt == "Compraste $10.000 en TIENDA\nGracias"

    def test_fallback_trunca_a_max_chars(self) -> None:
        body = "Compraste $10.000 en " + ("A" * 2000)
        excerpt = extract_excerpt(body, None, max_chars=50)
        assert len(excerpt) == 50


@pytest.mark.unit
class TestLooksMonetary:
    @pytest.mark.parametrize(
        "text",
        [
            "Compraste $10.000 en TIENDA",
            "COP 45.900",
            "el monto es 1.234.567 pesos",
        ],
    )
    def test_positivos(self, text: str) -> None:
        assert looks_monetary(text) is True

    @pytest.mark.parametrize(
        "text",
        [
            "Hola, como estas",
            "Visita www.bancolombia.com",
            "Tu clave es 12345",
        ],
    )
    def test_negativos(self, text: str) -> None:
        assert looks_monetary(text) is False
