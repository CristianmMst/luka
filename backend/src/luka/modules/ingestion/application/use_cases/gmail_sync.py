"""Aviso push de Gmail y sincronizacion por history (F3.4, spec 005 §4 y 006 §2.1).

`HandleGmailPush` resuelve la cuenta del aviso y encola un `sync_gmail` por cada
conexion activa. `SyncGmail` hace una pasada: lista los mensajes nuevos desde el
cursor (o resync de 7 dias si el cursor vencio), ingiere cada uno con
`IngestRawMessage` (filtro de remitentes e idempotencia por `external_id`) y
avanza el cursor solo hacia adelante.

Nunca se espera a Google con una transaccion abierta: la conexion se lee y la
transaccion se cierra antes de la primera llamada; cada ingesta confirma la suya
y la escritura final del cursor corre en una nueva.
"""

from __future__ import annotations

from uuid import UUID

from luka.modules.ingestion.application.dto import (
    Accepted,
    Discarded,
    GmailSyncResult,
    RawMessageInput,
)
from luka.modules.ingestion.application.ports import (
    ClockPort,
    GmailClientPort,
    GmailConnectionRepositoryPort,
    GmailSyncQueuePort,
    RawMessageIngestPort,
    TokenCipherPort,
    UnitOfWorkPort,
)
from luka.modules.ingestion.domain.entities import GmailConnection
from luka.modules.ingestion.domain.enums import Channel, GmailConnectionStatus
from luka.modules.ingestion.domain.errors import (
    GmailAuthRevoked,
    GmailHistoryExpired,
    GmailMessageNotFound,
    GmailMessageUnreadable,
    GmailRequestRejected,
    GmailTokenUndecryptable,
)
from luka.modules.ingestion.domain.gmail_push import GmailPushNotification

RESYNC_DAYS = 7
RESYNC_MAX_MESSAGES = 500


