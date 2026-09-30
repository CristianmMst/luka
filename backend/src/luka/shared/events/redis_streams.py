"""Bus de eventos sobre Redis Streams con grupos de consumidores (spec 003 SS2.3)."""

from __future__ import annotations

from typing import TYPE_CHECKING, cast

import redis.exceptions

if TYPE_CHECKING:
    from redis.asyncio import Redis
    from redis.typing import EncodableT, FieldT

    from luka.shared.events.codec import EventRegistry

_DEFAULT_PREFIX = "luka:events"
_DEFAULT_MAXLEN = 100_000


class RedisStreamsEventBus:
    """Publica a `{prefix}:{event_type}` via `XADD` con recorte aproximado (MAXLEN ~)."""

    def __init__(
        self,
        redis: Redis,
        registry: EventRegistry,
        *,
        prefix: str = _DEFAULT_PREFIX,
        maxlen: int = _DEFAULT_MAXLEN,
    ) -> None:
        self._redis = redis
        self._registry = registry
        self._prefix = prefix
        # Publico: `StreamConsumer._to_dlq` recorta la DLQ con el MISMO limite que
        # los streams principales (sin el, la DLQ crece sin cota).
        self.maxlen = maxlen
        self.dlq_stream = f"{prefix}:dlq"

    def stream_name(self, event_type: str) -> str:
        return f"{self._prefix}:{event_type}"

    async def publish(self, event: object) -> None:
        fields = self._registry.encode(event)
        stream = self.stream_name(fields["event_type"])
        # `redis.typing.FieldT`/`EncodableT` son alias concretos (no TypeVars); un
        # `dict[str, str]` no es asignable directo por la invariancia de `Dict`,
        # de ahi el `cast` al tipo exacto que espera `xadd`.
        payload = cast("dict[FieldT, EncodableT]", fields)
        await self._redis.xadd(stream, payload, maxlen=self.maxlen, approximate=True)

    async def ensure_group(self, stream: str, group: str) -> None:
        """`XGROUP CREATE stream group $ MKSTREAM`; ignora `BUSYGROUP` (ya existia)."""
        try:
            await self._redis.xgroup_create(stream, group, id="$", mkstream=True)
        except redis.exceptions.ResponseError as exc:
            if "BUSYGROUP" not in str(exc):
                raise


__all__ = ["RedisStreamsEventBus"]
