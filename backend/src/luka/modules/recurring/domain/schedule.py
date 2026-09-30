"""Calendario de ocurrencias en hora de Colombia (spec 011 SS3). Solo stdlib (P3)."""

from __future__ import annotations

import calendar
from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

BOGOTA = ZoneInfo("America/Bogota")
#: Dias antes y despues del vencimiento en que un pago cuenta (spec 011 SS2).
DETECTION_WINDOW_DAYS = 5
_DECEMBER = 12


def colombia_date(instant: datetime) -> date:
    """Fecha local de Colombia de un instante aware."""
    if instant.tzinfo is None:
        msg = "instant debe ser aware"
        raise ValueError(msg)
    return instant.astimezone(BOGOTA).date()


def month_start(day: date) -> date:
    """Primer dia del mes de `day` (el `period` de una ocurrencia)."""
    return day.replace(day=1)


def next_month(period: date) -> date:
    """Primer dia del mes siguiente a `period`."""
    if period.month == _DECEMBER:
        return date(period.year + 1, 1, 1)
    return date(period.year, period.month + 1, 1)


def due_date(period: date, day_of_month: int) -> date:
    """Vencimiento del mes `period`; si el mes es mas corto, su ultimo dia."""
    last = calendar.monthrange(period.year, period.month)[1]
    return date(period.year, period.month, min(day_of_month, last))


def window(due: date) -> tuple[date, date]:
    """Ventana de deteccion `[due - 5 d, due + 5 d]`, bordes incluidos."""
    delta = timedelta(days=DETECTION_WINDOW_DAYS)
    return due - delta, due + delta


def periods_to_ensure(today: date, since: date, day_of_month: int) -> list[date]:
    """Meses cuya ocurrencia debe existir hoy: el actual y el siguiente (spec 011 SS3).

    El mes actual solo cuenta si `since` (el dia en que el gasto fijo empezo a
    contar: creado o reanudado) no pasa de `due + 5 d`; asi un gasto registrado
    el 28 con vencimiento el 5 empieza a contar el mes siguiente.
    """
    current = month_start(today)
    periods: list[date] = []
    if since <= window(due_date(current, day_of_month))[1]:
        periods.append(current)
    periods.append(next_month(current))
    return periods


def parse_month(value: str) -> date:
    """`"2026-10"` -> `date(2026, 10, 1)`; `ValueError` si no es `AAAA-MM`."""
    year_s, sep, month_s = value.partition("-")
    if not sep or len(year_s) != 4 or len(month_s) != 2:  # noqa: PLR2004 - formato AAAA-MM
        msg = "mes invalido"
        raise ValueError(msg)
    return date(int(year_s), int(month_s), 1)


def months_between(start: date, end: date) -> int:
    """Cantidad de meses de `start` a `end` (ambos primeros de mes), sin incluir `end`."""
    return (end.year - start.year) * 12 + end.month - start.month
