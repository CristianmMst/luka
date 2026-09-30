"""API publica de ingestion: unico punto de entrada para otros modulos.

`ingest_raw_message`/`ingest_notifications_batch` son la fachada que usaran el
webhook de Gmail y `POST /v1/ingest/notifications` (Fase 3/F4.3) sin conocer los
adapters SQLAlchemy de ingestion. `get_raw_message_for_parsing` es como `parsing`
lee el cuerpo de un mensaje ya persistido (D2: el evento `RawMessageReceived`
solo lleva ids). `run_gmail_sync` es el cuerpo del job `sync_gmail` del worker
(F3.4) y `gmail_connection_status` lo que lee identity para `GET /v1/me`.
"""

from __future__ import annotations

from datetime import timedelta
from typing import TYPE_CHECKING
from uuid import UUID

from luka.modules.ingestion.application.dto import (
    GMAIL_DISCONNECTED,
    Accepted,
    BatchResult,
    Discarded,
    Duplicate,
    GmailSyncResult,
    IngestOutcome,
    NotificationItemInput,
    RawMessageInput,
    RawMessageView,
    RenewWatchesSummary,
    ReparseSummary,
    RequeueSummary,
)
from luka.modules.ingestion.application.ports import GmailClientPort
from luka.modules.ingestion.application.use_cases.gmail_connection import (
    DisconnectGmail,
    GetGmailStatus,
)
from luka.modules.ingestion.application.use_cases.ingest_notifications_batch import (
    IngestNotificationsBatch,
)
from luka.modules.ingestion.application.use_cases.ingest_raw_message import IngestRawMessage
from luka.modules.ingestion.application.use_cases.mark_raw_message import MarkRawMessage
from luka.modules.ingestion.application.use_cases.purge_bodies import PurgeExpiredBodies
from luka.modules.ingestion.application.use_cases.renew_gmail_watches import RenewGmailWatches
from luka.modules.ingestion.application.use_cases.reparse_failed import (
    ReparseFailedRawMessages,
)
from luka.modules.ingestion.application.use_cases.requeue_pending import (
    RequeuePendingRawMessages,
)
from luka.modules.ingestion.domain.entities import RawMessage
from luka.modules.ingestion.domain.enums import RawMessageStatus
from luka.modules.ingestion.domain.errors import GmailTransientError
from luka.modules.ingestion.events import RawMessageReceived
from luka.modules.ingestion.infrastructure.event_publisher import BusEventPublisher
from luka.modules.ingestion.infrastructure.gmail_sync import run_gmail_sync
from luka.modules.ingestion.infrastructure.id_generator import SecretsIdGenerator
from luka.modules.ingestion.infrastructure.logging import log_ingest_outcome
from luka.modules.ingestion.infrastructure.repositories import (
    SqlAlchemyGmailConnectionRepository,
    SqlAlchemyRawMessageRepository,
)
from luka.modules.ingestion.infrastructure.sender_policy import ParsingSenderPolicy
from luka.modules.ingestion.infrastructure.token_cipher import AesGcmTokenCipher
from luka.modules.ingestion.infrastructure.uow import SqlAlchemyUnitOfWork

if TYPE_CHECKING:
    from collections.abc import Sequence
    from datetime import datetime

    from sqlalchemy.ext.asyncio import AsyncSession

    from luka.modules.ingestion.application.ports import ClockPort
    from luka.shared.events.port import EventBusPort
    from luka.shared.settings import Settings

__all__ = [
    "Accepted",
    "BatchResult",
    "Discarded",
    "Duplicate",
    "GmailClientPort",
    "GmailSyncResult",
    "GmailTransientError",
    "IngestOutcome",
    "NotificationItemInput",
    "RawMessageInput",
    "RawMessageReceived",
    "RawMessageView",
    "RenewWatchesSummary",
    "ReparseSummary",
    "RequeueSummary",
    "disconnect_gmail",
    "get_raw_message_for_parsing",
    "gmail_connection_status",
    "ingest_notifications_batch",
    "ingest_raw_message",
    "load_raw_messages_for_review",
    "mark_raw_message",
    "purge_expired_bodies",
    "renew_gmail_watches",
    "reparse_failed_raw_messages",
    "requeue_pending_raw_messages",
    "run_gmail_sync",
]

