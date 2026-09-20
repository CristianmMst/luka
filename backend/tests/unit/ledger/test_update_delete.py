"""Tests unitarios de `UpdateTransaction`/`DeleteTransaction` (spec 005 SS6, AC-6.3/AC-7.2)."""

from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from finanzia.modules.ledger.application.dto import (
    CapturedTransactionCommand,
    ManualTransactionCommand,
    SourceInput,
    TransactionPatch,
)
from finanzia.modules.ledger.application.use_cases.create_manual_transaction import (
    CreateManualTransaction,
)
from finanzia.modules.ledger.application.use_cases.delete_transaction import DeleteTransaction
from finanzia.modules.ledger.application.use_cases.get_transaction import GetTransaction
from finanzia.modules.ledger.application.use_cases.record_captured_transaction import (
    RecordCapturedTransaction,
)
from finanzia.modules.ledger.application.use_cases.update_transaction import UpdateTransaction
from finanzia.modules.ledger.domain.entities import Category, LinkedAccount, Transaction
from finanzia.modules.ledger.domain.enums import (
    AccountKind,
    Bank,
    Channel,
    Direction,
    FiscalTag,
    Kind,
)
from finanzia.modules.ledger.domain.errors import NotManualTransaction, TransactionNotFound
from finanzia.modules.ledger.domain.merchant import normalize_merchant
from finanzia.modules.ledger.domain.transfers import NoMatch, find_transfer_match
from ledger.fakes import FixedClock, build_ledger_repos

NOW = datetime(2024, 3, 1, 12, 0, 0, tzinfo=UTC)
USER = uuid4()


def _update_use_case(repos) -> UpdateTransaction:
    return UpdateTransaction(
        transactions=repos.transactions,
        categories=repos.categories,
        merchant_rules=repos.merchant_rules,
        clock=FixedClock(NOW),
        ids=repos.ids,
        uow=repos.uow,
    )


def _get_use_case(repos) -> GetTransaction:
    return GetTransaction(transactions=repos.transactions, sources=repos.sources)


def _delete_use_case(repos) -> DeleteTransaction:
    return DeleteTransaction(
        transactions=repos.transactions,
        categories=repos.categories,
        clock=FixedClock(NOW),
        uow=repos.uow,
    )


async def _create_manual(  # noqa: PLR0913 - builder de comando con un default por campo
    repos,
    *,
    direction: Direction = Direction.DEBIT,
    category_id: UUID | None = None,
    merchant: str | None = None,
    account_id: UUID | None = None,
    occurred_at: datetime = NOW,
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
            amount=Decimal("30000"),
            direction=direction,
            occurred_at=occurred_at,
            category_id=category_id,
            merchant=merchant,
            description=None,
            account_id=account_id,
            notes=None,
        )
    )


async def _capture(  # noqa: PLR0913 - builder de comando con un default por campo
    repos,
    *,
    bank: Bank = Bank.BANCOLOMBIA,
    last4: str | None = "1234",
    direction: Direction = Direction.DEBIT,
    merchant: str | None = "EXITO BOGOTA",
    source: SourceInput | None = None,
):
    use_case = RecordCapturedTransaction(
        transactions=repos.transactions,
        sources=repos.sources,
        categories=repos.categories,
        accounts=repos.accounts,
        merchant_rules=repos.merchant_rules,
        events=repos.events,
        clock=FixedClock(NOW),
        ids=repos.ids,
        uow=repos.uow,
    )
    return await use_case.execute(
        CapturedTransactionCommand(
            user_id=USER,
            bank=bank,
            amount=Decimal("30000"),
            direction=direction,
            occurred_at=NOW,
            last4=last4,
            merchant=merchant,
            description=None,
            suggested_category_slug=None,
            parsed_by="rule:bancolombia:debito",
            confidence=0.9,
            source=source or SourceInput(Channel.EMAIL, uuid4(), NOW),
        )
    )


async def _add_category(repos, *, fiscal_tag: FiscalTag = FiscalTag.NO_DEDUCIBLE) -> Category:
    category = Category(
        id=uuid4(),
        user_id=USER,
        slug=None,
        name=f"Categoria {uuid4()}",
        icon=None,
        color=None,
        fiscal_tag=fiscal_tag,
    )
    await repos.categories.add(category)
    return category


@pytest.mark.unit
async def test_patch_category_con_merchant_aprende_regla_y_re_denormaliza_fiscal_tag() -> None:
    """AC-7.2: cambiar de categoria con un comercio no vacio aprende la regla."""
    repos = await build_ledger_repos()
    tx = await _create_manual(repos, merchant="EXITO BOGOTA")
    category = await _add_category(repos, fiscal_tag=FiscalTag.DEDUCIBLE_SALUD)
    use_case = _update_use_case(repos)

    updated = await use_case.execute(USER, tx.id, TransactionPatch(category_id=category.id))

    assert updated.category_id == category.id
    assert updated.fiscal_tag == FiscalTag.DEDUCIBLE_SALUD
    rules = await repos.merchant_rules.list_for_user(USER)
    assert len(rules) == 1
    assert rules[0].merchant_pattern == normalize_merchant("EXITO BOGOTA")
    assert rules[0].category_id == category.id


@pytest.mark.unit
async def test_patch_category_con_learn_merchant_rule_false_no_aprende_regla() -> None:
    repos = await build_ledger_repos()
    tx = await _create_manual(repos, merchant="EXITO BOGOTA")
    category = await _add_category(repos)
    use_case = _update_use_case(repos)

    await use_case.execute(
        USER, tx.id, TransactionPatch(category_id=category.id, learn_merchant_rule=False)
    )

    assert await repos.merchant_rules.list_for_user(USER) == []


