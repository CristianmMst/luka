"""Puerto de reloj del sistema: hora UTC consciente (aware)."""

from datetime import UTC, datetime


class SystemClock:
    """Implementacion real del reloj basada en la hora del sistema, en UTC."""

    def now(self) -> datetime:
        return datetime.now(UTC)
