"""Cola y ejecucion del job `sync_gmail` (arq + Redis, spec 006 §2.1, F3.4).

- `ArqGmailSyncQueue` encola el job desde el webhook.
- `run_gmail_sync` es el cuerpo del job en el worker: toma un lock por usuario
  en Redis y corre `SyncGmail`.

Coalescencia: cada job marca primero `pending` y despues intenta el lock
(`SET NX EX`). Si otro job lo tiene, sale sin hacer nada; el dueno del lock,
al soltarlo, ve `pending` y hace otra pasada. Asi un aviso que llega a mitad de
un sync (despues de su `history.list`) no espera al siguiente push. No se usa
`_job_id` de arq para deduplicar: arq rechaza un job con el mismo id mientras
exista su resultado guardado (1 h por defecto), lo que tiraria los avisos
posteriores a un sync ya terminado.
"""

from __future__ import annotations

import asyncio
import secrets
from typing import TYPE_CHECKING, Any
from uuid import UUID

import redis.exceptions

from finanzia.modules.ingestion.application.dto import GmailSyncResult, IngestOutcome
from finanzia.modules.ingestion.application.use_cases.gmail_sync import SyncGmail
from finanzia.modules.ingestion.application.use_cases.ingest_raw_message import IngestRawMessage
from finanzia.modules.ingestion.domain.errors import GmailSyncEnqueueFailed
from finanzia.modules.ingestion.infrastructure.event_publisher import BusEventPublisher
from finanzia.modules.ingestion.infrastructure.id_generator import SecretsIdGenerator
from finanzia.modules.ingestion.infrastructure.logging import log_ingest_outcome
from finanzia.modules.ingestion.infrastructure.repositories import (
    SqlAlchemyGmailConnectionRepository,
    SqlAlchemyRawMessageRepository,
)
from finanzia.modules.ingestion.infrastructure.sender_policy import ParsingSenderPolicy
from finanzia.modules.ingestion.infrastructure.token_cipher import AesGcmTokenCipher
from finanzia.modules.ingestion.infrastructure.uow import SqlAlchemyUnitOfWork

if TYPE_CHECKING:
    from arq.connections import ArqRedis
    from redis.asyncio import Redis
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

    from finanzia.modules.ingestion.application.dto import RawMessageInput
    from finanzia.modules.ingestion.application.ports import ClockPort, GmailClientPort
    from finanzia.shared.events.port import EventBusPort
    from finanzia.shared.settings import Settings

#: Nombre del job en arq: el de la funcion `finanzia.worker.sync_gmail`.
SYNC_GMAIL_JOB = "sync_gmail"

_ENQUEUE_TIMEOUT_S = 2.0
#: Mayor que `job_timeout` del worker (300 s): el lock no vence con el job vivo.
_LOCK_TTL_S = 330
#: Pasadas extra por avisos que llegaron durante un sync; el resto lo cubre el proximo push.
_MAX_ROUNDS = 3
_RELEASE_IF_OWNER = """
if redis.call('get', KEYS[1]) == ARGV[1] then
    return redis.call('del', KEYS[1])
end
return 0
"""


def _lock_key(user_id: UUID) -> str:
    return f"gmail_sync:lock:{user_id}"


def _pending_key(user_id: UUID) -> str:
    return f"gmail_sync:pending:{user_id}"


class ArqGmailSyncQueue:
    """`GmailSyncQueuePort` sobre un `ArqRedis` (el mismo Redis de la API)."""

    def __init__(self, arq_redis: ArqRedis) -> None:
        self._arq = arq_redis

    async def enqueue_sync(self, user_id: UUID, history_id: int | None) -> None:
        try:
            await asyncio.wait_for(
                self._arq.enqueue_job(SYNC_GMAIL_JOB, str(user_id), history_id),
                timeout=_ENQUEUE_TIMEOUT_S,
            )
        except (redis.exceptions.RedisError, OSError, TimeoutError) as exc:
            raise GmailSyncEnqueueFailed(type(exc).__name__) from exc


class _LoggedIngest:
    """`RawMessageIngestPort` que emite `parsing_metric` por mensaje (spec 006 §6)."""

    def __init__(self, ingest: IngestRawMessage) -> None:
        self._ingest = ingest

    async def execute(self, input: RawMessageInput) -> IngestOutcome:
        outcome = await self._ingest.execute(input)
        log_ingest_outcome(outcome, input.channel.value)
        return outcome


def _build_sync(  # noqa: PLR0913 - un parametro por dependencia externa
    session: AsyncSession,
    *,
    event_bus: EventBusPort,
    gmail: GmailClientPort,
    cipher: AesGcmTokenCipher,
    clock: ClockPort,
    settings: Settings,
) -> SyncGmail:
    uow = SqlAlchemyUnitOfWork(session)
    ingest = IngestRawMessage(
        repo=SqlAlchemyRawMessageRepository(session),
        policy=ParsingSenderPolicy(),
        events=BusEventPublisher(event_bus),
        clock=clock,
        ids=SecretsIdGenerator(),
        uow=uow,
        retention_days=settings.raw_message_retention_days,
        body_max_bytes=settings.raw_message_body_max_bytes,
    )
    return SyncGmail(
        repo=SqlAlchemyGmailConnectionRepository(session),
        gmail=gmail,
        cipher=cipher,
        ingest=_LoggedIngest(ingest),
        clock=clock,
        uow=uow,
    )


async def run_gmail_sync(  # noqa: PLR0913 - un parametro por dependencia externa + el aviso
    *,
    session_factory: async_sessionmaker[AsyncSession],
    redis_client: Redis,
    event_bus: EventBusPort,
    gmail: GmailClientPort,
    clock: ClockPort,
    settings: Settings,
    user_id: UUID,
    history_id: int | None,
) -> list[GmailSyncResult]:
    """Cuerpo del job `sync_gmail`: pasadas de `SyncGmail` bajo el lock del usuario.

    Devuelve una entrada por pasada (vacia si otro job tenia el lock). Los errores
    de `SyncGmail` (p. ej. `GmailTransientError`) se propagan tras soltar el lock.
    """
    cipher = AesGcmTokenCipher.from_settings(settings)
    lock_key, pending_key = _lock_key(user_id), _pending_key(user_id)
    await redis_client.set(pending_key, b"1", ex=_LOCK_TTL_S)
    results: list[GmailSyncResult] = []
    notified: int | None = history_id
    for _ in range(_MAX_ROUNDS):
        owner = secrets.token_hex(16)
        if not await redis_client.set(lock_key, owner, nx=True, ex=_LOCK_TTL_S):
            break  # el dueno actual vera `pending` al soltar el lock
        try:
            await redis_client.delete(pending_key)
            async with session_factory() as session:
                sync = _build_sync(
                    session,
                    event_bus=event_bus,
                    gmail=gmail,
                    cipher=cipher,
                    clock=clock,
                    settings=settings,
                )
                results.append(await sync.execute(user_id, notified))
        finally:
            release: Any = redis_client.eval(_RELEASE_IF_OWNER, 1, lock_key, owner)
            await release
        notified = None  # las pasadas extra no tienen un historyId de aviso
        if not await redis_client.exists(pending_key):
            break
    return results


__all__ = ["SYNC_GMAIL_JOB", "ArqGmailSyncQueue", "run_gmail_sync"]
