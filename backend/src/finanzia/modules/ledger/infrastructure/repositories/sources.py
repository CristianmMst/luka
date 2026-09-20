"""Repositorio SQLAlchemy de fuentes de transaccion (spec 004 SS2.6; controller ruling 1)."""

from typing import cast
from uuid import UUID

from sqlalchemy import CursorResult, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from finanzia.modules.ledger.domain.entities import TransactionSource
from finanzia.modules.ledger.infrastructure.mappers import (
    source_entity_to_values,
    source_row_to_entity,
)
from finanzia.modules.ledger.infrastructure.orm import TransactionSourceRow


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