_RETENTION_DAYS_DEFAULT = 90
_BODY_MAX_BYTES_DEFAULT = 8192
_REQUEUE_OLDER_THAN_DEFAULT = timedelta(minutes=10)
_REQUEUE_LIMIT_DEFAULT = 500
_REPARSE_LIMIT_DEFAULT = 500


def _view(msg: RawMessage) -> RawMessageView:
    return RawMessageView(
        id=msg.id,
        user_id=msg.user_id,
        channel=msg.channel,
        bank=msg.bank,
        sender=msg.sender,
        body=msg.body,
        status=msg.status,
        received_at=msg.received_at,
    )


def _build_ingest(
    session: AsyncSession,
    event_bus: EventBusPort,
    clock: ClockPort,
    *,
    retention_days: int,
    body_max_bytes: int,
) -> IngestRawMessage:
    return IngestRawMessage(
        repo=SqlAlchemyRawMessageRepository(session),
        policy=ParsingSenderPolicy(),
        events=BusEventPublisher(event_bus),
        clock=clock,
        ids=SecretsIdGenerator(),
        uow=SqlAlchemyUnitOfWork(session),
        retention_days=retention_days,
        body_max_bytes=body_max_bytes,
    )


async def ingest_raw_message(  # noqa: PLR0913 - un parametro por dependencia externa + config
    session: AsyncSession,
    event_bus: EventBusPort,
    clock: ClockPort,
    input: RawMessageInput,
    *,
    retention_days: int = _RETENTION_DAYS_DEFAULT,
    body_max_bytes: int = _BODY_MAX_BYTES_DEFAULT,
) -> IngestOutcome:
    """Ingesta un mensaje crudo sobre `session` (spec 006 §2.2-2.3, §4.4, D9).

    El llamador controla el ciclo de vida de `session` (scope, cierre), igual
    que las demas fachadas de modulo. Registra una metrica de resultado
    (`parsing_metric`, infra) sin loguear datos crudos del mensaje (P1/P6).
    """
    use_case = _build_ingest(
        session, event_bus, clock, retention_days=retention_days, body_max_bytes=body_max_bytes
    )
    outcome = await use_case.execute(input)
    log_ingest_outcome(outcome, input.channel.value)
    return outcome


async def ingest_notifications_batch(  # noqa: PLR0913 - un parametro por dependencia externa + config
    session: AsyncSession,
    event_bus: EventBusPort,
    clock: ClockPort,
    user_id: UUID,
    items: Sequence[NotificationItemInput],
    *,
    retention_days: int = _RETENTION_DAYS_DEFAULT,
    body_max_bytes: int = _BODY_MAX_BYTES_DEFAULT,
) -> BatchResult:
    """Ingesta un batch de notificaciones/SMS (spec 006 §3.2, F4.3): un item
    invalido no anula el resto (commit por item, dentro de `IngestRawMessage`).
    """
    ingest = _build_ingest(
        session, event_bus, clock, retention_days=retention_days, body_max_bytes=body_max_bytes
    )
    batch = IngestNotificationsBatch(ingest=ingest)
    return await batch.execute(user_id, items)


async def get_raw_message_for_parsing(
    session: AsyncSession, raw_message_id: UUID
) -> RawMessageView | None:
    """El mensaje crudo (con su cuerpo, si aun no fue purgado) que `parsing` lee
    tras recibir `RawMessageReceived` (D2).
    """
    repo = SqlAlchemyRawMessageRepository(session)
    msg = await repo.get(raw_message_id)
    return _view(msg) if msg is not None else None


async def mark_raw_message(
    session: AsyncSession, raw_message_id: UUID, status: str, now: datetime
) -> bool:
    """Actualiza el estado de un mensaje crudo; no comitea (el llamador controla
    la transaccion, D8).
    """
    use_case = MarkRawMessage(repo=SqlAlchemyRawMessageRepository(session))
    return await use_case.execute(raw_message_id, RawMessageStatus(status), now)


async def load_raw_messages_for_review(
    session: AsyncSession, user_id: UUID, ids: Sequence[UUID]
) -> dict[UUID, RawMessageView]:
    """Vistas de mensajes crudos propios del usuario, indexadas por id (spec 004 §2.10)."""
    repo = SqlAlchemyRawMessageRepository(session)
    messages = await repo.get_many_for_user(user_id, ids)
    return {msg.id: _view(msg) for msg in messages}


