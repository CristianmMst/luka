"""Tests unitarios de `ingestion.domain.gmail_message` (spec 006 §2.3)."""

from __future__ import annotations

import html
from datetime import UTC, datetime

import pytest
from support.email_fixtures import FIXTURES_DIR as EMAIL_FIXTURES_DIR
from support.email_fixtures import EmailFixture, bancolombia_fixtures, load_email_fixtures

from luka.modules.ingestion.domain.gmail_message import (
    GMAIL_BODY_MAX_BYTES,
    GmailMessage,
    MimePart,
    extract_body,
    html_to_text,
)

_ALL_FIXTURES = [*bancolombia_fixtures(), *load_email_fixtures(EMAIL_FIXTURES_DIR / "other")]


def _key_line(fixture: EmailFixture) -> str:
    """La primera linea no vacia que describe el movimiento (la que leen las plantillas)."""
    lines = [line.strip() for line in fixture.body.splitlines() if line.strip()]
    return next((line for line in lines if "$" in line), lines[0])


def _as_bank_html(fixture: EmailFixture) -> str:
    """Envuelve el cuerpo del fixture como lo hacen los bancos: tablas de layout,
    estilos, spans inline y entidades HTML.
    """
    rows = "".join(
        f"<tr><td style='padding:4px'><span>{html.escape(line)}</span></td></tr>"
        for line in fixture.body.splitlines()
        if line.strip()
    )
    return (
        "<html><head><title>Alertas</title><style>td{color:red}</style></head>"
        "<body><!-- tracking --><script>var x = 1;</script>"
        f"<table>{rows}</table></body></html>"
    )


def _text(
    data: str, *, mime_type: str = "text/plain", charset: str | None = None, filename: str = ""
) -> MimePart:
    return MimePart(
        mime_type=mime_type,
        data=data.encode(charset or "utf-8"),
        charset=charset,
        filename=filename,
    )


@pytest.mark.unit
class TestHtmlToText:
    def test_filas_de_tabla_quedan_como_lineas_y_celdas_separadas_por_espacio(self) -> None:
        source = (
            "<table><tr><td>Valor</td><td>$176.824,00</td></tr>"
            "<tr><th>Comercio</th><td>OXXO</td></tr></table>"
        )
        assert html_to_text(source) == "Valor $176.824,00\nComercio OXXO"

    def test_tags_inline_no_parten_la_linea(self) -> None:
        source = "<p>Compraste <b>$176.824,00</b> en <a href='x'>OXXO</a></p>"
        assert html_to_text(source) == "Compraste $176.824,00 en OXXO"

    def test_br_y_bloques_cortan_linea(self) -> None:
        source = "<div>uno<br>dos</div><p>tres</p><h1>cuatro</h1><ul><li>cinco</li></ul>"
        assert html_to_text(source) == "uno\ndos\ntres\ncuatro\ncinco"

    def test_tags_autocerrados_cortan_linea(self) -> None:
        assert html_to_text("uno<br/>dos<hr/>tres<img src='x'/>") == "uno\ndos\ntres"

    def test_descarta_script_style_head_y_comentarios(self) -> None:
        source = (
            "<html><head><title>T</title><style>p{}</style></head><body>"
            "<!-- nada --><script>alert(1)</script><p>visible</p></body></html>"
        )
        assert html_to_text(source) == "visible"

    def test_decodifica_entidades_y_nbsp(self) -> None:
        assert html_to_text("<p>Caf&eacute;&nbsp;&amp;&#160;m&aacute;s</p>") == "Café & más"

    def test_colapsa_espacios_y_lineas_vacias(self) -> None:
        source = "<div>  hola \n   mundo  </div><div></div><div>   </div><div>fin</div>"
        assert html_to_text(source) == "hola mundo\nfin"

    def test_texto_vacio(self) -> None:
        assert html_to_text("") == ""


