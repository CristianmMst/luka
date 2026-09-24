"""Dobles de prueba de ingestion: repos en memoria y ports fake (sin infraestructura)."""

from __future__ import annotations

import uuid
from collections.abc import Sequence
from dataclasses import replace
from datetime import UTC, datetime
from uuid import UUID

from support.clock import FixedClock

from finanzia.modules.ingestion.application.dto import BankDecision
from finanzia.modules.ingestion.domain.entities import GmailConnection, RawMessage
from finanzia.modules.ingestion.domain.enums import (
    Channel,
    GmailConnectionStatus,
    RawMessageStatus,
)
from finanzia.modules.ingestion.domain.errors import (
    GmailHistoryExpired,
    GmailRequestRejected,
    GmailTokenUndecryptable,
)
from finanzia.modules.ingestion.domain.gmail_message import GmailMessage, MimePart

__all__ = [
    "FakeGmailClient",
    "FakeSenderPolicy",
    "FakeTokenCipher",
    "FixedClock",
    "InMemoryGmailConnectionRepo",
    "InMemoryRawMessageRepo",
    "NoopUoW",
    "RecordingPublisher",
    "RecordingSyncQueue",
    "SequenceIdGenerator",
]


class InMemoryRawMessageRepo:
    """Doble en memoria de `RawMessageRepositoryPort`: honra `(user_id, channel,
    external_id)` como `insert_if_absent` idempotente.
    """

    #: sentinel `updated_at` para filas nunca reencoladas (`mark_requeued`): muy en
    #: el pasado, asi que por defecto siempre cuentan como huerfanas en
    #: `list_pending_older_than` hasta que un test llame `mark_requeued` explicito.
    _SENTINEL_UPDATED_AT = datetime.min.replace(tzinfo=UTC)

    def __init__(self) -> None:
        self.by_id: dict[UUID, RawMessage] = {}
        self._index: dict[tuple[UUID, str, str], UUID] = {}
        self.updated_at: dict[UUID, datetime] = {}

    async def insert_if_absent(self, msg: RawMessage) -> UUID | None:
        key = (msg.user_id, msg.channel.value, msg.external_id)
        if key in self._index:
            return None
        self.by_id[msg.id] = msg
        self._index[key] = msg.id
        self.updated_at[msg.id] = self._SENTINEL_UPDATED_AT
        return msg.id

    async def get_by_external_id(
        self, user_id: UUID, channel: Channel, external_id: str
    ) -> RawMessage | None:
        found = self._index.get((user_id, channel.value, external_id))
        return self.by_id.get(found) if found is not None else None

    async def get(self, id: UUID) -> RawMessage | None:
        return self.by_id.get(id)

    async def get_many_for_user(self, user_id: UUID, ids: Sequence[UUID]) -> list[RawMessage]:
        id_set = set(ids)
        return [m for m in self.by_id.values() if m.user_id == user_id and m.id in id_set]

    async def set_status(self, id: UUID, status: RawMessageStatus, now: datetime) -> bool:
        msg = self.by_id.get(id)
        if msg is None:
            return False
        self.by_id[id] = replace(msg, status=status)
        return True

    async def purge_bodies(self, before: datetime, now: datetime) -> int:
        del now
        count = 0
        for id, msg in list(self.by_id.items()):
            if msg.purge_after < before and msg.body is not None:
                self.by_id[id] = replace(msg, body=None)
                count += 1
        return count

    async def list_pending_older_than(self, before: datetime, limit: int) -> list[RawMessage]:
        pending = [
            msg
            for msg in self.by_id.values()
            if msg.status is RawMessageStatus.PENDING
            and self.updated_at.get(msg.id, self._SENTINEL_UPDATED_AT) < before
        ]
        pending.sort(key=lambda msg: self.updated_at.get(msg.id, self._SENTINEL_UPDATED_AT))
        return pending[:limit]

    async def mark_requeued(self, id: UUID, now: datetime) -> None:
        self.updated_at[id] = now
        msg = self.by_id.get(id)
        if msg is not None:
            self.by_id[id] = replace(msg, requeue_attempts=msg.requeue_attempts + 1)


class FakeSenderPolicy:
    """Doble de `SenderPolicyPort`: mapas fijos remitente/(paquete,canal) -> banco."""

    def __init__(
        self,
        email_map: dict[str, str] | None = None,
        notification_map: dict[tuple[str, str], BankDecision] | None = None,
    ) -> None:
        self._email_map = email_map or {}
        self._notification_map = notification_map or {}

    def bank_for_email_sender(self, sender: str) -> str | None:
        return self._email_map.get(sender)

    def bank_for_notification(self, package: str, channel: str, title: str | None) -> BankDecision:
        del title
        default = BankDecision(accepted=False, bank=None)
        return self._notification_map.get((package, channel), default)


class RecordingPublisher:
    """Doble de `EventPublisherPort`: guarda cada evento publicado para inspeccion."""

    def __init__(self) -> None:
        self.events: list[object] = []

    async def publish(self, event: object) -> None:
        self.events.append(event)


class SequenceIdGenerator:
    """Doble de `IdGeneratorPort`: ids uuid5 deterministas por contador."""

    def __init__(self) -> None:
        self._counter = 0

    def new_id(self) -> UUID:
        self._counter += 1
        return uuid.uuid5(uuid.NAMESPACE_URL, f"https://finanzia.app/test-ids/{self._counter}")


class NoopUoW:
    """Doble de `UnitOfWorkPort`: no persiste nada, solo cuenta los commits."""

    def __init__(self) -> None:
        self.commits = 0

    async def commit(self) -> None:
        self.commits += 1


