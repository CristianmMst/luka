"""Adaptador que publica eventos de identity en el bus compartido (spec 003 SS2.3)."""

from __future__ import annotations

from typing import TYPE_CHECKING

import redis.exceptions
import structlog

if TYPE_CHECKING:
    from luka.shared.events.port import EventBusPort

_logger = structlog.get_logger()


class BusEventPublisher:
    """Satisface `EventPublisherPort` delegando en un `EventBusPort`."""

    def __init__(self, bus: EventBusPort) -> None:
        self._bus = bus

    async def publish(self, event: object) -> None:
        """Publica `event` despues del commit; si el bus no responde, avisa y
        sigue: el borrado ya esta hecho y no debe convertirse en un 500."""
        try:
            await self._bus.publish(event)
        except (redis.exceptions.RedisError, OSError, TimeoutError):
            _logger.warning(
                "event_publish_failed",
                event_type=getattr(event, "event_type", None),
                event_id=getattr(event, "event_id", None),
            )


__all__ = ["BusEventPublisher"]
