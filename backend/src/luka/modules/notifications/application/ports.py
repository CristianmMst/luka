"""Ports (interfaces) que la capa application de notifications expone a infrastructure."""

from __future__ import annotations

from datetime import datetime
from typing import Protocol
from uuid import UUID

from luka.modules.notifications.domain.entities import (
    DeviceToken,
    Platform,
    PushMessage,
    SendOutcome,
)


class DeviceTokenRepositoryPort(Protocol):
    """Persistencia de `device_tokens` (spec 004 SS2.15)."""

    async def upsert(
        self, *, id: UUID, user_id: UUID, token: str, platform: Platform, now: datetime
    ) -> None:
        """Inserta o reasigna el token al usuario y actualiza `last_seen_at`."""
        ...

    async def delete_for_user(self, user_id: UUID, token: str) -> None: ...

    async def delete_token(self, token: str) -> None: ...

    async def list_for_user(self, user_id: UUID) -> list[DeviceToken]: ...

    async def purge_seen_before(self, cutoff: datetime) -> int: ...


class PushSenderPort(Protocol):
    """Envia un push a un token (FCM HTTP v1). Lanza `PushUnavailable` si hay que reintentar."""

    async def send(self, token: DeviceToken, message: PushMessage) -> SendOutcome: ...


class RecurringRemindersPort(Protocol):
    """Lo que notifications consulta o marca en recurring via `recurring.public` (R4)."""

    async def still_due(self, occurrence_id: UUID) -> bool:
        """`True` si la ocurrencia sigue `pending`, sin aviso y sin vencer."""
        ...

    async def mark_reminded(self, occurrence_id: UUID) -> bool: ...


class ClockPort(Protocol):
    """Reloj inyectado (nunca `datetime.now()` directo)."""

    def now(self) -> datetime: ...


class IdGeneratorPort(Protocol):
    """Generador de ids."""

    def new_id(self) -> UUID: ...


class UnitOfWorkPort(Protocol):
    """Confirma la transaccion de base de datos en curso."""

    async def commit(self) -> None: ...
