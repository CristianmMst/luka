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

from sqlalchemy import CursorResult, delete, select, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from finanzia.modules.ingestion.domain.entities import GmailConnection, RawMessage
from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus
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

    async def delete(self, user_id: UUID) -> bool:
        stmt = delete(GmailConnectionRow).where(GmailConnectionRow.user_id == user_id)
        result = cast("CursorResult[tuple[()]]", await self._session.execute(stmt))
        return result.rowcount > 0


__all__ = ["SqlAlchemyGmailConnectionRepository", "SqlAlchemyRawMessageRepository"]
