"""Caso de uso: reclasificar transferencias propias ya capturadas (spec 004 SS4.1).

Las capturas entre personas (`parsed_by` de una plantilla con `counterparty:
true`) cuya contraparte es el titular pasan a `transfer`, igual que haria
`RecordCapturedTransaction` con una captura nueva. Solo toca filas que nadie
edito despues de capturarlas (`updated_at == created_at`): una categoria, nota
o tipo puesto a mano se respeta y la fila se cuenta como omitida.
"""

from __future__ import annotations

from collections.abc import Collection
from dataclasses import dataclass
from uuid import UUID

from luka.modules.ledger.application.ports import (
    ClockPort,
    OwnerNamePort,
    TransactionRepositoryPort,
    UnitOfWorkPort,
)
from luka.modules.ledger.domain.classification import mark_as_transfer
from luka.modules.ledger.domain.self_transfer import is_same_person


@dataclass(frozen=True, slots=True)
class MarkSelfTransfersSummary:
    """Conteos (sin ids, montos ni nombres, P1)."""

    marked: int
    skipped_edited: int


class MarkSelfTransfers:
    """Pasa a `transfer` las capturas entre personas hechas al propio titular."""

    def __init__(
        self,
        *,
        transactions: TransactionRepositoryPort,
        owner_names: OwnerNamePort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._transactions = transactions
        self._owner_names = owner_names
        self._clock = clock
        self._uow = uow

    async def execute(
        self, *, person_parsed_by: Collection[str], user_id: UUID | None
    ) -> MarkSelfTransfersSummary:
        candidates = await self._transactions.find_non_transfers_by_parsed_by(
            person_parsed_by, user_id
        )
        owners: dict[UUID, str | None] = {}
        now = self._clock.now()
        marked = skipped = 0
        for tx in candidates:
            if tx.user_id not in owners:
                owners[tx.user_id] = await self._owner_names.display_name(tx.user_id)
            if not is_same_person(tx.merchant, owners[tx.user_id]):
                continue
            if tx.updated_at != tx.created_at:
                skipped += 1
                continue
            # `updated_at` nuevo: el pull incremental de la app la trae.
            await self._transactions.update(mark_as_transfer(tx, now=now))
            marked += 1
        await self._uow.commit()
        return MarkSelfTransfersSummary(marked=marked, skipped_edited=skipped)


__all__ = ["MarkSelfTransfers", "MarkSelfTransfersSummary"]
