"""Caso de uso: emparejar manualmente dos transacciones como transferencia (spec 005 SS6)."""

from uuid import UUID

from luka.modules.ledger.application.dto import TransactionDetail
from luka.modules.ledger.application.ports import (
    ClockPort,
    TransactionRepositoryPort,
    TransactionSourceRepositoryPort,
    UnitOfWorkPort,
)
from luka.modules.ledger.domain.errors import (
    AlreadyPaired,
    TransactionNotFound,
    TransferPairInvalid,
)
from luka.modules.ledger.domain.transfers import pair


class SetTransferPair:
    """Empareja dos transacciones propias como transferencia manual (`transfer_auto=False`)."""

    def __init__(
        self,
        *,
        transactions: TransactionRepositoryPort,
        sources: TransactionSourceRepositoryPort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._transactions = transactions
        self._sources = sources
        self._clock = clock
        self._uow = uow

    async def execute(self, user_id: UUID, id: UUID, pair_id: UUID) -> TransactionDetail:
        """Lanza `TransactionNotFound`/`AlreadyPaired`/`TransferPairInvalid` segun aplique."""
        a = await self._transactions.get(user_id, id)
        if a is None:
            raise TransactionNotFound
        b = await self._transactions.get(user_id, pair_id)
        if b is None:
            raise TransactionNotFound

        if id == pair_id:
            raise TransferPairInvalid("una transaccion no puede emparejarse consigo misma")
        if a.transfer_pair_id is not None or b.transfer_pair_id is not None:
            raise AlreadyPaired

        now = self._clock.now()
        paired_a, paired_b = pair(a, b, auto=False, now=now)
        await self._transactions.update(paired_a)
        await self._transactions.update(paired_b)
        await self._uow.commit()

        sources = await self._sources.list_for(paired_a.id)
        return TransactionDetail(transaction=paired_a, sources=tuple(sources), pair=paired_b)
