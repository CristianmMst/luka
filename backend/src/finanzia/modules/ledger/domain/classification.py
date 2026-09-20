"""Clasificacion de transacciones: kind, fiscal_tag y marcado de transferencias.

Referencias: spec 004 SS2.5 (kind/fiscal_tag), spec 004 SS4 (desmarcado, AC-6.3),
spec 007 SS2 (fiscal_tag). `Transaction` solo se referencia para anotar tipos: este
modulo no la importa en tiempo de ejecucion (evita el ciclo `entities -> classification`,
ya que `entities.py` usa `derive_kind`/`resolve_fiscal_tag` en sus factories).
"""

from __future__ import annotations

from dataclasses import replace
from typing import TYPE_CHECKING

from finanzia.modules.ledger.domain.enums import Direction, FiscalTag, Kind

if TYPE_CHECKING:
    from datetime import datetime

    from finanzia.modules.ledger.domain.entities import Transaction

_DIRECTION_TO_KIND: dict[Direction, Kind] = {
    Direction.DEBIT: Kind.EXPENSE,
    Direction.CREDIT: Kind.INCOME,
}


def derive_kind(direction: Direction) -> Kind:
    """`expense` para debitos, `income` para creditos (spec 004 SS2.5)."""
    return _DIRECTION_TO_KIND[direction]


def resolve_fiscal_tag(kind: Kind, category_fiscal_tag: FiscalTag) -> FiscalTag:
    """`transferencia` si `kind == transfer`; si no, la etiqueta fiscal de la categoria."""
    if kind == Kind.TRANSFER:
        return FiscalTag.TRANSFERENCIA
    return category_fiscal_tag


def mark_as_transfer(tx: Transaction, *, now: datetime) -> Transaction:
    """Marca `tx` como transferencia: `kind=transfer`, `fiscal_tag=transferencia`."""
    return replace(tx, kind=Kind.TRANSFER, fiscal_tag=FiscalTag.TRANSFERENCIA, updated_at=now)


def unmark_transfer(
    tx: Transaction, *, category_fiscal_tag: FiscalTag, now: datetime
) -> Transaction:
    """Restaura `tx` a su naturaleza original al desmarcar una transferencia (AC-6.3).

    Restablece `kind` a partir de `direction`, `fiscal_tag` a la de la categoria actual
    y limpia el emparejamiento (`transfer_pair_id=None`, `transfer_auto=False`). No
    toca `transfer_exclusions`: eso lo hace el matcher (spec 004 SS4, `transfers.py`).
    """
    return replace(
        tx,
        kind=derive_kind(tx.direction),
        fiscal_tag=category_fiscal_tag,
        transfer_pair_id=None,
        transfer_auto=False,
        updated_at=now,
    )
