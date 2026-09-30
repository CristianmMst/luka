"""Ayudante interno compartido por los casos de uso de captura (no es un caso de uso).

Ejecuta el matcher de transferencias (spec 004 SS4, AC-6.1/AC-6.2) tras insertar una
transaccion con `account_id`. Se extrae aqui para no duplicar la misma logica entre
`record_captured_transaction.py` y `create_manual_transaction.py`.
"""

from luka.modules.ledger.application.ports import ClockPort, TransactionRepositoryPort
from luka.modules.ledger.domain.entities import Transaction
from luka.modules.ledger.domain.enums import Direction
from luka.modules.ledger.domain.transfers import (
    TRANSFER_WINDOW,
    Matched,
    find_transfer_match,
    pair,
)

_OPPOSITE: dict[Direction, Direction] = {
    Direction.DEBIT: Direction.CREDIT,
    Direction.CREDIT: Direction.DEBIT,
}


async def try_auto_pair(
    tx: Transaction, *, transactions: TransactionRepositoryPort, clock: ClockPort
) -> Transaction:
    """Busca la contraparte de transferencia de `tx` y empareja ambas si hay match unico.

    No hace nada si `tx.account_id` es `None`, si no hay candidatos o si hay mas de
    uno (`Ambiguous`): en ese caso nadie queda emparejado (AC-6.2). Devuelve `tx`
    (posiblemente actualizada) para que el llamador la use en el resto del flujo.
    """
    if tx.account_id is None:
        return tx
    candidates = await transactions.find_transfer_candidates(
        tx.user_id,
        _OPPOSITE[tx.direction],
        tx.amount,
        tx.occurred_at - TRANSFER_WINDOW,
        tx.occurred_at + TRANSFER_WINDOW,
    )
    match = find_transfer_match(tx, candidates)
    if not isinstance(match, Matched):
        return tx
    other = await transactions.get(tx.user_id, match.other_id)
    if other is None:
        return tx
    paired_tx, paired_other = pair(tx, other, auto=True, now=clock.now())
    await transactions.update(paired_tx)
    await transactions.update(paired_other)
    return paired_tx
