"""Caso de uso: borrar una transaccion propia, manual o capturada (spec 005 SS6).

Una captura deja una lapida (spec 004 SS3) para que otra fuente de la misma
compra (un correo tardio, la cola de avisos del telefono, un `reparse`) no la
vuelva a crear.
"""

from uuid import UUID

from luka.modules.ledger.application.ports import (
    CategoryRepositoryPort,
    ClockPort,
    EventPublisherPort,
    IdGeneratorPort,
    TombstoneRepositoryPort,
    TransactionRepositoryPort,
    TransactionSourceRepositoryPort,
    UnitOfWorkPort,
)
from luka.modules.ledger.domain.dedupe import capture_origin, is_manual_key
from luka.modules.ledger.domain.entities import Transaction, TransactionTombstone
from luka.modules.ledger.domain.enums import Bank, FiscalTag
from luka.modules.ledger.domain.errors import CategoryNotFound, TransactionNotFound
from luka.modules.ledger.domain.transfers import unpair
from luka.modules.ledger.events import TransactionDeleted


class DeleteTransaction:
    """Borra una transaccion propia; si estaba emparejada, restaura la pareja, y si
    era una captura deja su lapida.

    Tras el commit publica `TransactionDeleted` para que recurring libere la
    ocurrencia que esa transaccion pagaba (spec 011 SS4).
    """

    def __init__(  # noqa: PLR0913 - puertos del caso de uso por nombre
        self,
        *,
        transactions: TransactionRepositoryPort,
        sources: TransactionSourceRepositoryPort,
        tombstones: TombstoneRepositoryPort,
        categories: CategoryRepositoryPort,
        events: EventPublisherPort,
        clock: ClockPort,
        ids: IdGeneratorPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._transactions = transactions
        self._sources = sources
        self._tombstones = tombstones
        self._categories = categories
        self._events = events
        self._clock = clock
        self._ids = ids
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID) -> None:
        """Lanza `TransactionNotFound` si no existe (o es ajena)."""
        tx = await self._transactions.get(user_id, id)
        if tx is None:
            raise TransactionNotFound
        if not is_manual_key(tx.dedupe_key):
            await self._leave_tombstone(tx)

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

    async def _leave_tombstone(self, tx: Transaction) -> None:
        channels = await self._sources.channels_for([tx.id])
        await self._tombstones.add(
            TransactionTombstone(
                id=self._ids.new_id(),
                user_id=tx.user_id,
                dedupe_key=tx.dedupe_key,
                bank=tx.bank or Bank.OTHER,
                amount=tx.amount,
                direction=tx.direction,
                occurred_at=tx.occurred_at,
                channels=frozenset(channels.get(tx.id, [])),
                origin=capture_origin(tx.parsed_by),
                deleted_at=self._clock.now(),
            )
        )

    async def _category_fiscal_tag(self, user_id: UUID, category_id: UUID) -> FiscalTag:
        category = await self._categories.get_visible(user_id, category_id)
        if category is None:
            raise CategoryNotFound
        return category.fiscal_tag
