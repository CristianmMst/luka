"""Tests unitarios de categorias y cuentas (spec 005 SS7)."""

from datetime import UTC, datetime
from decimal import Decimal
from uuid import uuid4

import pytest

from finanzia.modules.ledger.application.dto import (
    AccountInput,
    AccountPatch,
    CategoryInput,
    CategoryPatch,
    ManualTransactionCommand,
)
from finanzia.modules.ledger.application.use_cases.create_account import CreateAccount
from finanzia.modules.ledger.application.use_cases.create_category import CreateCategory
from finanzia.modules.ledger.application.use_cases.create_manual_transaction import (
    CreateManualTransaction,
)
from finanzia.modules.ledger.application.use_cases.delete_account import DeleteAccount
from finanzia.modules.ledger.application.use_cases.delete_category import DeleteCategory
from finanzia.modules.ledger.application.use_cases.list_accounts import ListAccounts
from finanzia.modules.ledger.application.use_cases.list_categories import ListCategories
from finanzia.modules.ledger.application.use_cases.update_account import UpdateAccount
from finanzia.modules.ledger.application.use_cases.update_category import UpdateCategory
from finanzia.modules.ledger.domain.entities import MerchantRule
from finanzia.modules.ledger.domain.enums import AccountKind, Bank, Direction, FiscalTag
from finanzia.modules.ledger.domain.errors import (
    AccountNotFound,
    DuplicateAccount,
    DuplicateCategoryName,
    InvalidLast4,
    SystemCategoryImmutable,
)
from finanzia.modules.ledger.domain.system_categories import SIN_CATEGORIA_ID
from ledger.fakes import FixedClock, build_ledger_repos

NOW = datetime(2024, 3, 1, 12, 0, 0, tzinfo=UTC)
USER = uuid4()


def _create_category_use_case(repos) -> CreateCategory:
    return CreateCategory(categories=repos.categories, ids=repos.ids, uow=repos.uow)


def _update_category_use_case(repos) -> UpdateCategory:
    return UpdateCategory(categories=repos.categories, uow=repos.uow)


def _delete_category_use_case(repos) -> DeleteCategory:
    return DeleteCategory(
        categories=repos.categories,
        transactions=repos.transactions,
        merchant_rules=repos.merchant_rules,
        clock=FixedClock(NOW),
        uow=repos.uow,
    )


def _create_account_use_case(repos) -> CreateAccount:
    return CreateAccount(accounts=repos.accounts, ids=repos.ids, uow=repos.uow)


def _update_account_use_case(repos) -> UpdateAccount:
    return UpdateAccount(accounts=repos.accounts, uow=repos.uow)


def _delete_account_use_case(repos) -> DeleteAccount:
    return DeleteAccount(accounts=repos.accounts, uow=repos.uow)


@pytest.mark.unit
async def test_crear_categoria_con_nombre_duplicado_lanza_duplicate_category_name() -> None:
    repos = await build_ledger_repos()
    use_case = _create_category_use_case(repos)
    input_ = CategoryInput(
        name="Mascotas", icon=None, color=None, fiscal_tag=FiscalTag.NO_DEDUCIBLE
    )
    await use_case.execute(USER, input_)

    with pytest.raises(DuplicateCategoryName):
        await use_case.execute(USER, input_)


@pytest.mark.unit
async def test_patch_categoria_del_sistema_lanza_system_category_immutable() -> None:
    repos = await build_ledger_repos()
    use_case = _update_category_use_case(repos)

    with pytest.raises(SystemCategoryImmutable):
        await use_case.execute(USER, SIN_CATEGORIA_ID, CategoryPatch(name="Otro nombre"))


@pytest.mark.unit
async def test_borrar_categoria_del_sistema_lanza_system_category_immutable() -> None:
    repos = await build_ledger_repos()
    use_case = _delete_category_use_case(repos)

    with pytest.raises(SystemCategoryImmutable):
        await use_case.execute(USER, SIN_CATEGORIA_ID)


@pytest.mark.unit
async def test_borrar_categoria_propia_reasigna_transacciones_y_borra_reglas() -> None:
    repos = await build_ledger_repos()
    create_category = _create_category_use_case(repos)
    category = await create_category.execute(
        USER, CategoryInput(name="Antojos", icon=None, color=None, fiscal_tag=FiscalTag.DONACION)
    )
    await repos.merchant_rules.upsert(
        MerchantRule(id=uuid4(), user_id=USER, merchant_pattern="EXITO", category_id=category.id)
    )
    manual_use_case = CreateManualTransaction(
        transactions=repos.transactions,
        sources=repos.sources,
        categories=repos.categories,
        accounts=repos.accounts,
        events=repos.events,
        clock=FixedClock(NOW),
        ids=repos.ids,
        uow=repos.uow,
    )

    tx = await manual_use_case.execute(
        ManualTransactionCommand(
            user_id=USER,
            amount=Decimal("10000"),
            direction=Direction.DEBIT,
            occurred_at=NOW,
            category_id=category.id,
            merchant=None,
            description=None,
            account_id=None,
            notes=None,
        )
    )

    delete_use_case = _delete_category_use_case(repos)
    await delete_use_case.execute(USER, category.id)

    refreshed = await repos.transactions.get(USER, tx.id)
    assert refreshed is not None
    assert refreshed.category_id == SIN_CATEGORIA_ID
    assert refreshed.fiscal_tag == FiscalTag.NO_DEDUCIBLE
    assert await repos.merchant_rules.list_for_user(USER) == []
    assert await repos.categories.get_visible(USER, category.id) is None


