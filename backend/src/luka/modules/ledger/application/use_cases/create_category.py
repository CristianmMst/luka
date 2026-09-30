"""Caso de uso: crear una categoria propia (spec 005 SS7)."""

from uuid import UUID

from luka.modules.ledger.application.dto import CategoryInput
from luka.modules.ledger.application.ports import (
    CategoryRepositoryPort,
    IdGeneratorPort,
    UnitOfWorkPort,
)
from luka.modules.ledger.domain.entities import Category
from luka.modules.ledger.domain.errors import DuplicateCategoryName


class CreateCategory:
    """Crea una categoria propia del usuario. El nombre no puede repetir, sin distinguir
    mayusculas, el de otra propia ni el de una del sistema (409)."""

    def __init__(
        self, *, categories: CategoryRepositoryPort, ids: IdGeneratorPort, uow: UnitOfWorkPort
    ) -> None:
        self._categories = categories
        self._ids = ids
        self._uow = uow

    async def execute(self, user_id: UUID, input: CategoryInput) -> Category:
        if await self._categories.exists_name(user_id, input.name):
            raise DuplicateCategoryName

        category = Category(
            id=self._ids.new_id(),
            user_id=user_id,
            slug=None,
            name=input.name,
            icon=input.icon,
            color=input.color,
            fiscal_tag=input.fiscal_tag,
        )
        await self._categories.add(category)
        await self._uow.commit()
        return category