async def purge_expired_bodies(session: AsyncSession, now: datetime) -> int:
    """Pone `body=NULL` en las filas vencidas; comitea (job de purga, F3.7)."""
    use_case = PurgeExpiredBodies(
        repo=SqlAlchemyRawMessageRepository(session), uow=SqlAlchemyUnitOfWork(session)
    )
    return await use_case.execute(now)


async def requeue_pending_raw_messages(
    session: AsyncSession,
    event_bus: EventBusPort,
    clock: ClockPort,
    *,
    older_than: timedelta = _REQUEUE_OLDER_THAN_DEFAULT,
    limit: int = _REQUEUE_LIMIT_DEFAULT,
) -> RequeueSummary:
    """Republica `RawMessageReceived` para filas `pending` huerfanas (riesgo 4, D9);
    comitea (job cron cada 15 min).

    Las filas que ya se republicaron demasiadas veces pasan a `failed` en vez de
    reencolarse otra vez (ver `RequeuePendingRawMessages`).
    """
    use_case = RequeuePendingRawMessages(
        repo=SqlAlchemyRawMessageRepository(session),
        events=BusEventPublisher(event_bus),
        clock=clock,
        ids=SecretsIdGenerator(),
        uow=SqlAlchemyUnitOfWork(session),
    )
    return await use_case.execute(older_than=older_than, limit=limit)


async def reparse_failed_raw_messages(  # noqa: PLR0913 - un parametro por dependencia externa + filtros
    session: AsyncSession,
    event_bus: EventBusPort,
    clock: ClockPort,
    *,
    user_id: UUID | None = None,
    since: datetime | None = None,
    limit: int = _REPARSE_LIMIT_DEFAULT,
) -> ReparseSummary:
    """Devuelve a `pending` los `raw_messages` `failed` con cuerpo y republica su
    `RawMessageReceived` (spec 005 §7, CLI `luka.tools.reparse`); comitea.
    """
    use_case = ReparseFailedRawMessages(
        repo=SqlAlchemyRawMessageRepository(session),
        events=BusEventPublisher(event_bus),
        clock=clock,
        ids=SecretsIdGenerator(),
        uow=SqlAlchemyUnitOfWork(session),
    )
    return await use_case.execute(user_id=user_id, since=since, limit=limit)


async def renew_gmail_watches(
    session: AsyncSession, gmail: GmailClientPort, clock: ClockPort, settings: Settings
) -> RenewWatchesSummary:
    """Renueva los watches de Gmail por vencer (cron diario, spec 006 §2.1, F3.5);
    comitea. Un fallo en una conexion nunca corta las demas (ver `RenewGmailWatches`).
    """
    use_case = RenewGmailWatches(
        repo=SqlAlchemyGmailConnectionRepository(session),
        gmail=gmail,
        cipher=AesGcmTokenCipher.from_settings(settings),
        clock=clock,
        uow=SqlAlchemyUnitOfWork(session),
        topic=settings.gmail_pubsub_topic,
    )
    return await use_case.execute()


async def gmail_connection_status(session: AsyncSession, user_id: UUID) -> str:
    """Estado de la conexion Gmail para `GET /v1/me` (spec 005 §2): `active`,
    `revoked`, `error` o `none` si el usuario no tiene conexion. No comitea.
    """
    view = await GetGmailStatus(repo=SqlAlchemyGmailConnectionRepository(session)).execute(user_id)
    return "none" if view.status == GMAIL_DISCONNECTED else view.status


async def disconnect_gmail(
    session: AsyncSession, gmail: GmailClientPort, settings: Settings, user_id: UUID
) -> None:
    """Para el watch, revoca el grant en Google (best effort) y borra la
    conexion; comitea. Lo usa identity al borrar la cuenta (RF-11.3)."""
    await DisconnectGmail(
        repo=SqlAlchemyGmailConnectionRepository(session),
        gmail=gmail,
        cipher=AesGcmTokenCipher.from_settings(settings),
        uow=SqlAlchemyUnitOfWork(session),
    ).execute(user_id)
