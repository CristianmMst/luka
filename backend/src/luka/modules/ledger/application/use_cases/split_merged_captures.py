"""Caso de uso: separar capturas entre personas fusionadas por el dedupe viejo
(spec 004 SS3).

Antes la huella no miraba la contraparte: tres amigos que envian $7.100 a la
misma cuenta en la misma ventana de 10 minutos quedaban como UN movimiento con
tres fuentes. Para cada captura entre personas con 2 o mas fuentes, se re-parsea
cada `raw_message` (`CaptureReaderPort`) y las fuentes cuya contraparte no es la
de la primera se sueltan y se registran de nuevo con `RecordCapturedTransaction`,
que ya las trata como movimientos distintos. Correo y notificacion del mismo envio
(misma persona) se quedan juntos. Una fuente que ya no se puede re-parsear (cuerpo
purgado) se queda donde esta y se cuenta aparte. Idempotente.
"""

from __future__ import annotations

from collections.abc import Collection
from dataclasses import dataclass
from uuid import UUID

from luka.modules.ledger.application.dto import CapturedTransactionCommand
from luka.modules.ledger.application.ports import (
    CaptureReaderPort,
    ClockPort,
    TransactionRepositoryPort,
    TransactionSourceRepositoryPort,
    UnitOfWorkPort,
)
from luka.modules.ledger.application.use_cases.record_captured_transaction import (
    RecordCapturedTransaction,
)
from luka.modules.ledger.domain.dedupe import same_counterparty


@dataclass(frozen=True, slots=True)
class SplitMergedCapturesSummary:
    """Conteos (sin ids, montos ni nombres, P1)."""

    split: int
    unreadable: int


class SplitMergedCaptures:
    """Suelta y vuelve a registrar las fuentes de otra contraparte."""

    def __init__(  # noqa: PLR0913 - un puerto por dependencia externa
        self,
        *,
        transactions: TransactionRepositoryPort,
        sources: TransactionSourceRepositoryPort,
        reader: CaptureReaderPort,
        record: RecordCapturedTransaction,
        clock: ClockPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._transactions = transactions
        self._sources = sources
        self._reader = reader
        self._record = record
        self._clock = clock
        self._uow = uow

    async def execute(
        self, *, person_parsed_by: Collection[str], user_id: UUID | None
    ) -> SplitMergedCapturesSummary:
        split = unreadable = 0
        for tx in await self._transactions.find_by_parsed_by(person_parsed_by, user_id):
            raw_ids = [
                s.raw_message_id
                for s in await self._sources.list_for(tx.id)
                if s.raw_message_id is not None
            ]
            if len(raw_ids) < 2:  # noqa: PLR2004 - una sola fuente no esta fusionada
                continue
            captures = [await self._reader.capture_for(raw_id) for raw_id in raw_ids]
            unreadable += sum(1 for c in captures if c is None)
            anchor = _anchor(tx.merchant, [c for c in captures if c is not None])
            if anchor is None:
                continue
            for raw_id, capture in zip(raw_ids, captures, strict=True):
                if capture is None or not _other_person(capture, anchor):
                    continue
                await self._sources.detach(tx.id, raw_id)
                await self._transactions.touch(tx.user_id, tx.id, self._clock.now())
                # Comitea el detach junto con el registro nuevo (misma unidad).
                await self._record.execute(capture)
                split += 1
        await self._uow.commit()
        return SplitMergedCapturesSummary(split=split, unreadable=unreadable)


def _anchor(merchant: str | None, captures: list[CapturedTransactionCommand]) -> str | None:
    """La contraparte que se queda en el movimiento: la de la fuente que coincide
    con su comercio (el registro la volveria a pegar ahi), o la primera fuente si
    el usuario renombro el comercio."""
    names = [c.merchant for c in captures if c.merchant]
    if merchant:
        for name in names:
            if same_counterparty(name, merchant):
                return name
    return names[0] if names else None


def _other_person(capture: CapturedTransactionCommand, anchor: str) -> bool:
    return (
        capture.merchant_is_person
        and bool(capture.merchant)
        and not same_counterparty(capture.merchant or "", anchor)
    )


__all__ = ["SplitMergedCaptures", "SplitMergedCapturesSummary"]
