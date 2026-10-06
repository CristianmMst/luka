"""Extraccion del fragmento util del cuerpo de un mensaje (spec 006 §2.3/§4.1, P3).

Reduce el cuerpo crudo a lo minimo necesario antes de mandarlo a una
plantilla regex o al LLM (RNF-5, costo por token).
"""

from __future__ import annotations

import re

_URL_RE = re.compile(r"(?i)https?://|www\.")
# Las anclas `(?<!\d)`/`(?!\d)` exigen consumir el telefono entero: sin ellas,
# `018000912345` (12 digitos) matcheaba solo sus primeros 10 y dejaba `45`.
# El prefijo de pais opcional (`+57`, `57 `) vive dentro de las anclas: sin
# el, `+573001234567` no matcheaba entero. La app replica este patron byte a
# byte (`amount_highlight.dart`).
_PHONE_RE = re.compile(
    r"(?<!\d)(?:\+?57[\s.\-]?)?(?:"
    r"01[89]000\d{6}"  # gratuita pegada, 12 digitos (018000912345 / 019000...)
    r"|\d{3}[\s.\-]?\d{3}[\s.\-]?\d{4}"  # 3-3-4: local/celular, con/sin separador (incl. punto)
    r"|\d{3}[\s.\-]\d{3}[\s.\-]\d{3}[\s.\-]\d{3}"  # 3-3-3-3: gratuita espaciada (018 000 931 987)
    r")(?!\d)"
)
# Corridas de 10+ cifras (referencias, cuentas completas): el fallback descarta
# la linea entera para que no lleguen al LLM (RNF-5).
_LONG_DIGITS_RE = re.compile(r"\d{10,}")
# Los segundos opcionales (`15:45:13`, pago desde producto) quedan en la cabeza:
# si no, el `:13` pasaria a la cola como digitos sueltos.
_TIME_RE = re.compile(r"\d{2}:\d{2}(?::\d{2})?")
_CURRENCY_MARKER_RE = re.compile(r"\$\s?\d|COP")
_THOUSANDS_RE = re.compile(
    r"\d{1,3}(?:[.,]\d{3}){2,}"  # miles sin decimales pero con >=2 grupos (1.234.567)
    r"|\d{1,3}(?:[.,]\d{3})+[.,]\d{2}(?!\d)"  # miles con centavos (1.234,56 / 45.900,00)
)


def looks_monetary(text: str) -> bool:
    """`True` si `text` contiene un signo de monto (`$`, `COP`) o miles agrupados
    que parecen un valor monetario.

    Las secuencias tipo telefono (`_PHONE_RE`) se descartan antes de evaluar: un
    numero como `604.510.9095` matchea el patron de miles con separador por
    coincidencia de forma, pero no es un monto (spec 006 §4.1, RNF-5).
    """
    stripped = _PHONE_RE.sub("", text)
    if _CURRENCY_MARKER_RE.search(stripped):
        return True
    return bool(_THOUSANDS_RE.search(stripped))


def _unwrapped_paragraphs(body: str) -> list[str]:
    """Parrafos de `body` (separados por lineas vacias), cada uno unido en una
    sola linea (*unwrap*) para poder buscar `relevant_line_prefix` aunque el
    proveedor de correo lo haya cortado a ~76 caracteres a mitad de frase.
    """
    paragraphs: list[str] = []
    current: list[str] = []
    for line in body.splitlines():
        stripped = line.strip()
        if stripped:
            current.append(stripped)
        elif current:
            paragraphs.append(" ".join(current))
            current = []
    if current:
        paragraphs.append(" ".join(current))
    return paragraphs


def _clean_tail(tail: str) -> str:
    """Recorta `tail` (lo que sigue a la hora `HH:MM` de la transaccion) en la
    primera URL o `[` (imagenes tipo `Icon 1 [https://...]`, RNF-5) y le quita
    secuencias tipo telefono. Nunca toca el texto ANTES de la hora: ahi puede
    vivir una llave Bre-B puramente numerica, indistinguible de un telefono
    para `_PHONE_RE` (spec 006 §4.1).
    """
    cut = len(tail)
    url_match = _URL_RE.search(tail)
    if url_match:
        cut = min(cut, url_match.start())
    bracket_idx = tail.find("[")
    if bracket_idx != -1:
        cut = min(cut, bracket_idx)
    return _PHONE_RE.sub("", tail[:cut])


def extract_excerpt(body: str, relevant_line_prefix: str | None, max_chars: int = 1500) -> str:
    """Reduce `body` al fragmento util, truncado a `max_chars`.

    Si `relevant_line_prefix` esta configurado, `body` se parte en parrafos
    (separados por lineas vacias) y cada parrafo se desenvuelve (une sus
    lineas fisicas en una sola, por espacio). En el primer parrafo donde el
    prefijo aparezca, en cualquier posicion, el extracto arranca en el
    prefijo. Lo que sigue a la hora `HH:MM` de la transaccion (boilerplate:
    "Dudas al <telefono>", imagenes, el inicio del pie de seguridad) se
    recorta en la primera URL/`[` y se le quitan secuencias tipo telefono
    (`_clean_tail`); el texto ANTES de la hora (donde vive el monto, la
    llave/last4 y el comerciante) no se toca. Si ningun parrafo contiene el
    prefijo (o no hay prefijo configurado) cae al fallback: lineas no vacias
    sin URLs, secuencias tipo telefono ni corridas de 10+ cifras.
    """
    if relevant_line_prefix:
        for paragraph in _unwrapped_paragraphs(body):
            idx = paragraph.find(relevant_line_prefix)
            if idx != -1:
                matched = paragraph[idx:]
                time_match = _TIME_RE.search(matched)
                if time_match:
                    head, tail = matched[: time_match.end()], matched[time_match.end() :]
                    matched = head + _clean_tail(tail)
                return matched[:max_chars]

    fallback = [
        stripped
        for line in body.splitlines()
        if (stripped := line.strip())
        and not _URL_RE.search(stripped)
        and not _PHONE_RE.search(stripped)
        and not _LONG_DIGITS_RE.search(stripped)
    ]
    return "\n".join(fallback)[:max_chars]


__all__ = ["extract_excerpt", "looks_monetary"]
