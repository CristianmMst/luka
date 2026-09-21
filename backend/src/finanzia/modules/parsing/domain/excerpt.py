"""Extraccion del fragmento util del cuerpo de un mensaje (spec 006 §2.3/§4.1, P3).

Reduce el cuerpo crudo a lo minimo necesario antes de mandarlo a una
plantilla regex o al LLM (RNF-5, costo por token).
"""

from __future__ import annotations

import re

_URL_RE = re.compile(r"(?i)https?://|www\.")
_PHONE_RE = re.compile(r"\d{3}[\s-]?\d{3}[\s-]?\d{4}")
_MONETARY_RE = re.compile(r"\$\s?\d|COP|\d{1,3}(?:[.,]\d{3})+")


def looks_monetary(text: str) -> bool:
    """`True` si `text` contiene un signo de monto (`$`, `COP`, miles con separador)."""
    return bool(_MONETARY_RE.search(text))


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
