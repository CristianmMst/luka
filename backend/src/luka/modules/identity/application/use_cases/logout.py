"""Caso de uso: logout (revoca el refresh token actual, spec 009 SS2.2)."""

from uuid import UUID

from luka.modules.identity.application.ports import (
    ClockPort,
    RefreshTokenRepositoryPort,
    UnitOfWorkPort,
)
from luka.modules.identity.domain.sessions import hash_refresh_token, is_revoked


class Logout:
    """Revoca el refresh token del usuario si le pertenece; nunca falla."""

    def __init__(
        self,
        *,
        tokens: RefreshTokenRepositoryPort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._tokens = tokens
        self._clock = clock
        self._uow = uow

    async def execute(self, user_id: UUID, raw_refresh: str) -> None:
        """Revoca `raw_refresh` de forma idempotente; ignora tokens desconocidos o ajenos."""
        token = await self._tokens.get_by_hash_for_update(hash_refresh_token(raw_refresh))
        if token is None or token.user_id != user_id or is_revoked(token):
            return

        now = self._clock.now()
        await self._tokens.revoke(token.id, now)
        await self._uow.commit()
