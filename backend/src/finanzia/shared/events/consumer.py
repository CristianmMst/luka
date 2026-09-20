"""Consumidor de un stream via grupo de consumidores (spec 003 SS2.3).

At-least-once con reintentos: `XREADGROUP >` para mensajes nuevos, `XAUTOCLAIM` para
reclamar pendientes abandonados por un consumidor caido, y DLQ cuando un mensaje
supera `max_deliveries`. Fail-soft ante errores de Redis (log + reintento; nunca
crashea el loop). Nunca loguea el payload de un evento (spec 009 SS5, P1).
"""

from __future__ import annotations

import asyncio
import os
import socket
from typing import TYPE_CHECKING, cast

import redis.exceptions
import structlog

from finanzia.shared.events.idempotent import IdempotentHandler

if TYPE_CHECKING:
    from redis.asyncio import Redis
    from redis.typing import EncodableT, FieldT

    from finanzia.shared.events.base import DomainEvent
    from finanzia.shared.events.codec import EventRegistry
    from finanzia.shared.events.port import EventHandler
    from finanzia.shared.events.redis_streams import RedisStreamsEventBus

_logger = structlog.get_logger()

_DEFAULT_BLOCK_MS = 5000
_DEFAULT_BATCH = 50
_DEFAULT_MAX_DELIVERIES = 5
_DEFAULT_CLAIM_MIN_IDLE_MS = 60_000
_BACKEND_ERROR_SLEEP_S = 1.0

_StreamMessage = tuple[bytes, dict[bytes, bytes]]


class StreamConsumer:
    """Consume `event_type` en `group`, con reclamo de pendientes y DLQ."""

    def __init__(  # noqa: PLR0913 - firma fijada por controller ruling (Task 14)
        self,
        bus: RedisStreamsEventBus,
        redis: Redis,
        registry: EventRegistry,
        *,
        group: str,
        event_type: str,
        handler: EventHandler,
        consumer_name: str | None = None,
        block_ms: int = _DEFAULT_BLOCK_MS,
        batch: int = _DEFAULT_BATCH,
        max_deliveries: int = _DEFAULT_MAX_DELIVERIES,
        claim_min_idle_ms: int = _DEFAULT_CLAIM_MIN_IDLE_MS,
    ) -> None:
        """`max_deliveries` es el numero de INTENTOS de handler permitidos: un
        mensaje va a la DLQ recien cuando ya se intento `max_deliveries` veces y
        volvio a quedar pendiente (`delivery_count > max_deliveries`), no en el
        intento numero `max_deliveries` (ese todavia se ejecuta).
        """
        self._bus = bus
        self._redis = redis
        self._registry = registry
        self._group = group
        self._event_type = event_type
        self._stream = bus.stream_name(event_type)
        self._consumer_name = consumer_name or f"{socket.gethostname()}-{os.getpid()}"
        self._block_ms = block_ms
        self._batch = batch
        self._max_deliveries = max_deliveries
        self._claim_min_idle_ms = claim_min_idle_ms
        self._idempotent = IdempotentHandler(redis, group=group, handler=handler)

    async def run(self, stop: asyncio.Event) -> None:
        """Corre hasta que `stop` se marque; cancelable entre iteraciones del loop.

        Fail-soft de punta a punta: `ensure_group`, el claim de pendientes, la
        lectura y el procesamiento del batch completo (fresco o reclamado) corren
        bajo la misma guarda. Un error de Redis en cualquiera de esos pasos —
        incluidos el `XACK`/`XADD` a DLQ dentro de `_process`, que antes quedaban
        sin proteger— se loguea y reintenta tras 1s en vez de propagar y matar la
        tarea de fondo. Un mensaje que no se pudo ACKear por una falla transitoria
        queda pendiente y se reintenta en la siguiente iteracion (at-least-once).
        `ensure_group` tambien se reintenta hasta que el grupo quede listo.
        """
        group_ready = False
        while not stop.is_set():
            try:
                if not group_ready:
                    await self._bus.ensure_group(self._stream, self._group)
                    group_ready = True
                await self._claim_stale_pending()
                messages = await self._read_new()
                for message_id, fields in messages:
                    await self._process(message_id, fields)
            except (redis.exceptions.RedisError, OSError) as exc:
                _logger.warning(
                    "event_consumer_backend_error",
                    event_type=self._event_type,
                    error_type=type(exc).__name__,
                )
                await asyncio.sleep(_BACKEND_ERROR_SLEEP_S)

    async def _read_new(self) -> list[_StreamMessage]:
        try:
            response = await asyncio.wait_for(
                self._redis.xreadgroup(
                    self._group,
                    self._consumer_name,
                    {self._stream: ">"},
                    count=self._batch,
                    block=self._block_ms,
                ),
                timeout=(self._block_ms / 1000) + 1,
            )
        except TimeoutError:
            return []
        if not response:
            return []
        _stream_name, entries = response[0]
        return list(entries)

    async def _claim_stale_pending(self) -> None:
        _next_cursor, messages, _deleted = await self._redis.xautoclaim(
            self._stream,
            self._group,
            self._consumer_name,
            self._claim_min_idle_ms,
            start_id="0-0",
            count=self._batch,
        )
        for message_id, fields in messages:
            await self._process(message_id, fields)

    async def _process(self, message_id: bytes, fields: dict[bytes, bytes]) -> None:
        try:
            # `decode` devuelve `object` (registro dinamico); todo evento registrado
            # satisface `DomainEvent` estructuralmente (event_id/occurred_at).
            event = cast("DomainEvent", self._registry.decode(fields))
        except Exception:  # decode invalido nunca crashea el loop; se manda a DLQ
            _logger.warning(
                "event_decode_failed",
                event_type=self._event_type,
                message_id=message_id.decode(),
            )
            await self._to_dlq(message_id, fields, reason="decode_failed")
            await self._redis.xack(self._stream, self._group, message_id)
            return

        delivery_count = await self._delivery_count(message_id)
        if delivery_count > self._max_deliveries:
            await self._to_dlq(message_id, fields, reason="max_deliveries_exceeded")
            await self._redis.xack(self._stream, self._group, message_id)
            return

        try:
            await self._idempotent(event)
        except Exception:  # handler que falla queda pendiente (PEL); nunca crashea el loop
            _logger.warning(
                "event_handler_failed",
                event_type=self._event_type,
                event_id=str(event.event_id),
                delivery_count=delivery_count,
            )
            return
        await self._redis.xack(self._stream, self._group, message_id)

    async def _delivery_count(self, message_id: bytes) -> int:
        pending = await self._redis.xpending_range(
            self._stream, self._group, min=message_id, max=message_id, count=1
        )
        if not pending:
            return 1
        return int(pending[0]["times_delivered"])

    async def _to_dlq(self, message_id: bytes, fields: dict[bytes, bytes], *, reason: str) -> None:
        del message_id
        dlq_fields: dict[bytes, bytes] = dict(fields)
        dlq_fields[b"failed_group"] = self._group.encode()
        dlq_fields[b"reason"] = reason.encode()
        # `FieldT`/`EncodableT` (alias concretos, no TypeVars): se castea al tipo
        # exacto que espera `xadd` para esquivar la invariancia de `Dict`.
        await self._redis.xadd(self._bus.dlq_stream, cast("dict[FieldT, EncodableT]", dlq_fields))


__all__ = ["StreamConsumer"]
