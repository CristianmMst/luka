"""Repositorio SQLAlchemy de categorias (spec 004 SS2.8; controller ruling 1).

Las categorias del sistema (`user_id IS NULL`) son visibles para todos: toda
consulta de "visibilidad" filtra `user_id = :uid OR user_id IS NULL`.
"""

from uuid import UUID

from sqlalchemy import delete, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.ledger.domain.entities import Category
from luka.modules.ledger.infrastructure.mappers import (
    category_entity_to_row,
    category_row_to_entity,
)
from luka.modules.ledger.infrastructure.orm import CategoryRow


class SqlAlchemyCategoryRepository:
    """Implementacion SQLAlchemy de `CategoryRepositoryPort`."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_visible(self, user_id: UUID, category_id: UUID) -> Category | None:
        stmt = select(CategoryRow).where(
            CategoryRow.id == category_id,
            or_(CategoryRow.user_id == user_id, CategoryRow.user_id.is_(None)),
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return category_row_to_entity(row) if row is not None else None

    async def list_visible(self, user_id: UUID) -> list[Category]:
        stmt = (
            select(CategoryRow)
            .where(or_(CategoryRow.user_id == user_id, CategoryRow.user_id.is_(None)))
            .order_by(CategoryRow.user_id.is_(None).desc(), CategoryRow.name.asc())
        )
        result = await self._session.execute(stmt)
        return [category_row_to_entity(row) for row in result.scalars()]

    async def get_system_by_slug(self, slug: str) -> Category | None:
        stmt = select(CategoryRow).where(CategoryRow.slug == slug, CategoryRow.user_id.is_(None))
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return category_row_to_entity(row) if row is not None else None

    async def exists_name(
        self, user_id: UUID, name: str, *, exclude_id: UUID | None = None
    ) -> bool:
        stmt = (
            select(func.count())
            .select_from(CategoryRow)
            .where(
                or_(CategoryRow.user_id == user_id, CategoryRow.user_id.is_(None)),
                func.lower(CategoryRow.name) == func.lower(name),
            )
        )
        if exclude_id is not None:
            stmt = stmt.where(CategoryRow.id != exclude_id)
        count = (await self._session.execute(stmt)).scalar_one()
        return count > 0

    async def add(self, category: Category) -> None:
        self._session.add(category_entity_to_row(category))
        await self._session.flush()

    async def update(self, category: Category) -> None:
        row = await self._session.get(CategoryRow, category.id)
        if row is None or row.user_id != category.user_id:
            return
        row.name = category.name
        row.icon = category.icon
        row.color = category.color
        row.fiscal_tag = category.fiscal_tag.value
        await self._session.flush()

    async def delete(self, user_id: UUID, id: UUID) -> None:
        stmt = delete(CategoryRow).where(CategoryRow.id == id, CategoryRow.user_id == user_id)
        await self._session.execute(stmt)
