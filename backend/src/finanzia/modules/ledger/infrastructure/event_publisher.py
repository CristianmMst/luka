"""Adaptador que publica eventos de ledger en el bus compartido (spec 003 SS2.3)."""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from finanzia.shared.events.port import EventBusPort


class BusEventPublisher:
    """Satisface `EventPublisherPort` delegando en un `EventBusPort` (Redis o memoria)."""

    def __init__(self, bus: EventBusPort) -> None:
        self._bus = bus

    async def publish(self, event: object) -> None:
        await self._bus.publish(event)


__all__ = ["BusEventPublisher"]
