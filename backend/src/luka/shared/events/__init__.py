"""Bus de eventos interno (spec 003 SS2.3): Redis Streams con consumer groups.

Re-exporta la API publica del paquete para que los composition roots (`app.py`,
`worker.py`) y `modules/*/infrastructure` no tengan que conocer la organizacion
interna en submodulos.
"""

from luka.shared.events.base import DomainEvent, event_type_of
from luka.shared.events.codec import EventRegistry, UnknownEventType
from luka.shared.events.consumer import StreamConsumer
from luka.shared.events.idempotent import IdempotentHandler
from luka.shared.events.memory import InMemoryEventBus
from luka.shared.events.port import EventBusPort, EventHandler
from luka.shared.events.redis_streams import RedisStreamsEventBus

__all__ = [
    "DomainEvent",
    "EventBusPort",
    "EventHandler",
    "EventRegistry",
    "IdempotentHandler",
    "InMemoryEventBus",
    "RedisStreamsEventBus",
    "StreamConsumer",
    "UnknownEventType",
    "event_type_of",
]
