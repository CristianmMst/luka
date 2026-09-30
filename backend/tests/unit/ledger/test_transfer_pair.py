"""Tests unitarios de `SetTransferPair`/`UnsetTransferPair` (spec 005 SS6 SS1.4)."""

from datetime import UTC, datetime
from decimal import Decimal
from uuid import uuid4

import pytest

from ledger.fakes import FixedClock, build_ledger_repos
from luka.modules.ledger.application.dto import ManualTransactionCommand
from luka.modules.ledger.application.use_cases.create_manual_transaction import (
    CreateManualTransaction,
)
from luka.modules.ledger.application.use_cases.set_transfer_pair import SetTransferPair
from luka.modules.ledger.application.use_cases.unset_transfer_pair import UnsetTransferPair
from luka.modules.ledger.domain.entities import Transaction
from luka.modules.ledger.domain.enums import Direction, FiscalTag, Kind
from luka.modules.ledger.domain.errors import AlreadyPaired, TransferPairInvalid

NOW = datetime(2024, 3, 1, 12, 0, 0, tzinfo=UTC)
USER = uuid4()


async def _create_manual(
    repos, *, amount: Decimal = Decimal("30000"), direction: Direction = Direction.DEBIT
) -> Transaction:
    use_case = CreateManualTransaction(
        transactions=repos.transactions,
        sources=repos.sources,
        categories=repos.categories,
        accounts=repos.accounts,
        events=repos.events,
        clock=FixedClock(NOW),
        ids=repos.ids,
        uow=repos.uow,
    )
    return await use_case.execute(
        ManualTransactionCommand(
            user_id=USER,
            amount=amount,
            direction=direction,
            occurred_at=NOW,
            category_id=None,
            merchant=None,
            description=None,
            account_id=None,
            notes=None,
        )
    )


def _set_use_case(repos) -> SetTransferPair:
    return SetTransferPair(
        transactions=repos.transactions, sources=repos.sources, clock=FixedClock(NOW), uow=repos.uow
    )


def _unset_use_case(repos) -> UnsetTransferPair:
    return UnsetTransferPair(
        transactions=repos.transactions,
        categories=repos.categories,
        sources=repos.sources,
        clock=FixedClock(NOW),
        uow=repos.uow,
    )


@pytest.mark.unit
async def test_emparejar_manualmente_permite_montos_distintos() -> None:
    repos = await build_ledger_repos()
    a = await _create_manual(repos, amount=Decimal("30000"), direction=Direction.DEBIT)
    b = await _create_manual(repos, amount=Decimal("45000"), direction=Direction.CREDIT)
    use_case = _set_use_case(repos)

    detail = await use_case.execute(USER, a.id, b.id)

    assert detail.transaction.kind == Kind.TRANSFER
    assert detail.transaction.transfer_auto is False
    assert detail.pair is not None
    assert detail.pair.id == b.id
    refreshed_b = await repos.transactions.get(USER, b.id)
    assert refreshed_b is not None
    assert refreshed_b.transfer_pair_id == a.id
    assert refreshed_b.transfer_auto is False


@pytest.mark.unit
async def test_emparejar_misma_direccion_lanza_transfer_pair_invalid() -> None:
    repos = await build_ledger_repos()
    a = await _create_manual(repos, direction=Direction.DEBIT)
    b = await _create_manual(repos, direction=Direction.DEBIT)
    use_case = _set_use_case(repos)

    with pytest.raises(TransferPairInvalid):
        await use_case.execute(USER, a.id, b.id)


@pytest.mark.unit
async def test_emparejar_una_ya_emparejada_lanza_already_paired() -> None:
    repos = await build_ledger_repos()
    a = await _create_manual(repos, direction=Direction.DEBIT)
    b = await _create_manual(repos, direction=Direction.CREDIT)
    c = await _create_manual(repos, direction=Direction.CREDIT)
    use_case = _set_use_case(repos)
    await use_case.execute(USER, a.id, b.id)

    with pytest.raises(AlreadyPaired):
        await use_case.execute(USER, a.id, c.id)


@pytest.mark.unit
async def test_deshacer_restaura_ambas_transacciones() -> None:
    repos = await build_ledger_repos()
    a = await _create_manual(repos, direction=Direction.DEBIT)
    b = await _create_manual(repos, direction=Direction.CREDIT)
    set_use_case = _set_use_case(repos)
    await set_use_case.execute(USER, a.id, b.id)

    unset_use_case = _unset_use_case(repos)
    detail = await unset_use_case.execute(USER, a.id)

    assert detail.transaction.kind == Kind.EXPENSE
    assert detail.transaction.transfer_pair_id is None
    assert detail.transaction.fiscal_tag == FiscalTag.NO_DEDUCIBLE
    assert detail.pair is not None
    assert detail.pair.kind == Kind.INCOME
    assert detail.pair.transfer_pair_id is None


@pytest.mark.unit
async def test_deshacer_no_emparejada_lanza_transfer_pair_invalid() -> None:
    repos = await build_ledger_repos()
    a = await _create_manual(repos)
    use_case = _unset_use_case(repos)

    with pytest.raises(TransferPairInvalid):
        await use_case.execute(USER, a.id)
