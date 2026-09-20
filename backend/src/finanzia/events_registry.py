"""Composition root: registro de eventos de dominio conocidos (spec 003 SS2.3).

Import compartido por `app.py` y `worker.py`. No es `shared` (que nunca puede
importar `finanzia.modules`): vive junto a esos composition roots y, como ellos,
puede importar eventos de cualquier modulo.
"""

from finanzia.modules.identity.events import UserDeleted
from finanzia.modules.ledger.events import TransactionCaptured
from finanzia.shared.events.codec import EventRegistry


def build_registry() -> EventRegistry:
    """`EventRegistry` con todos los eventos de dominio publicados hoy (F1.8)."""
    registry = EventRegistry()
    registry.register(TransactionCaptured)
    registry.register(UserDeleted)
    return registry


__all__ = ["build_registry"]
