"""Dobles de prueba de ingestion: repos en memoria y ports fake (sin infraestructura)."""

from __future__ import annotations

import uuid
from collections.abc import Sequence
from dataclasses import replace
from datetime import datetime
from uuid import UUID

from support.clock import FixedClock

from finanzia.modules.ingestion.application.dto import BankDecision
from finanzia.modules.ingestion.domain.entities import RawMessage
from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus

__all__ = [
    "FakeSenderPolicy",
    "FixedClock",
    "InMemoryRawMessageRepo",
    "NoopUoW",
    "RecordingPublisher",
    "SequenceIdGenerator",
]


class InMemoryRawMessageRepo:
    """Doble en memoria de `RawMessageRepositoryPort`: honra `(user_id, channel,
    external_id)` como `insert_if_absent` idempotente.
    """

    def __init__(self) -> None:
        self.by_id: dict[UUID, RawMessage] = {}
        self._index: dict[tuple[UUID, str, str], UUID] = {}

    async def insert_if_absent(self, msg: RawMessage) -> UUID | None:
        key = (msg.user_id, msg.channel.value, msg.external_id)
        if key in self._index:
            return None
        self.by_id[msg.id] = msg
        self._index[key] = msg.id
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
