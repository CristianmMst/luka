"""Normalizadores puros de parsing (spec 006 §4.1/§4.3, stdlib solo, P3).

`parse_amount` aplica la regla determinista (bancolombia-templates-spec §0):
si aparecen `.` y `,`, el ultimo separador (el que este mas a la derecha) es
el decimal y el otro se trata como separador de miles; si aparece un unico
tipo de separador una sola vez seguido de exactamente 2 digitos, es decimal;
en cualquier otro caso (aparece 0 o >=2 veces, o seguido de otra cantidad de
digitos) se trata como separador de miles.
"""

from __future__ import annotations

import re
from datetime import datetime
from decimal import ROUND_HALF_UP, Decimal, InvalidOperation
from zoneinfo import ZoneInfo

from finanzia.modules.parsing.domain.errors import AmountInvalid, DateInvalid

_CENTS = Decimal("0.01")
_COP_RE = re.compile(r"(?i)cop")
_WHITESPACE_RE = re.compile(r"\s+")
_VALID_AMOUNT_RE = re.compile(r"^\d+([.,]\d+)*$")
_TRAILING_PUNCT_RE = re.compile(r"[.,;:]+$")

_DECIMAL_LEN = 2


def parse_amount(raw: str) -> Decimal:
    """Convierte un monto colombiano (es-CO o en-US, con `$`/`COP`) a `Decimal`.

    Cuantiza a 2 decimales (`ROUND_HALF_UP`); exige resultado > 0, si no
    lanza `AmountInvalid`.
    """
    cleaned = _COP_RE.sub("", raw)
    cleaned = cleaned.replace("$", "")
    cleaned = _WHITESPACE_RE.sub("", cleaned)
    if not cleaned or not _VALID_AMOUNT_RE.match(cleaned):
        raise AmountInvalid(f"monto invalido: {raw!r}")

    has_dot = "." in cleaned
    has_comma = "," in cleaned
    if has_dot and has_comma:
        decimal_sep = "." if cleaned.rfind(".") > cleaned.rfind(",") else ","
        thousands_sep = "," if decimal_sep == "." else "."
        integer_part, _, decimal_part = cleaned.rpartition(decimal_sep)
        normalized = f"{integer_part.replace(thousands_sep, '')}.{decimal_part}"
    elif has_dot or has_comma:
        sep = "." if has_dot else ","
        parts = cleaned.split(sep)
        if len(parts) == 2 and len(parts[1]) == _DECIMAL_LEN:  # noqa: PLR2004
            normalized = f"{parts[0]}.{parts[1]}"
        else:
            normalized = "".join(parts)
    else:
        normalized = cleaned

    try:
        amount = Decimal(normalized)
    except InvalidOperation as exc:
        raise AmountInvalid(f"monto invalido: {raw!r}") from exc

    quantized = amount.quantize(_CENTS, rounding=ROUND_HALF_UP)
    if quantized <= 0:
        raise AmountInvalid(f"monto debe ser mayor que cero: {quantized}")
    return quantized


def parse_local_datetime(
    date_str: str,
    time_str: str,
    date_format: str,
    tz: str = "America/Bogota",
) -> datetime:
    """Combina fecha + hora local (plantilla) en un `datetime` aware.

    `date_format` es el formato `strptime` de la fecha (p. ej. `%d/%m/%Y`);
    la hora siempre se interpreta como `%H:%M`. Lanza `DateInvalid` si no se
    puede parsear.
    """
    try:
        naive = datetime.strptime(f"{date_str} {time_str}", f"{date_format} %H:%M")
    except ValueError as exc:
        raise DateInvalid(f"fecha/hora invalida: {date_str!r} {time_str!r}") from exc
    return naive.replace(tzinfo=ZoneInfo(tz))


def clean_text(value: str) -> str:
    """Strip + colapso de espacios + remocion de puntuacion final."""
    collapsed = _WHITESPACE_RE.sub(" ", value.strip())
    return _TRAILING_PUNCT_RE.sub("", collapsed).strip()


__all__ = ["clean_text", "parse_amount", "parse_local_datetime"]
