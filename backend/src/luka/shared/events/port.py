"""Puertos del bus de eventos: publicacion y manejo (spec 003 SS2.3)."""

from __future__ import annotations

from typing import Protocol


class EventBusPort(Protocol):
    """Publicacion de eventos de dominio, sin importar el backend (memoria o Redis)."""

    async def publish(self, event: object) -> None: ...


class EventHandler(Protocol):
    """Callable async que procesa un evento ya decodificado."""

    async def __call__(self, event: object) -> None: ...


__all__ = ["EventBusPort", "EventHandler"]
