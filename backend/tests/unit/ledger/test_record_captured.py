"""Tests unitarios de `RecordCapturedTransaction` (spec 004 SS3/SS4, spec 006 SS4.3)."""

from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from finanzia.modules.ledger.application.dto import CapturedTransactionCommand, SourceInput
from finanzia.modules.ledger.application.use_cases.record_captured_transaction import (
    RecordCapturedTransaction,
)
from finanzia.modules.ledger.domain.entities import Category, LinkedAccount, MerchantRule
from finanzia.modules.ledger.domain.enums import (
    AccountKind,
    Bank,
    Channel,
    Direction,
    FiscalTag,
    Kind,
)
from finanzia.modules.ledger.domain.merchant import normalize_merchant
from finanzia.modules.ledger.domain.system_categories import SIN_CATEGORIA_ID
from finanzia.modules.ledger.events import TransactionCaptured
from ledger.fakes import FixedClock, InMemoryTransactionRepo, build_ledger_repos

NOW = datetime(2024, 3, 1, 12, 0, 0, tzinfo=UTC)
USER = uuid4()


def _cmd(  # noqa: PLR0913 - builder de comando con un default por campo
    *,
    bank: Bank = Bank.BANCOLOMBIA,
    amount: Decimal = Decimal("50000"),
    direction: Direction = Direction.DEBIT,
    occurred_at: datetime = NOW,
    last4: str | None = "1234",
    merchant: str | None = "EXITO BOGOTA",
    description: str | None = None,
    suggested_category_slug: str | None = None,
    parsed_by: str = "rule:bancolombia:debito",
    confidence: float | None = 0.9,
    source: SourceInput | None = None,
) -> CapturedTransactionCommand:
    return CapturedTransactionCommand(
        user_id=USER,
        bank=bank,
        amount=amount,
        direction=direction,
        occurred_at=occurred_at,
        last4=last4,
        merchant=merchant,
        description=description,
        suggested_category_slug=suggested_category_slug,
        parsed_by=parsed_by,
        confidence=confidence,
        source=source or SourceInput(Channel.EMAIL, uuid4(), occurred_at),
    )


def _make_use_case(repos, *, transactions=None) -> RecordCapturedTransaction:
    return RecordCapturedTransaction(
        transactions=transactions or repos.transactions,
        sources=repos.sources,
        categories=repos.categories,
        accounts=repos.accounts,
        merchant_rules=repos.merchant_rules,
        events=repos.events,
        clock=FixedClock(NOW),
        ids=repos.ids,
        uow=repos.uow,
    )


@pytest.mark.unit
async def test_mismo_comando_dos_veces_produce_una_sola_transaccion_y_evento() -> None:
    """AC-5.2: reintentar exactamente el mismo comando no duplica nada."""
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    cmd = _cmd()

    first = await use_case.execute(cmd)
    second = await use_case.execute(cmd)

    assert first.created is True
    assert second.created is False
    assert second.transaction.id == first.transaction.id
    assert second.source_attached is False  # mismo raw_message_id: idempotente
    assert len(await repos.sources.list_for(first.transaction.id)) == 1
    assert len(repos.events.events) == 1
    assert isinstance(repos.events.events[0], TransactionCaptured)


@pytest.mark.unit
async def test_email_y_notificacion_de_la_misma_compra_agregan_una_segunda_fuente() -> None:
    """AC-5.1: mismos datos, +40s, `raw_message_id` distintos -> 1 tx, 2 fuentes."""
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    cmd_email = _cmd(source=SourceInput(Channel.EMAIL, uuid4(), NOW))
    later = NOW + timedelta(seconds=40)
    cmd_notification = _cmd(
        occurred_at=later, source=SourceInput(Channel.NOTIFICATION, uuid4(), later)
    )

    first = await use_case.execute(cmd_email)
    second = await use_case.execute(cmd_notification)

    assert first.created is True
    assert second.created is False
    assert second.transaction.id == first.transaction.id
    assert second.source_attached is True
    sources = await repos.sources.list_for(first.transaction.id)
    assert len(sources) == 2
    assert len(repos.events.events) == 1


@pytest.mark.unit
async def test_mismo_monto_doce_minutos_despues_es_una_transaccion_distinta() -> None:
    """AC-5.3: fuera de la ventana de 10 min -> dos transacciones independientes."""
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    later = NOW + timedelta(minutes=12)
    cmd_first = _cmd(source=SourceInput(Channel.EMAIL, uuid4(), NOW))
    cmd_second = _cmd(occurred_at=later, source=SourceInput(Channel.EMAIL, uuid4(), later))

    first = await use_case.execute(cmd_first)
    second = await use_case.execute(cmd_second)

    assert first.created is True
    assert second.created is True
    assert first.transaction.id != second.transaction.id
    assert len(repos.events.events) == 2


