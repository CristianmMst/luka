"""Caso de uso: editar una categoria propia (spec 005 SS7)."""

from dataclasses import replace
from uuid import UUID

from finanzia.modules.ledger.application.dto import UNSET, CategoryPatch
from finanzia.modules.ledger.application.ports import (
    CategoryRepositoryPort,
    ClockPort,
    TransactionRepositoryPort,
    UnitOfWorkPort,
)
from finanzia.modules.ledger.domain.entities import Category
from finanzia.modules.ledger.domain.errors import (
    CategoryNotFound,
    DuplicateCategoryName,
    SystemCategoryImmutable,
)


class UpdateCategory:
    """Edita una categoria propia; las del sistema son inmutables (403).

    Un cambio de `fiscal_tag` se propaga a las transacciones de la categoria (salvo
    transferencias), para que el reporte fiscal no mezcle etiquetas viejas y nuevas.
    """

    def __init__(
        self,
        *,
        categories: CategoryRepositoryPort,
        transactions: TransactionRepositoryPort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._categories = categories
        self._transactions = transactions
        self._clock = clock
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID, patch: CategoryPatch) -> Category:
        category = await self._categories.get_visible(user_id, id)
        if category is None:
            raise CategoryNotFound
        if category.is_system:
            raise SystemCategoryImmutable

        new_name = patch.name
        if new_name is not UNSET and new_name != category.name:
            if await self._categories.exists_name(user_id, new_name, exclude_id=id):
                raise DuplicateCategoryName
            category = replace(category, name=new_name)
        if patch.icon is not UNSET:
            category = replace(category, icon=patch.icon)
        if patch.color is not UNSET:
            category = replace(category, color=patch.color)
        retag = patch.fiscal_tag is not UNSET and patch.fiscal_tag != category.fiscal_tag
        if patch.fiscal_tag is not UNSET:
            category = replace(category, fiscal_tag=patch.fiscal_tag)

        await self._categories.update(category)
        if retag:
            await self._transactions.retag_category(
                user_id, id, category.fiscal_tag, self._clock.now()
            )
        await self._uow.commit()
        return category
