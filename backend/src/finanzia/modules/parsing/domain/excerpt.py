"""Extraccion del fragmento util del cuerpo de un mensaje (spec 006 §2.3/§4.1, P3).

Reduce el cuerpo crudo a lo minimo necesario antes de mandarlo a una
plantilla regex o al LLM (RNF-5, costo por token).
"""

from __future__ import annotations

import re

_URL_RE = re.compile(r"(?i)https?://|www\.")
_PHONE_RE = re.compile(
    r"\d{3}[\s.\-]?\d{3}[\s.\-]?\d{4}"  # 3-3-4: local/celular, con/sin separador (incl. punto)
    r"|\d{3}[\s.\-]\d{3}[\s.\-]\d{3}[\s.\-]\d{3}"  # 3-3-3-3: gratuita espaciada (018 000 931 987)
)
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


def extract_excerpt(body: str, relevant_line_prefix: str | None, max_chars: int = 1500) -> str:
    """Reduce `body` a las lineas relevantes, truncadas a `max_chars`.

    Si `relevant_line_prefix` esta configurado y alguna linea empieza por el,
    el extracto son exactamente esas lineas (join por `\\n`). En cualquier
    otro caso (sin prefijo, o ninguna linea lo matchea) cae al fallback:
    lineas no vacias sin URLs ni secuencias tipo telefono.
    """
    lines = body.splitlines()
    if relevant_line_prefix:
        matched = [line for line in lines if line.startswith(relevant_line_prefix)]
        if matched:
            return "\n".join(matched)[:max_chars]

    fallback = [
        stripped
        for line in lines
        if (stripped := line.strip())
        and not _URL_RE.search(stripped)
        and not _PHONE_RE.search(stripped)
    ]
    return "\n".join(fallback)[:max_chars]


__all__ = ["extract_excerpt", "looks_monetary"]
