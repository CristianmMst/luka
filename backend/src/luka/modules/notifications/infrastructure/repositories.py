"""Repositorio SQLAlchemy de `device_tokens` (spec 004 SS2.15)."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.notifications.domain.entities import DeviceToken, Platform
from luka.modules.notifications.infrastructure.orm import DeviceTokenRow


def _entity(row: DeviceTokenRow) -> DeviceToken:
    return DeviceToken(
        id=row.id,
        user_id=row.user_id,
        token=row.token,
        platform=Platform(row.platform),
        created_at=row.created_at,
        last_seen_at=row.last_seen_at,
    )


class SqlAlchemyDeviceTokenRepository:
    """Implementacion de `DeviceTokenRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def upsert(
        self, *, id: UUID, user_id: UUID, token: str, platform: Platform, now: datetime
    ) -> None:
        stmt = insert(DeviceTokenRow).values(
            id=id, user_id=user_id, token=token, platform=platform.value, last_seen_at=now
        )
        stmt = stmt.on_conflict_do_update(
            index_elements=[DeviceTokenRow.token],
            set_={
                "user_id": stmt.excluded.user_id,
                "platform": stmt.excluded.platform,
                "last_seen_at": stmt.excluded.last_seen_at,
            },
        )
        await self._session.execute(stmt)

    async def delete_for_user(self, user_id: UUID, token: str) -> None:
        await self._session.execute(
            delete(DeviceTokenRow).where(
                DeviceTokenRow.user_id == user_id, DeviceTokenRow.token == token
            )
        )

    async def delete_token(self, token: str) -> None:
        await self._session.execute(delete(DeviceTokenRow).where(DeviceTokenRow.token == token))

    async def list_for_user(self, user_id: UUID) -> list[DeviceToken]:
        stmt = (
            select(DeviceTokenRow)
            .where(DeviceTokenRow.user_id == user_id)
            .order_by(DeviceTokenRow.last_seen_at.desc())
        )
        return [_entity(row) for row in (await self._session.execute(stmt)).scalars()]

    async def purge_seen_before(self, cutoff: datetime) -> int:
        stmt = (
            delete(DeviceTokenRow)
            .where(DeviceTokenRow.last_seen_at < cutoff)
            .returning(DeviceTokenRow.id)
        )
        return len((await self._session.execute(stmt)).scalars().all())
