"""Repositorio SQLAlchemy de `raw_messages` (spec 004 §2.7; controller ruling 5).

`from __future__ import annotations` evita que pyright confunda el metodo `list`
builtin con el tipo `list[...]` en las anotaciones (mismo patron que
`ledger/infrastructure/repositories/transactions.py`).
"""

from __future__ import annotations

from collections.abc import Sequence
from datetime import datetime
from typing import cast
from uuid import UUID

from sqlalchemy import CursorResult, and_, delete, func, or_, select, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from finanzia.modules.ingestion.domain.entities import GmailConnection, RawMessage
from finanzia.modules.ingestion.domain.enums import (
    Channel,
    GmailConnectionStatus,
    RawMessageStatus,
)
from finanzia.modules.ingestion.infrastructure.mappers import (
    gmail_connection_entity_to_values,
    gmail_connection_row_to_entity,
    raw_message_entity_to_values,
    raw_message_row_to_entity,
)
from finanzia.modules.ingestion.infrastructure.orm import GmailConnectionRow, RawMessageRow


class SqlAlchemyRawMessageRepository:
    """Implementacion SQLAlchemy de `RawMessageRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def insert_if_absent(self, msg: RawMessage) -> UUID | None:
        stmt = (
            pg_insert(RawMessageRow)
            .values(**raw_message_entity_to_values(msg))
            .on_conflict_do_nothing(index_elements=["user_id", "channel", "external_id"])
            .returning(RawMessageRow.id)
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_external_id(
        self, user_id: UUID, channel: Channel, external_id: str
    ) -> RawMessage | None:
        stmt = select(RawMessageRow).where(
            RawMessageRow.user_id == user_id,
            RawMessageRow.channel == channel.value,
            RawMessageRow.external_id == external_id,
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return raw_message_row_to_entity(row) if row is not None else None

    async def get(self, id: UUID) -> RawMessage | None:
        stmt = select(RawMessageRow).where(RawMessageRow.id == id)
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return raw_message_row_to_entity(row) if row is not None else None

    async def get_many_for_user(self, user_id: UUID, ids: Sequence[UUID]) -> list[RawMessage]:
        if not ids:
            return []
        stmt = select(RawMessageRow).where(
            RawMessageRow.user_id == user_id, RawMessageRow.id.in_(ids)
        )
        result = await self._session.execute(stmt)
        return [raw_message_row_to_entity(row) for row in result.scalars()]

    async def set_status(self, id: UUID, status: RawMessageStatus, now: datetime) -> bool:
        stmt = (
            update(RawMessageRow)
            .where(RawMessageRow.id == id)
            .values(status=status.value, updated_at=now)
        )
        result = cast("CursorResult[tuple[()]]", await self._session.execute(stmt))
        return result.rowcount > 0

    async def purge_bodies(self, before: datetime, now: datetime) -> int:
        stmt = (
            update(RawMessageRow)
            .where(RawMessageRow.purge_after < before, RawMessageRow.body.isnot(None))
            .values(body=None, updated_at=now)
        )
        result = cast("CursorResult[tuple[()]]", await self._session.execute(stmt))
        return result.rowcount

    async def list_pending_older_than(self, before: datetime, limit: int) -> list[RawMessage]:
        stmt = (
            select(RawMessageRow)
            .where(
                RawMessageRow.status == RawMessageStatus.PENDING.value,
                RawMessageRow.updated_at < before,
            )
            .order_by(RawMessageRow.updated_at.asc())
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return [raw_message_row_to_entity(row) for row in result.scalars()]

    async def mark_requeued(self, id: UUID, now: datetime) -> None:
        stmt = (
            update(RawMessageRow)
            .where(RawMessageRow.id == id)
            .values(updated_at=now, requeue_attempts=RawMessageRow.requeue_attempts + 1)
        )
        await self._session.execute(stmt)


class SqlAlchemyGmailConnectionRepository:
    """Implementacion SQLAlchemy de la persistencia de `gmail_connections` (spec 004 §2.3)."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def upsert(self, connection: GmailConnection) -> None:
        """Inserta la conexion o, si ya existia para `user_id`, la reemplaza.

        `user_id` es PK (relacion 1:1 con `users`): reconectar Gmail tras una
        revocacion sobrescribe la fila anterior en vez de fallar por duplicado.
        `created_at` no se pisa: conserva la fecha de la primera conexion.
        """
        values = gmail_connection_entity_to_values(connection)
        stmt = pg_insert(GmailConnectionRow).values(**values)
        update_values = {k: v for k, v in values.items() if k not in {"user_id", "created_at"}}
        stmt = stmt.on_conflict_do_update(index_elements=["user_id"], set_=update_values)
        await self._session.execute(stmt)

    async def get(self, user_id: UUID) -> GmailConnection | None:
        stmt = select(GmailConnectionRow).where(GmailConnectionRow.user_id == user_id)
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return gmail_connection_row_to_entity(row) if row is not None else None

    async def delete(self, user_id: UUID, email: str | None = None) -> bool:
        stmt = delete(GmailConnectionRow).where(GmailConnectionRow.user_id == user_id)
        if email is not None:
            stmt = stmt.where(GmailConnectionRow.email == email)
        result = cast("CursorResult[tuple[()]]", await self._session.execute(stmt))
        return result.rowcount > 0

    async def list_active_user_ids_by_email(self, email: str) -> list[UUID]:
        stmt = select(GmailConnectionRow.user_id).where(
            GmailConnectionRow.email == email,
            GmailConnectionRow.status == GmailConnectionStatus.ACTIVE.value,
        )
        return list((await self._session.execute(stmt)).scalars())

    async def record_sync(self, user_id: UUID, email: str, history_id: int, now: datetime) -> None:
        """`GREATEST` en SQL: dos syncs concurrentes nunca hacen retroceder el cursor."""
        stmt = (
            update(GmailConnectionRow)
            .where(GmailConnectionRow.user_id == user_id, GmailConnectionRow.email == email)
            .values(
                history_id=func.greatest(
                    func.coalesce(GmailConnectionRow.history_id, 0), history_id
                ),
                last_sync_at=now,
                updated_at=now,
            )
        )
        await self._session.execute(stmt)

    async def mark_status(
        self, user_id: UUID, email: str, status: GmailConnectionStatus, now: datetime
    ) -> None:
        stmt = (
            update(GmailConnectionRow)
            .where(GmailConnectionRow.user_id == user_id, GmailConnectionRow.email == email)
            .values(status=status.value, updated_at=now)
        )
        await self._session.execute(stmt)

    async def list_renewable_before(self, before: datetime) -> list[GmailConnection]:
        active = GmailConnectionStatus.ACTIVE.value
        error = GmailConnectionStatus.ERROR.value
        stmt = (
            select(GmailConnectionRow)
            .where(
                or_(
                    and_(
                        GmailConnectionRow.status == active,
                        GmailConnectionRow.watch_expires_at < before,
                    ),
                    and_(
                        GmailConnectionRow.status == error,
                        or_(
                            GmailConnectionRow.watch_expires_at.is_(None),
                            GmailConnectionRow.watch_expires_at < before,
                        ),
                    ),
                )
            )
            .order_by(GmailConnectionRow.watch_expires_at.asc().nulls_first())
        )
        result = await self._session.execute(stmt)
        return [gmail_connection_row_to_entity(row) for row in result.scalars()]

    async def renew_watch(
        self, user_id: UUID, email: str, history_id: int, watch_expires_at: datetime, now: datetime
    ) -> None:
        """`COALESCE` en SQL: el `historyId` del watch solo siembra un cursor nulo;
        nunca adelanta uno existente (saltaria correo sin sincronizar, spec 006 §2.1).
        """
        stmt = (
            update(GmailConnectionRow)
            .where(GmailConnectionRow.user_id == user_id, GmailConnectionRow.email == email)
            .values(
                history_id=func.coalesce(GmailConnectionRow.history_id, history_id),
                watch_expires_at=watch_expires_at,
                status=GmailConnectionStatus.ACTIVE.value,
                updated_at=now,
            )
        )
        await self._session.execute(stmt)


__all__ = ["SqlAlchemyGmailConnectionRepository", "SqlAlchemyRawMessageRepository"]
