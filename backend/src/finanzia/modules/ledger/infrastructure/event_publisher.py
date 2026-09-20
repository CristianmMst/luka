"""Adaptador que publica eventos de ledger en el bus compartido (spec 003 SS2.3)."""

from __future__ import annotations

from typing import TYPE_CHECKING

import redis.exceptions
import structlog

if TYPE_CHECKING:
    from finanzia.shared.events.port import EventBusPort

_logger = structlog.get_logger()


class BusEventPublisher:
    """Satisface `EventPublisherPort` delegando en un `EventBusPort` (Redis o memoria)."""

    def __init__(self, bus: EventBusPort) -> None:
        self._bus = bus

    async def publish(self, event: object) -> None:
        """Publica `event`; falla en silencio (con warning) si el bus no responde.

        Se llama despues del commit de la transaccion: la transaccion ya esta
        confirmada; perder el evento es preferible a un 500 que provoque
        duplicados en el reintento idempotente (outbox planificado en F2).
        """
        try:
            await self._bus.publish(event)
        except (redis.exceptions.RedisError, OSError, TimeoutError):
            _logger.warning(
                "event_publish_failed",
                event_type=getattr(event, "event_type", None),
                event_id=getattr(event, "event_id", None),
            )


__all__ = ["BusEventPublisher"]
