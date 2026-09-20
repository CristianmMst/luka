"""Reloj de pruebas con hora fija y avance manual (doble de `SystemClock`)."""

from datetime import datetime, timedelta


class FixedClock:
    """Reloj determinista para tests: `now()` fija hasta que se llame `advance`."""

    def __init__(self, fixed: datetime) -> None:
        self._now = fixed

    def now(self) -> datetime:
        return self._now

    def advance(self, delta: timedelta = timedelta(seconds=1)) -> None:
        self._now += delta
