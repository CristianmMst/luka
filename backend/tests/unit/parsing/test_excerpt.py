"""Tests unitarios de extraccion de extracto (spec 006 §2.3/§4.1)."""

import re

import pytest
from support.email_fixtures import bancolombia_fixtures

from luka.modules.parsing.domain.excerpt import extract_excerpt, looks_monetary

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

    def test_body_con_crlf_se_desenvuelve_igual(self) -> None:
        """`splitlines()` ya trata `\\r\\n` como un solo salto de linea; el
        parrafo se desenvuelve igual que con `\\n` (correo real de Outlook/
        Exchange, spec 006 §4.1).
        """
        body = (
            "Hola Bancolombia: Compraste $10.000 en\r\n"
            "TIENDA el 01/05/2026 a las\r\n"
            "16:00\r\n"
            "\r\n"
            "Otro parrafo.\r\n"
        )
        excerpt = extract_excerpt(body, PREFIX)
        assert excerpt == "Bancolombia: Compraste $10.000 en TIENDA el 01/05/2026 a las 16:00"

    def test_rama_de_prefijo_tambien_trunca_a_max_chars(self) -> None:
        body = f"Bancolombia: Compraste $10.000 en {'A' * 2000} el 01/05/2026 a las 16:00"
        excerpt = extract_excerpt(body, PREFIX, max_chars=50)
        assert len(excerpt) == 50
        assert excerpt == body[:50]


