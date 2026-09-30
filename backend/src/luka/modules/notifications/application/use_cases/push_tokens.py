"""Registro, baja y purga de tokens de dispositivo (spec 011 SS6, spec 005 SS10)."""

from __future__ import annotations

from datetime import timedelta
from uuid import UUID

from luka.modules.notifications.application.ports import (
    ClockPort,
    DeviceTokenRepositoryPort,
    IdGeneratorPort,
    UnitOfWorkPort,
)
from luka.modules.notifications.domain.entities import TOKEN_MAX, Platform
from luka.modules.notifications.domain.errors import InvalidPushToken

#: Tokens sin registrarse en este tiempo se purgan (spec 004 SS6).
STALE_AFTER = timedelta(days=270)


def _clean(token: str) -> str:
    cleaned = token.strip()
    if not cleaned or len(cleaned) > TOKEN_MAX:
        raise InvalidPushToken
    return cleaned


class RegisterPushToken:
    """Upsert por token: lo asigna al usuario del JWT y renueva `last_seen_at`."""

    def __init__(
        self,
        *,
        tokens: DeviceTokenRepositoryPort,
        clock: ClockPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._tokens = tokens
        self._clock = clock
        self._ids = ids
        self._uow = uow

    async def execute(self, user_id: UUID, token: str, platform: Platform) -> None:
        await self._tokens.upsert(
            id=self._ids.new_id(),
            user_id=user_id,
            token=_clean(token),
            platform=platform,
            now=self._clock.now(),
        )
        await self._uow.commit()


class UnregisterPushToken:
    """Borra el token si es del usuario; si no existe, no pasa nada (idempotente)."""

    def __init__(self, *, tokens: DeviceTokenRepositoryPort, uow: UnitOfWorkPort) -> None:
        self._tokens = tokens
        self._uow = uow

    async def execute(self, user_id: UUID, token: str) -> None:
        await self._tokens.delete_for_user(user_id, _clean(token))
        await self._uow.commit()


class PurgeStaleTokens:
    """Cron diario: borra los tokens que la app no registra hace 270 dias."""

    def __init__(
        self, *, tokens: DeviceTokenRepositoryPort, clock: ClockPort, uow: UnitOfWorkPort
    ) -> None:
        self._tokens = tokens
        self._clock = clock
        self._uow = uow

    async def execute(self) -> int:
        removed = await self._tokens.purge_seen_before(self._clock.now() - STALE_AFTER)
        await self._uow.commit()
        return removed
