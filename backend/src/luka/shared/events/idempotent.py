"""Handler idempotente: evita reprocesar el mismo `event_id` por grupo (spec 003 SS2.3, P2).

Orden check -> handle -> mark: el bus es at-least-once (spec 003 SS2.3), asi que el
mismo evento puede reentregarse; todo handler debe ser idempotente.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from redis.asyncio import Redis

    from luka.shared.events.base import DomainEvent
    from luka.shared.events.port import EventHandler

_DEFAULT_TTL_SECONDS = 7 * 24 * 3600
_DEFAULT_PREFIX = "luka:events:processed"


class IdempotentHandler:
    """Envuelve `handler`: `EXISTS` -> skip; si no, ejecuta y marca (`SET EX ttl`)."""

    def __init__(
        self,
        redis: Redis,
        *,
        group: str,
        handler: EventHandler,
        ttl_seconds: int = _DEFAULT_TTL_SECONDS,
        prefix: str = _DEFAULT_PREFIX,
    ) -> None:
        self._redis = redis
        self._group = group
        self._handler = handler
        self._ttl_seconds = ttl_seconds
        self._prefix = prefix

    def _key(self, event_id: object) -> str:
        return f"{self._prefix}:{self._group}:{event_id}"

    async def __call__(self, event: DomainEvent) -> bool:
        """`True` si se ejecuto el handler; `False` si ya estaba procesado (skip)."""
        key = self._key(event.event_id)
        if await self._redis.exists(key):
            return False
        await self._handler(event)
        await self._redis.set(key, "1", ex=self._ttl_seconds)
        return True


__all__ = ["IdempotentHandler"]
