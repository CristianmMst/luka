"""Ports (interfaces) que la capa application de ingestion expone a infrastructure."""

from __future__ import annotations

from collections.abc import Sequence
from datetime import datetime
from typing import Protocol
from uuid import UUID

from finanzia.modules.ingestion.application.dto import BankDecision
from finanzia.modules.ingestion.domain.entities import RawMessage
from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus


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
    "IdGeneratorPort",
    "RawMessageRepositoryPort",
    "SenderPolicyPort",
    "UnitOfWorkPort",
]