@pytest.mark.unit
async def test_patch_kind_transfer_marca_la_transaccion() -> None:
    repos = await build_ledger_repos()
    tx = await _create_manual(repos)
    use_case = _update_use_case(repos)

    updated = await use_case.execute(USER, tx.id, TransactionPatch(kind=Kind.TRANSFER))

    assert updated.kind == Kind.TRANSFER
    assert updated.fiscal_tag == FiscalTag.TRANSFERENCIA


@pytest.mark.unit
async def test_patch_kind_expense_en_par_restaura_ambas_y_excluye_mutuamente() -> None:
    """AC-6.3: revertir un lado del par restaura ambos y evita que el matcher los re-empareje."""
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

    debit = await _capture(
        repos,
        bank=Bank.BANCOLOMBIA,
        last4="1111",
        direction=Direction.DEBIT,
        merchant=None,
        source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW),
    )
    credit = await _capture(
        repos,
        bank=Bank.NEQUI,
        last4="2222",
        direction=Direction.CREDIT,
        merchant=None,
        source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW),
    )
    assert credit.transaction.kind == Kind.TRANSFER  # matcher ya los emparejo

    use_case = _update_use_case(repos)
    updated_debit = await use_case.execute(
        USER, debit.transaction.id, TransactionPatch(kind=Kind.EXPENSE)
    )

    assert updated_debit.kind == Kind.EXPENSE
    assert updated_debit.transfer_pair_id is None
    refreshed_credit = await repos.transactions.get(USER, credit.transaction.id)
    assert refreshed_credit is not None
    assert refreshed_credit.kind == Kind.INCOME
    assert refreshed_credit.transfer_pair_id is None

    assert refreshed_credit.id in updated_debit.transfer_exclusions
    assert updated_debit.id in refreshed_credit.transfer_exclusions
    assert isinstance(find_transfer_match(updated_debit, [refreshed_credit]), NoMatch)


@pytest.mark.unit
async def test_borrar_transaccion_no_manual_lanza_not_manual_transaction() -> None:
    repos = await build_ledger_repos()
    captured = await _capture(repos)
    use_case = _delete_use_case(repos)

    with pytest.raises(NotManualTransaction):
        await use_case.execute(USER, captured.transaction.id)


@pytest.mark.unit
async def test_borrar_manual_emparejado_desempareja_la_pareja() -> None:
    repos = await build_ledger_repos()
    account_a = LinkedAccount(
        id=uuid4(),
        user_id=USER,
        bank=Bank.BANCOLOMBIA,
        kind=AccountKind.SAVINGS,
        last4="3333",
        alias=None,
    )
    account_b = LinkedAccount(
        id=uuid4(),
        user_id=USER,
        bank=Bank.NEQUI,
        kind=AccountKind.WALLET,
        last4="4444",
        alias=None,
    )
    await repos.accounts.add(account_a)
    await repos.accounts.add(account_b)
    debit = await _create_manual(repos, direction=Direction.DEBIT, account_id=account_a.id)
    credit = await _create_manual(
        repos,
        direction=Direction.CREDIT,
        account_id=account_b.id,
        occurred_at=NOW + timedelta(minutes=1),
    )
    assert credit.kind == Kind.TRANSFER  # matcher ya los emparejo

    use_case = _delete_use_case(repos)
    await use_case.execute(USER, debit.id)

    assert await repos.transactions.get(USER, debit.id) is None
    refreshed_credit = await repos.transactions.get(USER, credit.id)
    assert refreshed_credit is not None
    assert refreshed_credit.transfer_pair_id is None
    assert refreshed_credit.kind == Kind.INCOME


@pytest.mark.unit
async def test_id_ajeno_lanza_transaction_not_found() -> None:
    repos = await build_ledger_repos()
    delete_use_case = _delete_use_case(repos)
    update_use_case = _update_use_case(repos)

    with pytest.raises(TransactionNotFound):
        await delete_use_case.execute(USER, uuid4())
    with pytest.raises(TransactionNotFound):
        await update_use_case.execute(USER, uuid4(), TransactionPatch(notes="x"))


@pytest.mark.unit
async def test_get_transaction_incluye_fuentes_y_pareja() -> None:
    repos = await build_ledger_repos()
    account_a = LinkedAccount(
        id=uuid4(),
        user_id=USER,
        bank=Bank.BANCOLOMBIA,
        kind=AccountKind.SAVINGS,
        last4="5555",
        alias=None,
    )
    account_b = LinkedAccount(
        id=uuid4(),
        user_id=USER,
        bank=Bank.NEQUI,
        kind=AccountKind.WALLET,
        last4="6666",
        alias=None,
    )
    await repos.accounts.add(account_a)
    await repos.accounts.add(account_b)
    debit = await _create_manual(repos, direction=Direction.DEBIT, account_id=account_a.id)
    credit = await _create_manual(
        repos,
        direction=Direction.CREDIT,
        account_id=account_b.id,
        occurred_at=NOW + timedelta(minutes=1),
    )
    assert credit.kind == Kind.TRANSFER  # matcher ya los emparejo

    use_case = _get_use_case(repos)
    detail = await use_case.execute(USER, debit.id)

    assert detail.transaction.id == debit.id
    assert len(detail.sources) == 1
    assert detail.pair is not None
    assert detail.pair.id == credit.id


@pytest.mark.unit
async def test_get_transaction_id_ajeno_lanza_transaction_not_found() -> None:
    repos = await build_ledger_repos()
    use_case = _get_use_case(repos)

    with pytest.raises(TransactionNotFound):
        await use_case.execute(USER, uuid4())
