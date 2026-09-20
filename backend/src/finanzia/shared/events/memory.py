"""Bus de eventos en memoria: para tests y desarrollo (spec 003 SS2.3)."""

from __future__ import annotations

from collections import defaultdict
from typing import TYPE_CHECKING

from finanzia.shared.events.base import event_type_of

if TYPE_CHECKING:
    from finanzia.shared.events.codec import EventRegistry
    from finanzia.shared.events.port import EventHandler


class InMemoryEventBus:
    """Publica sincronicamente a los handlers suscritos; guarda todo en `published`."""

    def __init__(self, registry: EventRegistry) -> None:
        self._registry = registry
        self.published: list[object] = []
        self._handlers: dict[str, list[EventHandler]] = defaultdict(list)

    def subscribe(self, event_type: str, handler: EventHandler) -> None:
        self._handlers[event_type].append(handler)

    async def publish(self, event: object) -> None:
        self.published.append(event)
        for handler in self._handlers.get(event_type_of(event), []):
            await handler(event)


__all__ = ["InMemoryEventBus"]
