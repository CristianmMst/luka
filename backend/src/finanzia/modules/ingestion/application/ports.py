"""Ports (interfaces) que la capa application de ingestion expone a infrastructure."""

from __future__ import annotations

from collections.abc import Sequence
from datetime import datetime
from typing import Protocol
from uuid import UUID

from finanzia.modules.ingestion.application.dto import BankDecision
from finanzia.modules.ingestion.domain.entities import RawMessage
from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus
from finanzia.modules.ingestion.domain.gmail_message import GmailMessage


class RawMessageRepositoryPort(Protocol):
    """Persistencia de mensajes crudos (spec 004 §2.7, idempotencia spec 006 §4.4)."""

    async def insert_if_absent(self, msg: RawMessage) -> UUID | None:
        """Inserta `msg`; `None` si `(user_id, channel, external_id)` ya existia."""
        ...

    async def get_by_external_id(
        self, user_id: UUID, channel: Channel, external_id: str
    ) -> RawMessage | None:
        """La fila existente para la clave de idempotencia, o `None` si no existe."""
        ...

    async def get(self, id: UUID) -> RawMessage | None:
        """Mensaje crudo por id, o `None` si no existe."""
        ...

    async def get_many_for_user(self, user_id: UUID, ids: Sequence[UUID]) -> list[RawMessage]:
        """Mensajes propios del usuario cuyo id este en `ids` (revision, spec 004 §2.10)."""
        ...

    async def set_status(self, id: UUID, status: RawMessageStatus, now: datetime) -> bool:
        """Actualiza `status`/`updated_at`; `True` si existia una fila para `id`."""
        ...

    async def purge_bodies(self, before: datetime, now: datetime) -> int:
        """Pone `body=NULL` en las filas con `purge_after < before` y `body` aun
        presente; devuelve la cantidad de filas afectadas (spec 004 §6).
        """
        ...

    async def list_pending_older_than(self, before: datetime, limit: int) -> list[RawMessage]:
        """Filas `status='pending'` con `updated_at < before`, mas antiguas primero
        (cron `requeue_pending_raw_messages`, riesgo 4 / D9: cierra el hueco
        "commit ok + publish fallo" sin outbox).
        """
        ...

    async def mark_requeued(self, id: UUID, now: datetime) -> None:
        """Actualiza `updated_at` (sin tocar `status`) e incrementa `requeue_attempts`.

        Lo primero evita republicar la misma fila en cada corrida del cron dentro
        de la misma ventana; lo segundo acota cuantas veces se republica en total
        (riesgo 4 / D9).
        """
        ...


class SenderPolicyPort(Protocol):
    """Allowlists de remitentes/paquetes de captura, delegadas en `parsing.public` (D6)."""

    def bank_for_email_sender(self, sender: str) -> str | None:
        """Banco cuyo remitente/dominio matchea `sender`, o `None` si ninguno (AC-2.4)."""
        ...

    def bank_for_notification(self, package: str, channel: str, title: str | None) -> BankDecision:
        """Decide si una notificacion/SMS se acepta y con que banco (spec 006 §3.2)."""
        ...


class EventPublisherPort(Protocol):
    """Publicacion de eventos de dominio (`finanzia.modules.ingestion.events`)."""

    async def publish(self, event: object) -> None: ...


class GmailClientPort(Protocol):
    """Google OAuth + Gmail API (spec 006 §2, spec 005 §3/§4).

    Errores (dominio, `ingestion.domain.errors`): `GmailAuthRevoked` ante
    `invalid_grant`, `GmailHistoryExpired` ante el 404 de `history.list`,
    `GmailTransientError` ante timeout/red/5xx/429 (reintentable) y
    `GmailRequestRejected` ante cualquier otro rechazo o respuesta ilegible.
    Ningun metodo loguea tokens, codigos, emails ni contenido de mensajes.
    """

    async def exchange_code(self, code: str) -> tuple[str, str]:
        """Canjea un `serverAuthCode` por `(refresh_token, email de la cuenta Gmail)`."""
        ...

    async def access_token(self, refresh_token: str) -> str:
        """Access token de corta vida a partir del refresh token."""
        ...

    async def watch(self, access_token: str, topic: str) -> tuple[int, datetime]:
        """`users.watch` sobre INBOX hacia `topic` → `(history_id, expires_at aware UTC)`."""
        ...

    async def stop(self, access_token: str) -> None:
        """`users.stop`: deja de recibir avisos push."""
        ...

    async def revoke(self, refresh_token: str) -> None:
        """Revoca el refresh token en Google (idempotente si ya era invalido)."""
        ...

    async def history_new_message_ids(
        self, access_token: str, start_history_id: int
    ) -> tuple[list[str], int]:
        """Ids de mensajes agregados desde `start_history_id` (todas las paginas, sin
        repetir, en orden) y el `historyId` actual del buzon.
        """
        ...

    async def recent_message_ids(self, access_token: str, days: int = 7) -> list[str]:
        """Ids de los mensajes de los ultimos `days` dias (resync, spec 006 §2.1)."""
        ...

    async def get_message(self, access_token: str, message_id: str) -> GmailMessage:
        """Mensaje completo (`format=full`): remitente, `internalDate` y partes MIME."""
        ...


class ClockPort(Protocol):
    """Fuente de tiempo inyectable (siempre aware, UTC)."""

    def now(self) -> datetime: ...


class IdGeneratorPort(Protocol):
    """Generacion de identificadores."""

    def new_id(self) -> UUID: ...


class UnitOfWorkPort(Protocol):
    """Confirma los cambios acumulados en la unidad de trabajo actual."""

    async def commit(self) -> None: ...


__all__ = [
    "ClockPort",
    "EventPublisherPort",
    "GmailClientPort",
    "IdGeneratorPort",
    "RawMessageRepositoryPort",
    "SenderPolicyPort",
    "UnitOfWorkPort",
]
