"""Mensaje de Gmail y extraccion de su cuerpo (spec 006 §2.3).

Puro (stdlib solo, P3). El adaptador (`infrastructure/gmail_client.py`) traduce
el JSON de `users.messages.get?format=full` a `GmailMessage`/`MimePart` (ya con
`body.data` decodificado de base64url); aqui solo se decide que parte es el
cuerpo y como se convierte a texto:

- Se prefiere la primera parte `text/plain` no vacia (recorrido en profundidad).
- Si no hay, la primera `text/html`, convertida a texto con `html.parser`: los
  tags de bloque (`p`, `div`, `br`, `tr`, `li`, ...) cortan linea, las celdas de
  una fila se unen con un espacio (cada fila de tabla queda como una linea) y se
  descartan `script`/`style`/`head` y comentarios.
- Las partes con `filename` son adjuntos y nunca se usan como cuerpo.
- El resultado se trunca a 8 KB en frontera de caracter (`truncate_utf8`).
"""

from __future__ import annotations

import codecs
import re
from dataclasses import dataclass
from datetime import datetime
from email.utils import parseaddr
from html.parser import HTMLParser

from finanzia.modules.ingestion.domain.body import truncate_utf8

GMAIL_BODY_MAX_BYTES = 8192

_BLOCK_TAGS = frozenset(
    {
        "address",
        "article",
        "aside",
        "blockquote",
        "br",
        "caption",
        "center",
        "dd",
        "div",
        "dl",
        "dt",
        "footer",
        "form",
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "header",
        "hr",
        "li",
        "ol",
        "p",
        "pre",
        "section",
        "table",
        "tbody",
        "tfoot",
        "thead",
        "tr",
        "ul",
    }
)
_CELL_TAGS = frozenset({"td", "th"})
_SKIPPED_TAGS = frozenset({"head", "script", "style", "template", "noscript"})
# En HTML los saltos de linea del fuente son espacio; solo los tags de bloque cortan linea.
_WHITESPACE = re.compile(r"\s+")


@dataclass(frozen=True, slots=True)
class MimePart:
    """Una parte MIME de un mensaje de Gmail (`payload` o `payload.parts[]`).

    `data` son los bytes ya decodificados de base64url (vacio en contenedores
    `multipart/*` y en adjuntos que Gmail entrega aparte por `attachmentId`).
    """

    mime_type: str
    data: bytes = b""
    charset: str | None = None
    filename: str = ""
    parts: tuple[MimePart, ...] = ()


@dataclass(frozen=True, slots=True)
class GmailMessage:
    """Mensaje leido de Gmail: id, remitente (`From` crudo), fecha interna y partes.

    `internal_date` es el `internalDate` de Gmail (recepcion en el buzon), aware.
    """

    id: str
    sender: str
    internal_date: datetime
    payload: MimePart

    def __post_init__(self) -> None:
        if self.internal_date.tzinfo is None or self.internal_date.utcoffset() is None:
            raise ValueError("internal_date debe ser aware")

    @property
    def sender_address(self) -> str:
        """Direccion del `From` en minusculas, sin display name; `""` si no hay una
        direccion inequivoca (el filtro de remitentes la descarta, AC-2.4).
        """
        _, address = parseaddr(self.sender)
        address = address.strip().lower()
        return address if "@" in address else ""

    def body(self, max_bytes: int = GMAIL_BODY_MAX_BYTES) -> str:
        """El cuerpo en texto segun spec 006 §2.3 (ver `extract_body`)."""
        return extract_body(self.payload, max_bytes)


class _HtmlTextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self._chunks: list[str] = []
        self._skip_depth = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        del attrs
        if tag in _SKIPPED_TAGS:
            self._skip_depth += 1
        elif tag in _BLOCK_TAGS:
            self._chunks.append("\n")
        elif tag in _CELL_TAGS:
            self._chunks.append(" ")

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        # `<br/>`, `<hr/>`: sin cierre, no deben tocar `_skip_depth`.
        if tag in _BLOCK_TAGS:
            self._chunks.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag in _SKIPPED_TAGS:
            self._skip_depth = max(0, self._skip_depth - 1)
        elif tag in _BLOCK_TAGS:
            self._chunks.append("\n")
        elif tag in _CELL_TAGS:
            self._chunks.append(" ")

    def handle_data(self, data: str) -> None:
        if self._skip_depth == 0:
            self._chunks.append(_WHITESPACE.sub(" ", data))

    def text(self) -> str:
        return "".join(self._chunks)


def _normalize_lines(text: str) -> str:
    """Colapsa espacios (incluido `\\xa0`) dentro de cada linea y quita lineas vacias."""
    lines = (" ".join(line.split()) for line in text.splitlines())
    return "\n".join(line for line in lines if line)


def html_to_text(source: str) -> str:
    """Convierte HTML a texto plano conservando las filas de tabla como lineas."""
    parser = _HtmlTextExtractor()
    parser.feed(source)
    parser.close()
    return _normalize_lines(parser.text())


def _decode(part: MimePart) -> str:
    charset = part.charset or "utf-8"
    try:
        codecs.lookup(charset)
    except LookupError:
        charset = "utf-8"
    return part.data.decode(charset, errors="replace")


def _first_text_part(part: MimePart, mime_type: str) -> str | None:
    if part.filename:
        return None
    if part.mime_type.lower() == mime_type:
        text = _decode(part)
        if text.strip():
            return text
    for child in part.parts:
        found = _first_text_part(child, mime_type)
        if found is not None:
            return found
    return None


def extract_body(payload: MimePart, max_bytes: int = GMAIL_BODY_MAX_BYTES) -> str:
    """Cuerpo en texto de un mensaje (spec 006 §2.3): `text/plain` si existe; si no,
    el HTML convertido a texto; `""` si no hay ninguna parte de texto. Truncado a
    `max_bytes` bytes UTF-8.
    """
    plain = _first_text_part(payload, "text/plain")
    if plain is not None:
        text = plain.replace("\r\n", "\n").strip()
    else:
        html_source = _first_text_part(payload, "text/html")
        text = html_to_text(html_source) if html_source is not None else ""
    return truncate_utf8(text, max_bytes)


__all__ = ["GMAIL_BODY_MAX_BYTES", "GmailMessage", "MimePart", "extract_body", "html_to_text"]
