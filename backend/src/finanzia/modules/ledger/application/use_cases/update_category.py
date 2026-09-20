"""Caso de uso: editar una categoria propia (spec 005 SS7)."""

from dataclasses import replace
from uuid import UUID

from finanzia.modules.ledger.application.dto import UNSET, CategoryPatch
from finanzia.modules.ledger.application.ports import CategoryRepositoryPort, UnitOfWorkPort
from finanzia.modules.ledger.domain.entities import Category
from finanzia.modules.ledger.domain.errors import (
    CategoryNotFound,
    DuplicateCategoryName,
    SystemCategoryImmutable,
)


class UpdateCategory:
    """Edita una categoria propia; las del sistema son inmutables (403)."""

    def __init__(self, *, categories: CategoryRepositoryPort, uow: UnitOfWorkPort) -> None:
        self._categories = categories
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID, patch: CategoryPatch) -> Category:
        category = await self._categories.get_visible(user_id, id)
        if category is None:
            raise CategoryNotFound
        if category.is_system:
            raise SystemCategoryImmutable

        new_name = patch.name
        if new_name is not UNSET and new_name != category.name:
            if await self._categories.exists_name(user_id, new_name):
                raise DuplicateCategoryName
            category = replace(category, name=new_name)
        if patch.icon is not UNSET:
            category = replace(category, icon=patch.icon)
        if patch.color is not UNSET:
            category = replace(category, color=patch.color)
        if patch.fiscal_tag is not UNSET:
            category = replace(category, fiscal_tag=patch.fiscal_tag)

        await self._categories.update(category)
        await self._uow.commit()
        return category
