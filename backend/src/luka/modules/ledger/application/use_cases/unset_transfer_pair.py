"""Caso de uso: deshacer el emparejamiento de una transferencia (spec 005 SS6, AC-6.3)."""

from uuid import UUID

from luka.modules.ledger.application.dto import TransactionDetail
from luka.modules.ledger.application.ports import (
    CategoryRepositoryPort,
    ClockPort,
    TransactionRepositoryPort,
    TransactionSourceRepositoryPort,
    UnitOfWorkPort,
)
from luka.modules.ledger.domain.enums import FiscalTag
from luka.modules.ledger.domain.errors import (
    CategoryNotFound,
    TransactionNotFound,
    TransferPairInvalid,
)
from luka.modules.ledger.domain.transfers import unpair


class UnsetTransferPair:
    """Deshace el emparejamiento de `id`: restaura kind/fiscal_tag de ambas patas."""

    def __init__(
        self,
        *,
        transactions: TransactionRepositoryPort,
        categories: CategoryRepositoryPort,
        sources: TransactionSourceRepositoryPort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._transactions = transactions
        self._categories = categories
        self._sources = sources
        self._clock = clock
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID) -> TransactionDetail:
        """Lanza `TransactionNotFound` si no existe y `TransferPairInvalid` si no esta pareada."""
        tx = await self._transactions.get(user_id, id)
        if tx is None:
            raise TransactionNotFound
        if tx.transfer_pair_id is None:
            raise TransferPairInvalid("no emparejada")

        other = await self._transactions.get(user_id, tx.transfer_pair_id)
        if other is None:
            raise TransactionNotFound

        now = self._clock.now()
        tag_tx = await self._category_fiscal_tag(user_id, tx.category_id)
        tag_other = await self._category_fiscal_tag(user_id, other.category_id)
        updated_tx, updated_other = unpair(tx, other, category_tags=(tag_tx, tag_other), now=now)
        await self._transactions.update(updated_tx)
        await self._transactions.update(updated_other)
        await self._uow.commit()

        sources = await self._sources.list_for(updated_tx.id)
        return TransactionDetail(transaction=updated_tx, sources=tuple(sources), pair=updated_other)

    async def _category_fiscal_tag(self, user_id: UUID, category_id: UUID) -> FiscalTag:
        category = await self._categories.get_visible(user_id, category_id)
        if category is None:
            raise CategoryNotFound
        return category.fiscal_tag
