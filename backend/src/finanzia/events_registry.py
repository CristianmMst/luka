"""Composition root: registro de eventos de dominio conocidos (spec 003 SS2.3).

Import compartido por `app.py` y `worker.py`. No es `shared` (que nunca puede
importar `finanzia.modules`): vive junto a esos composition roots y, como ellos,
puede importar eventos de cualquier modulo.
"""

from finanzia.modules.identity.events import UserDeleted
from finanzia.modules.ingestion.events import RawMessageReceived
from finanzia.modules.ledger.events import TransactionCaptured
from finanzia.modules.parsing.events import ParseFailed, TransactionParsed
from finanzia.shared.events.codec import EventRegistry
from finanzia.shared.events.redis_streams import RedisStreamsEventBus

# Grupo de consumidores por evento (D10, F2.2): un evento -> un unico grupo hoy.
# Se crean (idempotente) tanto al arrancar la API (`app.py`) como el worker
# (`StreamConsumer.run`, via `ensure_group`), para que un evento publicado antes
# del primer arranque del worker no se pierda.
CONSUMER_GROUPS: tuple[tuple[str, str], ...] = (
    ("ingestion.RawMessageReceived", "parsing"),
    ("parsing.TransactionParsed", "ledger"),
    ("parsing.ParseFailed", "ledger-review"),
    ("ledger.TransactionCaptured", "ledger-observer"),
)


def build_registry() -> EventRegistry:
    """`EventRegistry` con todos los eventos de dominio publicados hoy (F1.8/F2.2)."""
    registry = EventRegistry()
    registry.register(TransactionCaptured)
    registry.register(UserDeleted)
    registry.register(RawMessageReceived)
    registry.register(TransactionParsed)
    registry.register(ParseFailed)
    return registry


async def ensure_consumer_groups(bus: RedisStreamsEventBus) -> None:
    """Crea (idempotente) todos los grupos de `CONSUMER_GROUPS` (D10).

    `RedisStreamsEventBus.ensure_group` ya ignora `BUSYGROUP` (grupo existente);
    llamar esto dos veces es un no-op seguro.
    """
    for event_type, group in CONSUMER_GROUPS:
        await bus.ensure_group(bus.stream_name(event_type), group)


__all__ = ["CONSUMER_GROUPS", "build_registry", "ensure_consumer_groups"]
