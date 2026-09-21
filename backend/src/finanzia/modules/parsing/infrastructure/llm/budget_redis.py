"""Presupuesto mensual de tokens del LLM sobre Redis (spec 006 §4.2).

Clave `llm:budget:{user_id}:{YYYYMM}`; `add` incrementa y fija un TTL de 40
dias solo si la clave no tenia uno (`EXPIRE ... NX`), asi un reintento no
extiende artificialmente la ventana de un mes ya vencido.
"""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import UUID

if TYPE_CHECKING:
    from redis.asyncio import Redis

_TTL_SECONDS = 40 * 24 * 3600


def _key(user_id: UUID, month_key: str) -> str:
    return f"llm:budget:{user_id}:{month_key}"


class RedisLlmBudget:
    """Implementa `LlmBudgetPort` sobre Redis."""

    def __init__(self, redis: Redis) -> None:
        self._redis = redis

    async def used(self, user_id: UUID, month_key: str) -> int:
        value = await self._redis.get(_key(user_id, month_key))
        return int(value or 0)

    async def add(self, user_id: UUID, month_key: str, tokens: int) -> None:
        key = _key(user_id, month_key)
        await self._redis.incrby(key, tokens)
        await self._redis.expire(key, _TTL_SECONDS, nx=True)


__all__ = ["RedisLlmBudget"]