@pytest.mark.unit
class TestExtractExcerptRecortaBoilerplateTrasLaHora:
    """Regla de oro (revision Task 1, ronda 1): lo que sigue a la hora
    `HH:MM` de la transaccion se recorta en la primera URL/`[` y se le quitan
    secuencias tipo telefono (RNF-5, minimalidad del extracto para el LLM).
    El texto ANTES de la hora (monto, llave/last4, comerciante) no se toca,
    porque ahi puede vivir una llave Bre-B puramente numerica indistinguible
    de un telefono.
    """

    @pytest.mark.parametrize(
        "fixture",
        [f for f in bancolombia_fixtures() if f.name.endswith("_wrap.txt")],
        ids=lambda f: f.name,
    )
    def test_fixtures_reales_cortados_excluyen_boilerplate_y_conservan_fecha_hora(
        self, fixture
    ) -> None:
        excerpt = extract_excerpt(fixture.body, PREFIX)
        assert "http://" not in excerpt
        assert "https://" not in excerpt
        assert "lamp.png" not in excerpt
        assert "018000912345" not in excerpt
        assert "seguridad" not in excerpt
        assert "Para que enviar" not in excerpt
        expected = fixture.expected
        occurred_at = expected["occurred_at"]
        assert occurred_at.strftime("%d/%m/%y") in excerpt
        assert occurred_at.strftime("%H:%M") in excerpt

    @pytest.mark.parametrize(
        "fixture", bancolombia_fixtures(), ids=lambda f: f.name if hasattr(f, "name") else str(f)
    )
    def test_quitar_telefonos_no_deja_digitos_sueltos(self, fixture) -> None:
        """`_PHONE_RE` consume el telefono entero: `018000912345` no puede dejar
        `45` ni `018000931987` dejar `87` (revision F4.7).
        """
        excerpt = extract_excerpt(fixture.body, PREFIX)
        tail = excerpt[re.search(r"\d{2}:\d{2}", excerpt).end() :]  # type: ignore[union-attr]
        # `Icon 1` (etiqueta de imagen de los `_wrap`) es el unico digito legitimo.
        assert not re.search(r"\d{2,}", tail), tail

    @pytest.mark.parametrize(
        ("name", "expected"),
        [
            (
                "transferencia_llave_wrap.txt",
                "Bancolombia: DIANA, transferiste $215,300.00 a la llave 3007654321 desde tu "
                "cuenta *5533 a CARLOS RUIZ el 15/06/26 a las 11:24. Con Bre-b es de una y "
                "gratis. Dudas al . Icon 1 ",
            ),
            (
                "transferencia_llave_recibida_wrap.txt",
                "Bancolombia: DIANA, recibiste una transferencia de CARLOS RUIZ por $482,500.00 "
                "en tu cuenta *9081 conectada a la llave @druiz882 el 15/06/26 a las 11:24. Con "
                "llaves es de una y gratis. Dudas al . Icon 1 ",
            ),
        ],
    )
    def test_extracto_exacto_de_los_fixtures_cortados(self, name: str, expected: str) -> None:
        fixture = next(f for f in bancolombia_fixtures() if f.name == name)
        assert extract_excerpt(fixture.body, PREFIX) == expected

    @pytest.mark.parametrize(
        "phone",
        ["604 510 9095", "018 000 931 987", "018000912345", "+573001234567", "57 300 123 4567"],
    )
    def test_telefonos_espaciados_y_gratuitos_tras_la_hora_se_quitan(self, phone: str) -> None:
        head = "Bancolombia: Compraste $10.000 en TIENDA el 01/05/2026 a las 16:00. Dudas al "
        assert extract_excerpt(f"{head}{phone}.", PREFIX) == f"{head}."

    def test_url_tras_la_hora_se_recorta(self) -> None:
        body = (
            "Bancolombia: Compraste $10.000 en TIENDA el 01/05/2026 a las 16:00. "
            "Visita https://banco.com/seguridad para mas info."
        )
        excerpt = extract_excerpt(body, PREFIX)
        assert "https://banco.com" not in excerpt
        assert "01/05/2026" in excerpt
        assert "16:00" in excerpt

    def test_imagen_entre_corchetes_tras_la_hora_se_recorta(self) -> None:
        body = (
            "Bancolombia: Compraste $10.000 en TIENDA el 01/05/2026 a las 16:00. "
            "Icon 1 [https://banco.com/img/lamp.png] Para que enviar plata sea un exito."
        )
        excerpt = extract_excerpt(body, PREFIX)
        assert "[" not in excerpt
        assert "lamp.png" not in excerpt
        assert "Para que enviar" not in excerpt
        assert "16:00" in excerpt

    def test_telefono_tras_la_hora_se_quita(self) -> None:
        body = (
            "Bancolombia: Compraste $10.000 en TIENDA el 01/05/2026 a las 16:00. "
            "Dudas al 018000912345."
        )
        excerpt = extract_excerpt(body, PREFIX)
        assert "018000912345" not in excerpt
        assert "16:00" in excerpt

    def test_llave_numerica_antes_de_la_hora_no_se_toca(self) -> None:
        """La llave Bre-B (puramente numerica, formato de telefono) vive
        ANTES de la hora y debe sobrevivir intacta para que la plantilla
        `transferencia_llave` la siga capturando.
        """
        body = (
            "Bancolombia: ANA, transferiste $1,820,000.00 a la llave 3001234567 "
            "desde tu cuenta *4455 a MARIA PEREZ el 01/05/26 a las 16:28. "
            "Con Bre-b es de una y gratis. Dudas al 018000912345."
        )
        excerpt = extract_excerpt(body, PREFIX)
        assert "3001234567" in excerpt
        assert "018000912345" not in excerpt


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

    @pytest.mark.parametrize("phone", ["+573001234567", "57 300 123 4567"])
    def test_fallback_descarta_telefonos_con_prefijo_57(self, phone: str) -> None:
        body = f"Compraste $10.000 en TIENDA\nLlamanos al {phone}"
        assert extract_excerpt(body, None) == "Compraste $10.000 en TIENDA"

    def test_fallback_descarta_referencias_largas(self) -> None:
        body = "Compraste $10.000 en TIENDA\nReferencia 123456789012"
        assert extract_excerpt(body, None) == "Compraste $10.000 en TIENDA"

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
