"""Repositorio SQLAlchemy de la cola de revision (spec 004 SS2.10; controller ruling 1)."""

from __future__ import annotations

from datetime import datetime
from typing import cast
from uuid import UUID

from sqlalchemy import CursorResult, select, tuple_, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.ledger.application.dto import Cursor
from luka.modules.ledger.domain.review import ReviewItem, ReviewReason, ReviewResolution
from luka.modules.ledger.infrastructure.orm import ReviewQueueRow


def _row_to_entity(row: ReviewQueueRow) -> ReviewItem:
    # `partial_extract` es JSONB (`dict[str, object]` en el ORM); el dominio exige
    # `Mapping[str, str]` (siempre construido asi por `EnqueueForReview`).
    partial_extract = cast("dict[str, str]", row.partial_extract)
    return ReviewItem(
        raw_message_id=row.raw_message_id,
        user_id=row.user_id,
        reason=ReviewReason(row.reason),
        partial_extract=dict(partial_extract),
        created_at=row.created_at,
        resolved_at=row.resolved_at,
        resolution=ReviewResolution(row.resolution) if row.resolution is not None else None,
    )


class SqlAlchemyReviewQueueRepository:
    """Implementacion SQLAlchemy de `ReviewQueueRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def insert_if_absent(self, item: ReviewItem) -> bool:
        stmt = (
            pg_insert(ReviewQueueRow)
            .values(
                raw_message_id=item.raw_message_id,
                user_id=item.user_id,
                reason=item.reason.value,
                partial_extract=dict(item.partial_extract),
                resolved_at=item.resolved_at,
                resolution=item.resolution.value if item.resolution is not None else None,
                created_at=item.created_at,
                updated_at=item.created_at,
            )
            .on_conflict_do_nothing(index_elements=["raw_message_id"])
        )
        result = cast("CursorResult[tuple[()]]", await self._session.execute(stmt))
        return result.rowcount == 1

    async def get(self, user_id: UUID, raw_message_id: UUID) -> ReviewItem | None:
        stmt = select(ReviewQueueRow).where(
            ReviewQueueRow.raw_message_id == raw_message_id, ReviewQueueRow.user_id == user_id
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return _row_to_entity(row) if row is not None else None

    async def list_open(self, user_id: UUID, cursor: Cursor | None, limit: int) -> list[ReviewItem]:
        stmt = select(ReviewQueueRow).where(
            ReviewQueueRow.user_id == user_id, ReviewQueueRow.resolved_at.is_(None)
        )
        if cursor is not None:
            stmt = stmt.where(
                tuple_(ReviewQueueRow.created_at, ReviewQueueRow.raw_message_id)
                < (cursor.sort_key, cursor.id)
            )
        stmt = stmt.order_by(
            ReviewQueueRow.created_at.desc(), ReviewQueueRow.raw_message_id.desc()
        ).limit(limit)
        result = await self._session.execute(stmt)
        return [_row_to_entity(row) for row in result.scalars()]

    async def resolve(
        self, user_id: UUID, raw_message_id: UUID, resolution: ReviewResolution, now: datetime
    ) -> bool:
        stmt = (
            update(ReviewQueueRow)
            .where(
                ReviewQueueRow.user_id == user_id,
                ReviewQueueRow.raw_message_id == raw_message_id,
                ReviewQueueRow.resolved_at.is_(None),
            )
            .values(resolved_at=now, resolution=resolution.value, updated_at=now)
        )
        result = cast("CursorResult[tuple[()]]", await self._session.execute(stmt))
        return result.rowcount == 1


__all__ = ["SqlAlchemyReviewQueueRepository"]