@pytest.mark.unit
async def test_crear_cuenta_duplicada_lanza_duplicate_account() -> None:
    repos = await build_ledger_repos()
    use_case = _create_account_use_case(repos)
    input_ = AccountInput(
        bank=Bank.BANCOLOMBIA, kind=AccountKind.SAVINGS, last4="1234", alias="Principal"
    )
    await use_case.execute(USER, input_)

    with pytest.raises(DuplicateAccount):
        await use_case.execute(USER, input_)


@pytest.mark.unit
async def test_crear_cuenta_con_last4_invalido_lanza_invalid_last4() -> None:
    repos = await build_ledger_repos()
    use_case = _create_account_use_case(repos)
    input_ = AccountInput(bank=Bank.BANCOLOMBIA, kind=AccountKind.SAVINGS, last4="abcd", alias=None)

    with pytest.raises(InvalidLast4):
        await use_case.execute(USER, input_)


@pytest.mark.unit
async def test_list_categories_incluye_sistema_y_propias() -> None:
    repos = await build_ledger_repos()
    create_category = _create_category_use_case(repos)
    own = await create_category.execute(
        USER,
        CategoryInput(name="Hobbies", icon=None, color=None, fiscal_tag=FiscalTag.NO_DEDUCIBLE),
    )
    use_case = ListCategories(categories=repos.categories)

    categories = await use_case.execute(USER)

    ids = {c.id for c in categories}
    assert own.id in ids
    assert SIN_CATEGORIA_ID in ids


@pytest.mark.unit
async def test_patch_categoria_propia_permite_renombrar() -> None:
    repos = await build_ledger_repos()
    create_category = _create_category_use_case(repos)
    category = await create_category.execute(
        USER, CategoryInput(name="Viejo", icon=None, color=None, fiscal_tag=FiscalTag.NO_DEDUCIBLE)
    )
    use_case = _update_category_use_case(repos)

    updated = await use_case.execute(USER, category.id, CategoryPatch(name="Nuevo"))

    assert updated.name == "Nuevo"
    persisted = await repos.categories.get_visible(USER, category.id)
    assert persisted is not None
    assert persisted.name == "Nuevo"


@pytest.mark.unit
async def test_list_accounts_solo_devuelve_las_propias() -> None:
    repos = await build_ledger_repos()
    use_case = _create_account_use_case(repos)
    account = await use_case.execute(
        USER,
        AccountInput(bank=Bank.BANCOLOMBIA, kind=AccountKind.SAVINGS, last4="7777", alias=None),
    )

    list_use_case = ListAccounts(accounts=repos.accounts)
    accounts = await list_use_case.execute(USER)

    assert [a.id for a in accounts] == [account.id]


@pytest.mark.unit
async def test_patch_cuenta_propia_edita_alias_y_last4() -> None:
    repos = await build_ledger_repos()
    create_use_case = _create_account_use_case(repos)
    account = await create_use_case.execute(
        USER,
        AccountInput(bank=Bank.BANCOLOMBIA, kind=AccountKind.SAVINGS, last4="8888", alias=None),
    )
    use_case = _update_account_use_case(repos)

    updated = await use_case.execute(USER, account.id, AccountPatch(last4="9999", alias="Ahorros"))

    assert updated.last4 == "9999"
    assert updated.alias == "Ahorros"


@pytest.mark.unit
async def test_patch_cuenta_con_last4_duplicado_lanza_duplicate_account() -> None:
    repos = await build_ledger_repos()
    create_use_case = _create_account_use_case(repos)
    await create_use_case.execute(
        USER,
        AccountInput(bank=Bank.BANCOLOMBIA, kind=AccountKind.SAVINGS, last4="1111", alias=None),
    )
    other = await create_use_case.execute(
        USER,
        AccountInput(bank=Bank.BANCOLOMBIA, kind=AccountKind.SAVINGS, last4="2222", alias=None),
    )
    use_case = _update_account_use_case(repos)

    with pytest.raises(DuplicateAccount):
        await use_case.execute(USER, other.id, AccountPatch(last4="1111"))


@pytest.mark.unit
async def test_borrar_cuenta_propia() -> None:
    repos = await build_ledger_repos()
    create_use_case = _create_account_use_case(repos)
    account = await create_use_case.execute(
        USER,
        AccountInput(bank=Bank.BANCOLOMBIA, kind=AccountKind.SAVINGS, last4="3333", alias=None),
    )
    use_case = _delete_account_use_case(repos)

    await use_case.execute(USER, account.id)

    assert await repos.accounts.get(USER, account.id) is None


@pytest.mark.unit
async def test_borrar_cuenta_ajena_lanza_account_not_found() -> None:
    repos = await build_ledger_repos()
    use_case = _delete_account_use_case(repos)

    with pytest.raises(AccountNotFound):
        await use_case.execute(USER, uuid4())
