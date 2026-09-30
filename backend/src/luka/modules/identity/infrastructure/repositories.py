"""Repositorios SQLAlchemy de identity (spec 004 SS2.1-2.2, controller ruling 1)."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.identity.domain.entities import RefreshToken, User
from luka.modules.identity.infrastructure.mappers import (
    refresh_token_entity_to_row,
    refresh_token_row_to_entity,
    user_entity_to_row,
    user_row_to_entity,
)
from luka.modules.identity.infrastructure.orm import RefreshTokenRow, UserRow


class SqlAlchemyUserRepository:
    """Implementacion SQLAlchemy de `UserRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_google_sub(self, sub: str) -> User | None:
        stmt = select(UserRow).where(UserRow.google_sub == sub)
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return user_row_to_entity(row) if row is not None else None

    async def get_by_id(self, id: UUID) -> User | None:
        row = await self._session.get(UserRow, id)
        return user_row_to_entity(row) if row is not None else None

    async def add(self, user: User) -> None:
        self._session.add(user_entity_to_row(user))
        await self._session.flush()

    async def delete(self, id: UUID) -> None:
        # CASCADE (spec 004 SS6): arrastra refresh tokens, conexion Gmail,
        # mensajes crudos y todo ledger del usuario.
        await self._session.execute(delete(UserRow).where(UserRow.id == id))

    async def update_profile(self, user: User) -> None:
        row = await self._session.get(UserRow, user.id)
        if row is None:
            return
        row.email = user.email
        row.display_name = user.display_name
        row.photo_url = user.photo_url
        row.updated_at = user.updated_at
        await self._session.flush()


class SqlAlchemyRefreshTokenRepository:
    """Implementacion SQLAlchemy de `RefreshTokenRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_hash_for_update(self, token_hash: str) -> RefreshToken | None:
        stmt = (
            select(RefreshTokenRow)
            .where(RefreshTokenRow.token_hash == token_hash)
            .with_for_update()
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return refresh_token_row_to_entity(row) if row is not None else None

    async def add(self, token: RefreshToken) -> None:
        self._session.add(refresh_token_entity_to_row(token))
        await self._session.flush()

    async def revoke(self, token_id: UUID, now: datetime) -> None:
        stmt = (
            update(RefreshTokenRow)
            .where(RefreshTokenRow.id == token_id, RefreshTokenRow.revoked_at.is_(None))
            .values(revoked_at=now)
        )
        await self._session.execute(stmt)

    async def revoke_family(self, family_id: UUID, now: datetime) -> None:
        stmt = (
            update(RefreshTokenRow)
            .where(RefreshTokenRow.family_id == family_id, RefreshTokenRow.revoked_at.is_(None))
            .values(revoked_at=now)
        )
        await self._session.execute(stmt)

    async def revoke_all_for_user(self, user_id: UUID, now: datetime) -> None:
        stmt = (
            update(RefreshTokenRow)
            .where(RefreshTokenRow.user_id == user_id, RefreshTokenRow.revoked_at.is_(None))
            .values(revoked_at=now)
        )
        await self._session.execute(stmt)