class InMemoryGmailConnectionRepo:
    """Doble de `GmailConnectionRepositoryPort`: un dict por `user_id`.

    Igual que el adapter SQL, `upsert` conserva el `created_at` de la fila previa.
    """

    def __init__(self) -> None:
        self.by_user: dict[UUID, GmailConnection] = {}

    async def upsert(self, connection: GmailConnection) -> None:
        previous = self.by_user.get(connection.user_id)
        if previous is not None:
            connection = replace(connection, created_at=previous.created_at)
        self.by_user[connection.user_id] = connection

    async def get(self, user_id: UUID) -> GmailConnection | None:
        return self.by_user.get(user_id)

    async def delete(self, user_id: UUID) -> bool:
        return self.by_user.pop(user_id, None) is not None

    async def list_active_user_ids_by_email(self, email: str) -> list[UUID]:
        return [
            c.user_id
            for c in self.by_user.values()
            if c.email == email and c.status is GmailConnectionStatus.ACTIVE
        ]

    async def record_sync(self, user_id: UUID, email: str, history_id: int, now: datetime) -> None:
        current = self.by_user.get(user_id)
        if current is None or current.email != email:
            return
        cursor = max(current.history_id or 0, history_id)
        self.by_user[user_id] = replace(
            current, history_id=cursor, last_sync_at=now, updated_at=now
        )

    async def mark_status(
        self, user_id: UUID, email: str, status: GmailConnectionStatus, now: datetime
    ) -> None:
        current = self.by_user.get(user_id)
        if current is None or current.email != email:
            return
        self.by_user[user_id] = replace(current, status=status, updated_at=now)


class RecordingSyncQueue:
    """Doble de `GmailSyncQueuePort`: guarda `(user_id, history_id)` de cada job encolado."""

    def __init__(self) -> None:
        self.jobs: list[tuple[UUID, int | None]] = []
        self.error: Exception | None = None

    async def enqueue_sync(self, user_id: UUID, history_id: int | None) -> None:
        if self.error is not None:
            raise self.error
        self.jobs.append((user_id, history_id))


class FakeTokenCipher:
    """Doble reversible de `TokenCipherPort`: `user_id|token` en claro, atado al usuario."""

    def encrypt(self, user_id: UUID, plaintext: str) -> bytes:
        return f"{user_id}|{plaintext}".encode()

    def decrypt(self, user_id: UUID, blob: bytes) -> str:
        prefix = f"{user_id}|"
        decoded = blob.decode(errors="replace")
        if not decoded.startswith(prefix):
            raise GmailTokenUndecryptable
        return decoded[len(prefix) :]


class FakeGmailClient:
    """Doble de `GmailClientPort`: respuestas fijas y errores inyectables por metodo.

    `errors["watch"] = GmailTransientError(...)` hace fallar esa operacion; `calls`
    registra `(operacion, argumento)` en orden para las aserciones.
    """

    def __init__(
        self,
        *,
        refresh_token: str = "refresh-1",  # noqa: S107 - valor de prueba
        email: str = "ana@gmail.com",
        history_id: int = 4242,
        watch_expires_at: datetime | None = None,
    ) -> None:
        self.refresh_token = refresh_token
        self.email = email
        self.history_id = history_id
        self.watch_expires_at = watch_expires_at or datetime(2026, 5, 8, 12, 0, tzinfo=UTC)
        self.errors: dict[str, Exception] = {}
        self.calls: list[tuple[str, str]] = []
        #: Buzon falso: `history` = ids nuevos por `start_history_id`; `messages` por id.
        self.mailbox_history_id = history_id
        self.history: dict[int, list[str]] = {}
        self.recent: list[str] = []
        self.messages: dict[str, GmailMessage] = {}

    def _record(self, operation: str, argument: str) -> None:
        self.calls.append((operation, argument))
        error = self.errors.get(operation)
        if error is not None:
            raise error

    async def exchange_code(self, code: str) -> tuple[str, str]:
        self._record("exchange_code", code)
        return self.refresh_token, self.email

    async def access_token(self, refresh_token: str) -> str:
        self._record("access_token", refresh_token)
        return f"access-for-{refresh_token}"

    async def watch(self, access_token: str, topic: str) -> tuple[int, datetime]:
        self._record("watch", topic)
        return self.history_id, self.watch_expires_at

    async def stop(self, access_token: str) -> None:
        self._record("stop", access_token)

    async def revoke(self, refresh_token: str) -> None:
        self._record("revoke", refresh_token)

    async def history_new_message_ids(
        self, access_token: str, start_history_id: int
    ) -> tuple[list[str], int]:
        self._record("history", str(start_history_id))
        if start_history_id not in self.history:
            raise GmailHistoryExpired("history.list: 404")
        return list(self.history[start_history_id]), self.mailbox_history_id

    async def recent_message_ids(
        self, access_token: str, days: int = 7, limit: int = 500
    ) -> list[str]:
        self._record("recent", f"{days}d/{limit}")
        return self.recent[:limit]

    async def profile_history_id(self, access_token: str) -> int:
        self._record("profile_history_id", access_token)
        return self.mailbox_history_id

    async def get_message(self, access_token: str, message_id: str) -> GmailMessage:
        self._record("get_message", message_id)
        message = self.messages.get(message_id)
        if message is None:
            raise GmailRequestRejected("messages.get: 404")
        return message

    def add_message(
        self, message_id: str, sender: str, text: str, received_at: datetime | None = None
    ) -> GmailMessage:
        """Agrega un mensaje `text/plain` al buzon falso."""
        message = GmailMessage(
            id=message_id,
            sender=sender,
            internal_date=received_at or datetime(2026, 5, 1, 12, 0, tzinfo=UTC),
            payload=MimePart(mime_type="text/plain", data=text.encode(), charset="utf-8"),
        )
        self.messages[message_id] = message
        return message
