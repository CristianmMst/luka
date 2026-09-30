"""Tests unitarios de `CreateManualTransaction` (spec 004 SS2.6, AC-6.4)."""

from datetime import UTC, datetime
from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from ledger.fakes import FixedClock, build_ledger_repos
from luka.modules.ledger.application.dto import ManualTransactionCommand
from luka.modules.ledger.application.use_cases.create_manual_transaction import (
    CreateManualTransaction,
)
from luka.modules.ledger.domain.entities import Category, LinkedAccount
from luka.modules.ledger.domain.enums import AccountKind, Bank, Direction, FiscalTag, Kind
from luka.modules.ledger.domain.errors import CategoryNotFound
from luka.modules.ledger.domain.system_categories import SIN_CATEGORIA_ID, TRANSFERENCIAS_ID

NOW = datetime(2024, 3, 1, 12, 0, 0, tzinfo=UTC)
USER = uuid4()


def _cmd(  # noqa: PLR0913 - builder de comando con un default por campo
    *,
    amount: Decimal = Decimal("20000"),
    direction: Direction = Direction.DEBIT,
    occurred_at: datetime = NOW,
    category_id: UUID | None = None,
    merchant: str | None = "Panaderia",
    description: str | None = None,
    account_id: UUID | None = None,
    notes: str | None = None,
    kind: Kind | None = None,
) -> ManualTransactionCommand:
    return ManualTransactionCommand(
        user_id=USER,
        amount=amount,
        direction=direction,
        occurred_at=occurred_at,
        category_id=category_id,
        merchant=merchant,
        description=description,
        account_id=account_id,
        notes=notes,
        kind=kind,
    )


def _make_use_case(repos) -> CreateManualTransaction:
    return CreateManualTransaction(
        transactions=repos.transactions,
        sources=repos.sources,
        categories=repos.categories,
        accounts=repos.accounts,
        events=repos.events,
        clock=FixedClock(NOW),
        ids=repos.ids,
        uow=repos.uow,
    )


@pytest.mark.unit
async def test_crea_transaccion_manual_con_categoria_y_cuenta_propias() -> None:
    repos = await build_ledger_repos()
    category = Category(
        id=uuid4(),
        user_id=USER,
        slug=None,
        name="Antojos",
        icon=None,
        color=None,
        fiscal_tag=FiscalTag.NO_DEDUCIBLE,
    )
    await repos.categories.add(category)
    account = LinkedAccount(
        id=uuid4(),
        user_id=USER,
        bank=Bank.BANCOLOMBIA,
        kind=AccountKind.SAVINGS,
        last4="9999",
        alias="Ahorros",
    )
    await repos.accounts.add(account)
    use_case = _make_use_case(repos)

    tx = await use_case.execute(_cmd(category_id=category.id, account_id=account.id))

    assert tx.category_id == category.id
    assert tx.account_id == account.id
    assert tx.bank == Bank.BANCOLOMBIA
    assert tx.parsed_by == "manual"
    assert tx.dedupe_key.startswith("manual:")
    assert len(repos.events.events) == 1
    assert (await repos.sources.list_for(tx.id))[0].channel.value == "manual"


@pytest.mark.unit
async def test_sin_categoria_usa_sin_categoria_del_sistema() -> None:
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)

    tx = await use_case.execute(_cmd())

    assert tx.category_id == SIN_CATEGORIA_ID


@pytest.mark.unit
async def test_categoria_desconocida_lanza_category_not_found() -> None:
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)

    with pytest.raises(CategoryNotFound):
        await use_case.execute(_cmd(category_id=uuid4()))


@pytest.mark.unit
async def test_matcher_empareja_manual_con_cuenta_contra_captura_existente() -> None:
    """El matcher tambien corre para una transaccion manual con `account_id`."""
    repos = await build_ledger_repos()
    account_a = LinkedAccount(
        id=uuid4(),
        user_id=USER,
        bank=Bank.BANCOLOMBIA,
        kind=AccountKind.SAVINGS,
        last4="1111",
        alias=None,
    )
    account_b = LinkedAccount(
        id=uuid4(),
        user_id=USER,
        bank=Bank.NEQUI,
        kind=AccountKind.WALLET,
        last4="2222",
        alias=None,
    )
    await repos.accounts.add(account_a)
    await repos.accounts.add(account_b)
    use_case = _make_use_case(repos)

    debit = await use_case.execute(
        _cmd(direction=Direction.DEBIT, account_id=account_a.id, merchant=None)
    )
    credit = await use_case.execute(
        _cmd(direction=Direction.CREDIT, account_id=account_b.id, merchant=None)
    )

    refreshed_debit = await repos.transactions.get(USER, debit.id)
    assert refreshed_debit is not None
    assert refreshed_debit.kind == Kind.TRANSFER
    assert refreshed_debit.transfer_pair_id == credit.id
    assert credit.kind == Kind.TRANSFER
    assert credit.transfer_pair_id == debit.id
    assert credit.transfer_auto is True


@pytest.mark.unit
async def test_transferencia_manual_explicita_sin_pareja_queda_fiscal_transferencia() -> None:
    """AC-6.4: `kind=transfer` manual sin contraparte -> `fiscal_tag=transferencia`."""
    repos = await build_ledger_repos()
    account = LinkedAccount(
        id=uuid4(),
        user_id=USER,
        bank=Bank.BANCOLOMBIA,
        kind=AccountKind.SAVINGS,
        last4="4444",
        alias=None,
    )
    await repos.accounts.add(account)
    use_case = _make_use_case(repos)

    tx = await use_case.execute(
        _cmd(
            category_id=TRANSFERENCIAS_ID,
            account_id=account.id,
            kind=Kind.TRANSFER,
            merchant=None,
        )
    )

    assert tx.kind == Kind.TRANSFER
    assert tx.fiscal_tag == FiscalTag.TRANSFERENCIA
    assert tx.transfer_pair_id is None
    assert tx.transfer_auto is False
