"""Matcher de transferencias entre cuentas propias (spec 004 SS4, RF-6).

`Transaction`/`FiscalTag` solo se referencian para anotar tipos (bajo `TYPE_CHECKING`):
este modulo no importa `entities.py` en tiempo de ejecucion, solo `classification.py`
(que tampoco importa `entities.py` en tiempo de ejecucion), evitando cualquier ciclo
con las factories de `entities.py`.
"""

from __future__ import annotations

from dataclasses import dataclass, replace
from datetime import timedelta
from typing import TYPE_CHECKING

from luka.modules.ledger.domain.classification import mark_as_transfer, unmark_transfer
from luka.modules.ledger.domain.enums import Kind
from luka.modules.ledger.domain.errors import TransferPairInvalid

if TYPE_CHECKING:
    from collections.abc import Iterable
    from datetime import datetime
    from uuid import UUID

    from luka.modules.ledger.domain.entities import Transaction
    from luka.modules.ledger.domain.enums import FiscalTag

TRANSFER_WINDOW = timedelta(hours=48)


@dataclass(frozen=True, slots=True)
class Matched:
    """Match unico: la otra pata de la transferencia (AC-6.1)."""

    other_id: UUID


@dataclass(frozen=True, slots=True)
class Ambiguous:
    """Dos o mas candidatos posibles; ids ordenados (AC-6.2)."""

    candidate_ids: tuple[UUID, ...]


@dataclass(frozen=True, slots=True)
class NoMatch:
    """Ningun candidato cumple las condiciones del matcher."""


MatchResult = Matched | Ambiguous | NoMatch


def is_transfer_candidate(a: Transaction, b: Transaction) -> bool:
    """`True` si `a`/`b` cumplen las condiciones del matcher (spec 004 SS4.1)."""
    same_transaction = a.id == b.id or a.user_id != b.user_id
    mismatched_amount = a.direction == b.direction or a.amount != b.amount
    outside_window = abs(a.occurred_at - b.occurred_at) > TRANSFER_WINDOW
    invalid_accounts = a.account_id is None or b.account_id is None or a.account_id == b.account_id
    already_paired = a.transfer_pair_id is not None or b.transfer_pair_id is not None
    already_transfer = Kind.TRANSFER in (a.kind, b.kind)
    excluded = b.id in a.transfer_exclusions or a.id in b.transfer_exclusions
    return not (
        same_transaction
        or mismatched_amount
        or outside_window
        or invalid_accounts
        or already_paired
        or already_transfer
        or excluded
    )


def find_transfer_match(tx: Transaction, candidates: Iterable[Transaction]) -> MatchResult:
    """Clasifica los candidatos de `tx`: sin match, match unico o ambiguo (AC-6.1/6.2)."""
    matches = [candidate.id for candidate in candidates if is_transfer_candidate(tx, candidate)]
    if not matches:
        return NoMatch()
    if len(matches) == 1:
        return Matched(other_id=matches[0])
    return Ambiguous(candidate_ids=tuple(sorted(matches)))


def pair(
    a: Transaction, b: Transaction, *, auto: bool, now: datetime
) -> tuple[Transaction, Transaction]:
    """Empareja `a` y `b` como transferencia (AC-6.1/AC-6.2).

    Ambas quedan `kind=transfer`, `fiscal_tag=transferencia`, con `transfer_pair_id`
    cruzado y `transfer_auto=auto`. Rechaza pares invalidos: distinto usuario, misma
    direccion o alguna ya emparejada.
    """
    if a.user_id != b.user_id:
        raise TransferPairInvalid("las transacciones pertenecen a usuarios distintos")
    if a.direction == b.direction:
        raise TransferPairInvalid("las transacciones deben tener direccion opuesta")
    if a.transfer_pair_id is not None or b.transfer_pair_id is not None:
        raise TransferPairInvalid("una de las transacciones ya esta emparejada")
    marked_a = mark_as_transfer(a, now=now)
    marked_b = mark_as_transfer(b, now=now)
    paired_a = replace(marked_a, transfer_pair_id=b.id, transfer_auto=auto)
    paired_b = replace(marked_b, transfer_pair_id=a.id, transfer_auto=auto)
    return paired_a, paired_b


def unpair(
    a: Transaction,
    b: Transaction,
    *,
    category_tags: tuple[FiscalTag, FiscalTag],
    now: datetime,
) -> tuple[Transaction, Transaction]:
    """Desmarca la pareja `a`/`b`: restaura kind/fiscal_tag y agrega exclusion mutua (AC-6.3).

    La exclusion mutua evita que el matcher automatico vuelva a emparejarlas.
    """
    tag_a, tag_b = category_tags
    unmarked_a = unmark_transfer(a, category_fiscal_tag=tag_a, now=now)
    unmarked_b = unmark_transfer(b, category_fiscal_tag=tag_b, now=now)
    excluded_a = replace(unmarked_a, transfer_exclusions=unmarked_a.transfer_exclusions | {b.id})
    excluded_b = replace(unmarked_b, transfer_exclusions=unmarked_b.transfer_exclusions | {a.id})
    return excluded_a, excluded_b