class HandleGmailPush:
    """Encola `sync_gmail` para cada conexion activa de la cuenta del aviso.

    Devuelve cuantos jobs encolo (0 si la cuenta es desconocida o no esta activa:
    el webhook responde 204 igual para que Pub/Sub no reintente).
    """

    def __init__(
        self,
        *,
        repo: GmailConnectionRepositoryPort,
        queue: GmailSyncQueuePort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._repo = repo
        self._queue = queue
        self._uow = uow

    async def execute(self, notification: GmailPushNotification) -> int:
        user_ids = await self._repo.list_active_user_ids_by_email(notification.email_address)
        await self._uow.commit()  # cierra la lectura antes de ir a Redis
        for user_id in user_ids:
            await self._queue.enqueue_sync(user_id, notification.history_id)
        return len(user_ids)


class SyncGmail:
    """Una pasada de sincronizacion de la conexion Gmail de un usuario (spec 006 §2.1).

    - `GmailAuthRevoked` (refresh token revocado) marca la conexion `revoked`.
    - `GmailTransientError` se propaga sin tocar el cursor: el job se reintenta y
      la ingesta es idempotente, asi que repetir mensajes no duplica nada.
    - `GmailRequestRejected` permanente en `access_token`/`history.list` (p. ej.
      `invalid_client`) marca la conexion `error`, sin propagar (nada que
      reintentar).
    - En `messages.get` solo se saltan `GmailMessageNotFound` (mensaje borrado) y
      `GmailMessageUnreadable` (2xx ilegible); cualquier otro `GmailRequestRejected`
      corta la pasada sin avanzar el cursor.
    """

    def __init__(  # noqa: PLR0913 - un parametro por port + la config del resync
        self,
        *,
        repo: GmailConnectionRepositoryPort,
        gmail: GmailClientPort,
        cipher: TokenCipherPort,
        ingest: RawMessageIngestPort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
        resync_days: int = RESYNC_DAYS,
        resync_limit: int = RESYNC_MAX_MESSAGES,
    ) -> None:
        self._repo = repo
        self._gmail = gmail
        self._cipher = cipher
        self._ingest = ingest
        self._clock = clock
        self._uow = uow
        self._resync_days = resync_days
        self._resync_limit = resync_limit

    async def execute(  # noqa: PLR0911 - un return por rama de estado (revoked/error/etc.)
        self, user_id: UUID, notified_history_id: int | None = None
    ) -> GmailSyncResult:
        connection = await self._repo.get(user_id)
        await self._uow.commit()  # no esperar a Google con la transaccion abierta
        if connection is None:
            return GmailSyncResult("no_connection")
        if connection.status is not GmailConnectionStatus.ACTIVE:
            return GmailSyncResult("inactive")
        cursor = connection.history_id
        if cursor is not None and notified_history_id is not None and notified_history_id <= cursor:
            return GmailSyncResult("up_to_date")

        try:
            refresh_token = self._cipher.decrypt(user_id, connection.refresh_token_enc)
        except GmailTokenUndecryptable:
            await self._mark(connection, GmailConnectionStatus.ERROR)
            return GmailSyncResult("undecryptable")

        try:
            access_token = await self._gmail.access_token(refresh_token)
            message_ids, new_cursor, resync = await self._list_new(access_token, cursor)
        except GmailAuthRevoked:
            await self._mark(connection, GmailConnectionStatus.REVOKED)
            return GmailSyncResult("revoked")
        except GmailRequestRejected:
            # Rechazo permanente de `access_token`/`history.list` (p. ej.
            # `invalid_client`): reintentar no lo arregla, asi que la conexion pasa
            # a `error` en vez de dejar que el job se propague y arq lo reintente
            # sin motivo (carry-in Task 5, controller ruling).
            await self._mark(connection, GmailConnectionStatus.ERROR)
            return GmailSyncResult("error")

        result = await self._ingest_all(connection, access_token, message_ids, resync=resync)
        await self._repo.record_sync(
            user_id, connection.email, max(cursor or 0, new_cursor), self._clock.now()
        )
        await self._uow.commit()
        return result

    async def _list_new(self, access_token: str, cursor: int | None) -> tuple[list[str], int, bool]:
        """`(ids, cursor nuevo, hubo resync)`: history desde `cursor` o, si vencio
        (o nunca hubo), los mensajes recientes de INBOX.
        """
        if cursor is not None:
            try:
                ids, history_id = await self._gmail.history_new_message_ids(access_token, cursor)
            except GmailHistoryExpired:
                pass
            else:
                return ids, history_id, False
        # El historyId se pide antes de listar: lo que llegue entre ambas llamadas
        # entra en el proximo history.list (y la ingesta idempotente absorbe el solape).
        history_id = await self._gmail.profile_history_id(access_token)
        ids = await self._gmail.recent_message_ids(
            access_token, self._resync_days, self._resync_limit
        )
        return ids, history_id, True

    async def _ingest_all(
        self,
        connection: GmailConnection,
        access_token: str,
        message_ids: list[str],
        *,
        resync: bool,
    ) -> GmailSyncResult:
        accepted = duplicates = discarded = skipped = 0
        for message_id in message_ids:
            try:
                message = await self._gmail.get_message(access_token, message_id)
            except (GmailMessageNotFound, GmailMessageUnreadable):
                # Se saltan el 404 (mensaje borrado) y la respuesta 2xx ilegible (no
                # tiene arreglo y bloquearia el cursor); una cuota (403) es
                # `GmailTransientError` y cualquier otro 4xx se propaga sin avanzar.
                skipped += 1
                continue
            outcome = await self._ingest.execute(
                RawMessageInput(
                    user_id=connection.user_id,
                    channel=Channel.EMAIL,
                    external_id=message.id,
                    sender=message.sender_address,
                    title=None,
                    text=message.body(),
                    received_at=message.internal_date,
                )
            )
            if isinstance(outcome, Accepted):
                accepted += 1
            elif isinstance(outcome, Discarded):
                discarded += 1
            else:
                duplicates += 1
        return GmailSyncResult(
            "synced",
            resync=resync,
            fetched=len(message_ids),
            accepted=accepted,
            duplicates=duplicates,
            discarded=discarded,
            skipped=skipped,
        )

    async def _mark(self, connection: GmailConnection, status: GmailConnectionStatus) -> None:
        await self._repo.mark_status(
            connection.user_id, connection.email, status, self._clock.now()
        )
        await self._uow.commit()


__all__ = ["RESYNC_DAYS", "RESYNC_MAX_MESSAGES", "HandleGmailPush", "SyncGmail"]
