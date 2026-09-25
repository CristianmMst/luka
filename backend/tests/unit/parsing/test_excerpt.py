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
    def test_extracto_empieza_en_el_prefijo_y_es_una_sola_linea(self, fixture) -> None:
        """Invariante para todos los fixtures reales: con o sin wrap, el
        extracto arranca exactamente en `PREFIX` y queda desenvuelto (sin
        saltos de linea), tanto si el prefijo empezaba una linea fisica como
        si estaba a mitad de linea (correo cortado, spec 006 §4.1).
        """
        excerpt = extract_excerpt(fixture.body, PREFIX)
        assert excerpt.startswith(PREFIX)
        assert excerpt.count("\n") == 0


@pytest.mark.unit
class TestExtractExcerptParrafoDesenvuelto:
    """`relevant_line_prefix` a mitad de parrafo o de linea (correo cortado a
    ~76 caracteres): se busca en el parrafo ya desenvuelto, no en la linea
    fisica (spec 006 §4.1).
    """

    def test_prefijo_al_inicio_de_linea_sigue_funcionando(self) -> None:
        body = "Bancolombia: Compraste $10.000 en TIENDA el 01/05/2026 a las 16:00\n\nOtro parrafo."
        excerpt = extract_excerpt(body, PREFIX)
        assert excerpt == "Bancolombia: Compraste $10.000 en TIENDA el 01/05/2026 a las 16:00"

    def test_prefijo_a_mitad_de_linea_se_extrae_desde_ahi(self) -> None:
        body = (
            "Hola Bancolombia: Compraste $10.000 en TIENDA el 01/05/2026 a las 16:00\n"
            "\n"
            "Otro parrafo sin el prefijo."
        )
        excerpt = extract_excerpt(body, PREFIX)
        assert excerpt == "Bancolombia: Compraste $10.000 en TIENDA el 01/05/2026 a las 16:00"

    def test_frase_cortada_en_varias_lineas_se_desenvuelve(self) -> None:
        body = (
            "Hola Bancolombia: Compraste $10.000 en\n"
            "TIENDA el 01/05/2026 a las\n"
            "16:00\n"
            "\n"
            "Otro parrafo."
        )
        excerpt = extract_excerpt(body, PREFIX)
        assert excerpt == "Bancolombia: Compraste $10.000 en TIENDA el 01/05/2026 a las 16:00"

    def test_solo_llega_hasta_el_final_del_parrafo_que_matchea(self) -> None:
        body = (
            "Parrafo irrelevante.\n"
            "\n"
            "Bancolombia: Compraste $10.000 en TIENDA el 01/05/2026 a las 16:00\n"
            "\n"
            "Parrafo de seguridad que no debe quedar en el extracto."
        )
        excerpt = extract_excerpt(body, PREFIX)
        assert excerpt == "Bancolombia: Compraste $10.000 en TIENDA el 01/05/2026 a las 16:00"
        assert "seguridad" not in excerpt

    def test_ningun_parrafo_con_prefijo_usa_fallback(self) -> None:
        body = "Parrafo 1 sin el prefijo.\n\nCompraste $10.000 en TIENDA."
        excerpt = extract_excerpt(body, PREFIX)
        assert "Compraste $10.000 en TIENDA" in excerpt


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
        assert "018 000 931 987" not in excerpt

    def test_fallback_descarta_telefono_punteado(self) -> None:
        body = "Compraste $10.000 en TIENDA\nLlamanos al 604.510.9095"
        excerpt = extract_excerpt(body, None)
        assert "604.510.9095" not in excerpt
        assert "Compraste $10.000 en TIENDA" in excerpt

    def test_fallback_descarta_telefono_gratuito_espaciado(self) -> None:
        body = "Compraste $10.000 en TIENDA\nComunicate gratis al 018 000 931 987"
        excerpt = extract_excerpt(body, None)
        assert "018 000 931 987" not in excerpt
        assert "Compraste $10.000 en TIENDA" in excerpt

    def test_fallback_conserva_fechas_y_montos_junto_a_telefonos(self) -> None:
        body = (
            "Compraste $53.900,00 en OXXO CALLE 59 con tu T.Deb *1234, "
            "el 01/05/2026 a las 16:00\n"
            "Llamanos al 604.510.9095 o al 018 000 931 987\n"
            "Otra transferencia el 01/05/26 a las 16:28"
        )
        excerpt = extract_excerpt(body, None)
        assert "$53.900,00" in excerpt
        assert "01/05/2026" in excerpt
        assert "01/05/26" in excerpt
        assert "604.510.9095" not in excerpt
        assert "018 000 931 987" not in excerpt

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
            "Compraste $53.900,00",
            "pago de 1.234.567 pesos",
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
            "Llamanos al 604.510.9095",
        ],
    )
    def test_negativos(self, text: str) -> None:
        assert looks_monetary(text) is False
