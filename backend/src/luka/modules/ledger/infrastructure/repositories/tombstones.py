"""Repositorio SQLAlchemy de lapidas de capturas borradas (spec 004 SS3).

Toda consulta filtra por `user_id` (009 SS4), salvo la purga, que es global.
"""

from datetime import datetime
from decimal import Decimal
from typing import cast
from uuid import UUID

from sqlalchemy import CursorResult, delete, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.ledger.domain.entities import TransactionTombstone
from luka.modules.ledger.domain.enums import Bank, Channel, Direction
from luka.modules.ledger.infrastructure.orm import TransactionTombstoneRow


def _to_entity(row: TransactionTombstoneRow) -> TransactionTombstone:
    return TransactionTombstone(
        id=row.id,
        user_id=row.user_id,
        dedupe_key=row.dedupe_key,
        bank=Bank(row.bank),
        amount=row.amount,
        direction=Direction(row.direction),
        occurred_at=row.occurred_at,
        channels=frozenset(Channel(c) for c in row.channels),
        origin=row.origin,
        deleted_at=row.deleted_at,
    )


class SqlAlchemyTombstoneRepository:
    """Implementacion SQLAlchemy de `TombstoneRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def add(self, tombstone: TransactionTombstone) -> None:
        await self._session.execute(
            pg_insert(TransactionTombstoneRow).values(
                id=tombstone.id,
                user_id=tombstone.user_id,
                dedupe_key=tombstone.dedupe_key,
                bank=tombstone.bank.value,
                amount=tombstone.amount,
                direction=tombstone.direction.value,
                occurred_at=tombstone.occurred_at,
                channels=sorted(c.value for c in tombstone.channels),
                origin=tombstone.origin,
                deleted_at=tombstone.deleted_at,
            )
        )

    async def find_near(
        self,
        user_id: UUID,
        direction: Direction,
        amount: Decimal,
        since: datetime,
        until: datetime,
    ) -> list[TransactionTombstone]:
        stmt = select(TransactionTombstoneRow).where(
            TransactionTombstoneRow.user_id == user_id,
            TransactionTombstoneRow.direction == direction.value,
            TransactionTombstoneRow.amount == amount,
            TransactionTombstoneRow.occurred_at.between(since, until),
        )
        result = await self._session.execute(stmt)
        return [_to_entity(row) for row in result.scalars()]

    async def purge_older_than(self, cutoff: datetime) -> int:
        result = await self._session.execute(
            delete(TransactionTombstoneRow).where(TransactionTombstoneRow.deleted_at < cutoff)
        )
        return cast("CursorResult[object]", result).rowcount
