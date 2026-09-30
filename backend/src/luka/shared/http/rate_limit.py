"""Limitador de ventana deslizante sobre Redis, atomico via script Lua (spec 009 SS4, F1.4).

Un unico script Lua evita condiciones de carrera entre `ZREMRANGEBYSCORE`/`ZCARD`/
`ZADD` cuando dos requests concurrentes compiten por el ultimo cupo de la ventana.
Los scores del sorted set son milisegundos (mayor precision que segundos enteros).
"""

from __future__ import annotations

import time
from collections.abc import Callable
from dataclasses import dataclass
from math import ceil
from typing import cast
from uuid import uuid4

from redis.asyncio import Redis

_SLIDING_WINDOW_SCRIPT = """
local key = KEYS[1]
local now_ms = tonumber(ARGV[1])
local window_ms = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])
local member = ARGV[4]

redis.call('ZREMRANGEBYSCORE', key, 0, now_ms - window_ms)
local count = redis.call('ZCARD', key)

if count < limit then
    redis.call('ZADD', key, now_ms, member)
    redis.call('PEXPIRE', key, window_ms)
    return {1, 0}
end

local oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
local oldest_score = tonumber(oldest[2])
local retry_after_ms = oldest_score + window_ms - now_ms
return {0, retry_after_ms}
"""


@dataclass(frozen=True, slots=True)
class Decision:
    """Resultado de evaluar una ventana: si se permite y cuanto esperar (segundos)."""

    allowed: bool
    retry_after: int


class SlidingWindowLimiter:
    """Ventana deslizante sobre un sorted set de Redis por clave."""

    def __init__(self, redis: Redis, *, now: Callable[[], float] | None = None) -> None:
        self._now = now if now is not None else time.time
        self._script = redis.register_script(_SLIDING_WINDOW_SCRIPT)

    async def hit(self, key: str, limit: int, window_s: int) -> Decision:
        """Registra un intento contra `key`; devuelve la decision (permitido/retry_after)."""
        now_ms = int(self._now() * 1000)
        window_ms = window_s * 1000
        member = f"{now_ms}-{uuid4().hex[:8]}"

        # El script Lua devuelve una tabla `{allowed, retry_after_ms}`; los stubs de
        # redis-py tipan el resultado como `Any`/`str`, de ahi el `cast` explicito.
        result = cast(
            "list[int]",
            await self._script(keys=[key], args=[now_ms, window_ms, limit, member]),
        )
        allowed_flag, retry_after_ms = result[0], result[1]

        if allowed_flag:
            return Decision(allowed=True, retry_after=0)
        return Decision(allowed=False, retry_after=max(1, ceil(retry_after_ms / 1000)))