@pytest.mark.unit
class TestExtractBody:
    def test_text_plain_simple(self) -> None:
        assert extract_body(_text("  Hola\r\nmundo  \n")) == "Hola\nmundo"

    def test_prefiere_text_plain_sobre_html_en_multipart_alternative(self) -> None:
        payload = MimePart(
            mime_type="multipart/alternative",
            parts=(
                _text("<p>version html</p>", mime_type="text/html"),
                _text("version plana"),
            ),
        )
        assert extract_body(payload) == "version plana"

    def test_sin_text_plain_convierte_el_html(self) -> None:
        payload = MimePart(
            mime_type="multipart/mixed",
            parts=(
                MimePart(
                    mime_type="multipart/related",
                    parts=(
                        _text(
                            "<table><tr><td>a</td><td>b</td></tr></table>", mime_type="text/html"
                        ),
                        MimePart(mime_type="image/png", data=b"\x89PNG", filename="logo.png"),
                    ),
                ),
            ),
        )
        assert extract_body(payload) == "a b"

    def test_ignora_adjuntos_aunque_sean_text_plain(self) -> None:
        payload = MimePart(
            mime_type="multipart/mixed",
            parts=(
                _text("adjunto", filename="extracto.txt"),
                _text("<p>cuerpo</p>", mime_type="text/html"),
            ),
        )
        assert extract_body(payload) == "cuerpo"

    def test_text_plain_vacio_cae_al_html(self) -> None:
        payload = MimePart(
            mime_type="multipart/alternative",
            parts=(_text("   "), _text("<p>html</p>", mime_type="text/html")),
        )
        assert extract_body(payload) == "html"

    def test_sin_partes_de_texto_devuelve_vacio(self) -> None:
        payload = MimePart(
            mime_type="multipart/mixed",
            parts=(MimePart(mime_type="application/pdf", data=b"%PDF", filename="a.pdf"),),
        )
        assert extract_body(payload) == ""

    def test_mime_type_es_case_insensitive(self) -> None:
        assert extract_body(_text("hola", mime_type="Text/Plain")) == "hola"

    def test_respeta_el_charset_declarado(self) -> None:
        part = _text("Compraste en PANADERÍA", charset="iso-8859-1")
        assert extract_body(part) == "Compraste en PANADERÍA"

    def test_charset_desconocido_cae_a_utf8_con_reemplazo(self) -> None:
        part = MimePart(
            mime_type="text/plain", data="ñandú\xff".encode() + b"\xff", charset="x-raro"
        )
        assert extract_body(part).startswith("ñandú")

    def test_trunca_a_8_kb_sin_partir_caracteres(self) -> None:
        assert GMAIL_BODY_MAX_BYTES == 8192
        body = extract_body(_text("ñ" * 10_000))
        assert len(body.encode("utf-8")) <= GMAIL_BODY_MAX_BYTES
        assert set(body) == {"ñ"}

    def test_max_bytes_configurable(self) -> None:
        assert extract_body(_text("abcdef"), max_bytes=3) == "abc"


@pytest.mark.unit
@pytest.mark.parametrize("fixture", _ALL_FIXTURES, ids=lambda f: f.name)
class TestExtractBodyConFixturesReales:
    def test_text_plain_conserva_la_linea_del_movimiento(self, fixture: EmailFixture) -> None:
        body = extract_body(_text(fixture.body))
        assert _key_line(fixture) in body.splitlines()

    def test_html_bancario_conserva_la_linea_del_movimiento(self, fixture: EmailFixture) -> None:
        payload = MimePart(
            mime_type="multipart/alternative",
            parts=(_text(_as_bank_html(fixture), mime_type="text/html"),),
        )
        body = extract_body(payload)
        assert _key_line(fixture) in body.splitlines()
        assert "var x" not in body
        assert "Alertas" not in body.splitlines()[0]


@pytest.mark.unit
class TestGmailMessage:
    def test_body_delegando_en_extract_body(self) -> None:
        msg = GmailMessage(
            id="18c2f0a1b2c3d4e5",
            sender="Bancolombia <alertas@bancolombia.com.co>",
            internal_date=datetime(2026, 5, 1, 21, 0, tzinfo=UTC),
            payload=_text("hola"),
        )
        assert msg.body() == "hola"

    def test_internal_date_debe_ser_aware(self) -> None:
        with pytest.raises(ValueError, match="aware"):
            GmailMessage(
                id="x",
                sender="a@b.co",
                internal_date=datetime(2026, 5, 1, 21, 0),
                payload=_text("hola"),
            )
