"""Caso de uso: borrar una categoria propia (spec 005 SS7)."""

from uuid import UUID

from finanzia.modules.ledger.application.ports import (
    CategoryRepositoryPort,
    ClockPort,
    MerchantRuleRepositoryPort,
    TransactionRepositoryPort,
    UnitOfWorkPort,
)
from finanzia.modules.ledger.domain.enums import FiscalTag
from finanzia.modules.ledger.domain.errors import CategoryNotFound, SystemCategoryImmutable
from finanzia.modules.ledger.domain.system_categories import SIN_CATEGORIA_ID


class DeleteCategory:
    """Borra una categoria propia: reasigna sus transacciones a `sin_categoria` y limpia
    sus reglas de comercio aprendidas (spec 005 SS7). Las del sistema son inmutables (403).
    """

    def __init__(
        self,
        *,
        categories: CategoryRepositoryPort,
        transactions: TransactionRepositoryPort,
        merchant_rules: MerchantRuleRepositoryPort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._categories = categories
        self._transactions = transactions
        self._merchant_rules = merchant_rules
        self._clock = clock
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID) -> None:
        category = await self._categories.get_visible(user_id, id)
        if category is None:
            raise CategoryNotFound
        if category.is_system:
            raise SystemCategoryImmutable

        now = self._clock.now()
        await self._transactions.reassign_category(
            user_id, id, SIN_CATEGORIA_ID, FiscalTag.NO_DEDUCIBLE, now
        )
        await self._merchant_rules.delete_for_category(user_id, id)
        await self._categories.delete(user_id, id)
        await self._uow.commit()
