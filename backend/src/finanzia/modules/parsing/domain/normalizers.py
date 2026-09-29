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

# Meses en espanol (Nequi: "26 de septiembre de 2026") -> numero, para que la
# plantilla use `%m` y no dependa del locale del proceso.
_MONTHS_ES = {
    "enero": "01",
    "febrero": "02",
    "marzo": "03",
    "abril": "04",
    "mayo": "05",
    "junio": "06",
    "julio": "07",
    "agosto": "08",
    "septiembre": "09",
    "setiembre": "09",
    "octubre": "10",
    "noviembre": "11",
    "diciembre": "12",
}
_MONTH_ES_RE = re.compile(r"\b(" + "|".join(_MONTHS_ES) + r")\b", re.IGNORECASE)
# "11:21 a.m", "1:05 p. m.", "9:00 AM": hora de 12 horas con meridiano.
_TIME_12H_RE = re.compile(r"^(\d{1,2}):(\d{2})\s*([ap])\.?\s*m\.?$", re.IGNORECASE)
_HOURS_12H = 12


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

    `date_format` es el formato `strptime` de la fecha (p. ej. `%d/%m/%Y`); un
    mes escrito en espanol ("septiembre") se cambia antes por su numero, asi
    que se usa `%m`. La hora es `%H:%M`, o de 12 horas con "a.m"/"p.m" (se
    pasa a 24 horas). Lanza `DateInvalid` si no se puede parsear.
    """
    date_norm = _MONTH_ES_RE.sub(lambda m: _MONTHS_ES[m.group(1).lower()], date_str)
    try:
        time_norm = _to_24h(time_str.strip())
        naive = datetime.strptime(f"{date_norm} {time_norm}", f"{date_format} %H:%M")
    except ValueError as exc:
        raise DateInvalid(f"fecha/hora invalida: {date_str!r} {time_str!r}") from exc
    return naive.replace(tzinfo=ZoneInfo(tz))


def _to_24h(time_str: str) -> str:
    """`"11:21 p.m"` -> `"23:21"`; una hora sin meridiano queda igual."""
    found = _TIME_12H_RE.match(time_str)
    if found is None:
        return time_str
    hour, minute, meridiem = int(found.group(1)), found.group(2), found.group(3).lower()
    if not 1 <= hour <= _HOURS_12H:
        raise ValueError(f"hora de 12 horas fuera de rango: {time_str!r}")
    hour %= _HOURS_12H
    if meridiem == "p":
        hour += _HOURS_12H
    return f"{hour:02d}:{minute}"


def clean_text(value: str) -> str:
    """Strip + colapso de espacios + remocion de puntuacion final."""
    collapsed = _WHITESPACE_RE.sub(" ", value.strip())
    return _TRAILING_PUNCT_RE.sub("", collapsed).strip()


__all__ = ["clean_text", "parse_amount", "parse_local_datetime"]
