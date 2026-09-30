"""Caso de uso: borrar una transaccion manual propia (spec 005 SS6)."""

from uuid import UUID

from luka.modules.ledger.application.ports import (
    CategoryRepositoryPort,
    ClockPort,
    EventPublisherPort,
    IdGeneratorPort,
    TransactionRepositoryPort,
    UnitOfWorkPort,
)
from luka.modules.ledger.domain.enums import FiscalTag
from luka.modules.ledger.domain.errors import (
    CategoryNotFound,
    NotManualTransaction,
    TransactionNotFound,
)
from luka.modules.ledger.domain.transfers import unpair
from luka.modules.ledger.events import TransactionDeleted


class DeleteTransaction:
    """Borra una transaccion manual propia; si estaba emparejada, restaura la pareja.

    Tras el commit publica `TransactionDeleted` para que recurring libere la
    ocurrencia que esa transaccion pagaba (spec 011 SS4).
    """

    def __init__(  # noqa: PLR0913 - puertos del caso de uso por nombre
        self,
        *,
        transactions: TransactionRepositoryPort,
        categories: CategoryRepositoryPort,
        events: EventPublisherPort,
        clock: ClockPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._transactions = transactions
        self._categories = categories
        self._events = events
        self._clock = clock
        self._ids = ids
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID) -> None:
        """Lanza `TransactionNotFound` si no existe y `NotManualTransaction` si no es manual."""
        tx = await self._transactions.get(user_id, id)
        if tx is None:
            raise TransactionNotFound
        if tx.parsed_by != "manual":
            raise NotManualTransaction

        if tx.transfer_pair_id is not None:
            other = await self._transactions.get(user_id, tx.transfer_pair_id)
            if other is not None:
                now = self._clock.now()
                tag_tx = await self._category_fiscal_tag(user_id, tx.category_id)
                tag_other = await self._category_fiscal_tag(user_id, other.category_id)
                _, updated_other = unpair(tx, other, category_tags=(tag_tx, tag_other), now=now)
                await self._transactions.update(updated_other)

        await self._transactions.delete(user_id, id)
        await self._uow.commit()
        await self._events.publish(
            TransactionDeleted(
                event_id=self._ids.new_id(),
                occurred_at=self._clock.now(),
                user_id=user_id,
                transaction_id=id,
            )
        )

    async def _category_fiscal_tag(self, user_id: UUID, category_id: UUID) -> FiscalTag:
        category = await self._categories.get_visible(user_id, category_id)
        if category is None:
            raise CategoryNotFound
        return category.fiscal_tag