@pytest.mark.unit
async def test_regla_de_comercio_aprendida_gana_sobre_la_sugerencia_del_parser() -> None:
    """AC-7.1 / spec 006 SS4.3: la regla aprendida tiene prioridad sobre el parser."""
    repos = await build_ledger_repos()
    custom_category = Category(
        id=uuid4(),
        user_id=USER,
        slug=None,
        name="Compras personales",
        icon=None,
        color=None,
        fiscal_tag=FiscalTag.NO_DEDUCIBLE,
    )
    await repos.categories.add(custom_category)
    await repos.merchant_rules.upsert(
        MerchantRule(
            id=uuid4(),
            user_id=USER,
            merchant_pattern=normalize_merchant("EXITO BOGOTA"),
            category_id=custom_category.id,
        )
    )
    use_case = _make_use_case(repos)
    cmd = _cmd(merchant="EXITO BOGOTA", suggested_category_slug="mercado")

    result = await use_case.execute(cmd)

    assert result.transaction.category_id == custom_category.id


@pytest.mark.unit
async def test_slug_sugerido_desconocido_cae_en_sin_categoria() -> None:
    repos = await build_ledger_repos()
    use_case = _make_use_case(repos)
    cmd = _cmd(merchant="COMERCIO NUEVO", suggested_category_slug="slug-inexistente")

    result = await use_case.execute(cmd)

    assert result.transaction.category_id == SIN_CATEGORIA_ID


async def _link_account(repos, *, bank: Bank, last4: str):
    account = LinkedAccount(
        id=uuid4(), user_id=USER, bank=bank, kind=AccountKind.SAVINGS, last4=last4, alias=None
    )
    await repos.accounts.add(account)
    return account


@pytest.mark.unit
async def test_debito_bancolombia_y_credito_nequi_del_mismo_monto_quedan_emparejados() -> None:
    """AC-6.1: dos capturas de cuentas propias, mismo monto y direccion opuesta -> pareja."""
    repos = await build_ledger_repos()
    await _link_account(repos, bank=Bank.BANCOLOMBIA, last4="1111")
    await _link_account(repos, bank=Bank.NEQUI, last4="2222")
    use_case = _make_use_case(repos)

    debit = await use_case.execute(
        _cmd(
            bank=Bank.BANCOLOMBIA,
            last4="1111",
            direction=Direction.DEBIT,
            merchant=None,
            description="Transferencia a Nequi",
            source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW),
        )
    )
    credit = await use_case.execute(
        _cmd(
            bank=Bank.NEQUI,
            last4="2222",
            direction=Direction.CREDIT,
            merchant=None,
            description="Transferencia recibida",
            occurred_at=NOW + timedelta(minutes=5),
            source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW + timedelta(minutes=5)),
        )
    )

    refreshed_debit = await repos.transactions.get(USER, debit.transaction.id)
    assert refreshed_debit is not None
    assert refreshed_debit.kind == Kind.TRANSFER
    assert refreshed_debit.transfer_auto is True
    assert refreshed_debit.transfer_pair_id == credit.transaction.id

    assert credit.transaction.kind == Kind.TRANSFER
    assert credit.transaction.transfer_auto is True
    assert credit.transaction.transfer_pair_id == debit.transaction.id


@pytest.mark.unit
async def test_tercer_candidato_ambiguo_no_empareja_a_nadie() -> None:
    """AC-6.2: mas de un candidato posible -> nadie queda emparejado."""
    repos = await build_ledger_repos()
    await _link_account(repos, bank=Bank.BANCOLOMBIA, last4="1111")
    await _link_account(repos, bank=Bank.DAVIVIENDA, last4="3333")
    await _link_account(repos, bank=Bank.NEQUI, last4="2222")
    use_case = _make_use_case(repos)

    debit_a = await use_case.execute(
        _cmd(
            bank=Bank.BANCOLOMBIA,
            last4="1111",
            direction=Direction.DEBIT,
            merchant=None,
            source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW),
        )
    )
    debit_b = await use_case.execute(
        _cmd(
            bank=Bank.DAVIVIENDA,
            last4="3333",
            direction=Direction.DEBIT,
            merchant=None,
            source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW),
        )
    )
    credit = await use_case.execute(
        _cmd(
            bank=Bank.NEQUI,
            last4="2222",
            direction=Direction.CREDIT,
            merchant=None,
            source=SourceInput(Channel.NOTIFICATION, uuid4(), NOW),
        )
    )

    assert credit.transaction.transfer_pair_id is None
    assert credit.transaction.kind != Kind.TRANSFER
    refreshed_a = await repos.transactions.get(USER, debit_a.transaction.id)
    refreshed_b = await repos.transactions.get(USER, debit_b.transaction.id)
    assert refreshed_a is not None
    assert refreshed_b is not None
    assert refreshed_a.transfer_pair_id is None
    assert refreshed_b.transfer_pair_id is None


class _RaceTransactionRepo(InMemoryTransactionRepo):
    """Simula una carrera: la primera insercion "gana" en otro proceso, no en este."""

    def __init__(self, sources) -> None:
        super().__init__(sources=sources)
        self._first_call = True

    async def insert_if_absent(self, tx) -> UUID | None:
        if self._first_call:
            self._first_call = False
            await super().insert_if_absent(tx)
            return None
        return await super().insert_if_absent(tx)


@pytest.mark.unit
async def test_carrera_de_insercion_adjunta_la_fuente_a_la_fila_existente() -> None:
    repos = await build_ledger_repos()
    race_repo = _RaceTransactionRepo(repos.sources)
    use_case = _make_use_case(repos, transactions=race_repo)

    result = await use_case.execute(_cmd())

    assert result.created is False
    assert result.source_attached is True
    assert len(repos.events.events) == 0
