"""Repositorio SQLAlchemy de fuentes de transaccion (spec 004 SS2.6; controller ruling 1)."""

from collections.abc import Sequence
from typing import cast
from uuid import UUID

from sqlalchemy import CursorResult, delete, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.ledger.domain.entities import TransactionSource
from luka.modules.ledger.domain.enums import Channel
from luka.modules.ledger.infrastructure.mappers import (
    source_entity_to_values,
    source_row_to_entity,
)
from luka.modules.ledger.infrastructure.orm import TransactionSourceRow


class SqlAlchemyTransactionSourceRepository:
    """Implementacion SQLAlchemy de `TransactionSourceRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def attach(self, source: TransactionSource) -> bool:
        values = source_entity_to_values(source)
        if source.raw_message_id is None:
            # Sin `raw_message_id` no hay indice unico parcial que aplique: insert simple.
            await self._session.execute(pg_insert(TransactionSourceRow).values(**values))
            return True

        stmt = (
            pg_insert(TransactionSourceRow)
            .values(**values)
            .on_conflict_do_nothing(
                index_elements=["transaction_id", "raw_message_id"],
                index_where=TransactionSourceRow.raw_message_id.isnot(None),
            )
        )
        result = cast("CursorResult[tuple[()]]", await self._session.execute(stmt))
        return result.rowcount == 1

    async def list_for(self, transaction_id: UUID) -> list[TransactionSource]:
        stmt = (
            select(TransactionSourceRow)
            .where(TransactionSourceRow.transaction_id == transaction_id)
            .order_by(TransactionSourceRow.received_at.asc(), TransactionSourceRow.id.asc())
        )
        result = await self._session.execute(stmt)
        return [source_row_to_entity(row) for row in result.scalars()]

    async def detach(self, transaction_id: UUID, raw_message_id: UUID) -> bool:
        stmt = delete(TransactionSourceRow).where(
            TransactionSourceRow.transaction_id == transaction_id,
            TransactionSourceRow.raw_message_id == raw_message_id,
        )
        result = cast("CursorResult[tuple[()]]", await self._session.execute(stmt))
        return result.rowcount > 0

    async def transaction_id_for_raw_message(self, raw_message_id: UUID) -> UUID | None:
        stmt = (
            select(TransactionSourceRow.transaction_id)
            .where(TransactionSourceRow.raw_message_id == raw_message_id)
            .limit(1)
        )
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def channels_for(self, ids: Sequence[UUID]) -> dict[UUID, list[Channel]]:
        if not ids:
            return {}
        stmt = (
            select(TransactionSourceRow.transaction_id, TransactionSourceRow.channel)
            .where(TransactionSourceRow.transaction_id.in_(ids))
            .group_by(TransactionSourceRow.transaction_id, TransactionSourceRow.channel)
        )
        result = await self._session.execute(stmt)
        channels_by_tx: dict[UUID, list[Channel]] = {}
        for transaction_id, channel in result.all():
            channels_by_tx.setdefault(transaction_id, []).append(Channel(channel))
        return channels_by_tx
