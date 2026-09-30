"""Protocolo base de eventos de dominio (spec 003 SS2.3). Puro: solo stdlib.

Los eventos concretos (p. ej. `luka.modules.ledger.events.TransactionCaptured`)
son dataclasses frozen que cumplen este protocolo estructuralmente; no heredan de el.
"""

from __future__ import annotations

from datetime import datetime
from typing import ClassVar, Protocol, runtime_checkable
from uuid import UUID


@runtime_checkable
class DomainEvent(Protocol):
    """Contrato minimo de un evento de dominio publicable en el bus."""

    event_id: UUID
    occurred_at: datetime
    event_type: ClassVar[str]


def event_type_of(event_or_cls: object) -> str:
    """`event_type` de una instancia o de la clase misma de un evento de dominio."""
    cls = event_or_cls if isinstance(event_or_cls, type) else type(event_or_cls)
    return str(cls.event_type)  # type: ignore[attr-defined]


__all__ = ["DomainEvent", "event_type_of"]
