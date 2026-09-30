"""Casos de uso de recurring con dobles en memoria (spec 011 SS3-SS4.1)."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta, timezone
from decimal import Decimal
from uuid import uuid4

import pytest

from luka.modules.recurring.application.dto import ExpenseInput, ExpensePatch
from luka.modules.recurring.application.use_cases.background import (
    EnsureAllOccurrences,
    MatchCapturedTransaction,
    RevertDeletedTransaction,
)
from luka.modules.recurring.application.use_cases.manage_expenses import (
    CreateExpense,
    DeleteExpense,
    ListExpenses,
    UpdateExpense,
)
from luka.modules.recurring.application.use_cases.occurrences import (
    GetOccurrence,
    ListOccurrences,
    MarkPaid,
    Skip,
    Unmark,
)
from luka.modules.recurring.domain.enums import MatchedBy, OccurrenceStatus
from luka.modules.recurring.domain.errors import (
    AccountNotFound,
    CategoryNotFound,
    InvalidMonthRange,
    OccurrenceNotFound,
    OccurrenceNotPaid,
    RecurringExpenseNotFound,
    TransactionAlreadyPays,
    TransactionNotExpense,
    TransactionNotFound,
)
from luka.modules.recurring.domain.matcher import TxCandidate
from recurring.fakes import RecurringRepos

pytestmark = pytest.mark.unit

_BOGOTA = timezone(timedelta(hours=-5))
# 15 de octubre de 2026, 10:00 en Colombia.
_NOW = datetime(2026, 10, 15, 15, 0, tzinfo=UTC)
_USER = uuid4()
_OTHER = uuid4()


def _repos() -> RecurringRepos:
    return RecurringRepos(_NOW)


def _create(repos: RecurringRepos) -> CreateExpense:
    return CreateExpense(
        expenses=repos.expenses,
        occurrences=repos.occurrences,
        rejections=repos.rejections,
        ledger=repos.ledger,
        clock=repos.clock,
        ids=repos.ids,
        uow=repos.uow,
    )


def _update(repos: RecurringRepos) -> UpdateExpense:
    return UpdateExpense(
        expenses=repos.expenses,
        occurrences=repos.occurrences,
        rejections=repos.rejections,
        ledger=repos.ledger,
        clock=repos.clock,
        ids=repos.ids,
        uow=repos.uow,
    )


def _match(repos: RecurringRepos) -> MatchCapturedTransaction:
    return MatchCapturedTransaction(
        occurrences=repos.occurrences,
        rejections=repos.rejections,
        clock=repos.clock,
        uow=repos.uow,
    )


def _input(**overrides: object) -> ExpenseInput:
    fields: dict[str, object] = {
        "name": "Spotify",
        "merchant_keyword": "spotify",
        "expected_amount": Decimal("16900"),
        "day_of_month": 22,
    }
    fields.update(overrides)
    return ExpenseInput(**fields)  # type: ignore[arg-type]


def _tx(day: int = 22, amount: str = "16900.00", merchant: str = "SPOTIFY P3A9C1") -> TxCandidate:
    return TxCandidate(
        id=uuid4(),
        amount=Decimal(amount),
        merchant=merchant,
        account_id=None,
        occurred_at=datetime(2026, 10, day, 7, 0, tzinfo=_BOGOTA),
        is_expense_debit=True,
    )


def _periods(repos: RecurringRepos) -> list[date]:
    return sorted(o.period for o in repos.occurrences.rows.values())


def _october(repos: RecurringRepos):
    (occ,) = [o for o in repos.occurrences.rows.values() if o.period == date(2026, 10, 1)]
    return occ


# --- Crear ----------------------------------------------------------------------------


async def test_crear_guarda_limpio_y_genera_octubre_y_noviembre() -> None:
    repos = _repos()

    expense = await _create(repos).execute(_USER, _input(name="  Spotify  "))

    assert expense.name == "Spotify"
    assert expense.expected_amount == Decimal("16900.00")
    assert _periods(repos) == [date(2026, 10, 1), date(2026, 11, 1)]
    assert _october(repos).due_date == date(2026, 10, 22)
    assert repos.uow.commits == 1


async def test_crear_despues_de_la_ventana_empieza_el_mes_siguiente() -> None:
    repos = _repos()

    await _create(repos).execute(_USER, _input(day_of_month=5))

    assert _periods(repos) == [date(2026, 11, 1)]


async def test_crear_barre_el_pago_ya_capturado() -> None:
    repos = _repos()
    tx = _tx(day=14, amount="16900.00")
    repos.ledger.add(_USER, tx)

    await _create(repos).execute(_USER, _input(day_of_month=15))

    october = _october(repos)
    assert october.status is OccurrenceStatus.PAID
    assert october.transaction_id == tx.id
    assert october.matched_by is MatchedBy.AUTO


async def test_crear_con_categoria_o_cuenta_no_visible_falla() -> None:
    repos = _repos()
    with pytest.raises(CategoryNotFound):
        await _create(repos).execute(_USER, _input(category_id=uuid4()))
    with pytest.raises(AccountNotFound):
        await _create(repos).execute(_USER, _input(account_id=uuid4()))
    visible = uuid4()
    repos.ledger.categories.add(visible)
    expense = await _create(repos).execute(_USER, _input(category_id=visible))
    assert expense.category_id == visible


# --- Editar ---------------------------------------------------------------------------


async def test_cambiar_el_dia_recalcula_las_pendientes() -> None:
    repos = _repos()
    expense = await _create(repos).execute(_USER, _input())

    await _update(repos).execute(_USER, expense.id, ExpensePatch(day_of_month=31))

    dues = sorted(o.due_date for o in repos.occurrences.rows.values())
    assert dues == [date(2026, 10, 31), date(2026, 11, 30)]


async def test_pausar_borra_las_futuras_y_reanudar_las_recrea() -> None:
    repos = _repos()
    expense = await _create(repos).execute(_USER, _input())

    await _update(repos).execute(_USER, expense.id, ExpensePatch(active=False))
    assert _periods(repos) == [date(2026, 10, 1)]

    await _update(repos).execute(_USER, expense.id, ExpensePatch(active=True))
    assert _periods(repos) == [date(2026, 10, 1), date(2026, 11, 1)]


async def test_cambiar_la_keyword_repite_el_barrido() -> None:
    repos = _repos()
    tx = _tx(day=20, merchant="NETFLIX.COM")
    repos.ledger.add(_USER, tx)
    expense = await _create(repos).execute(_USER, _input())
    assert _october(repos).status is OccurrenceStatus.PENDING

    await _update(repos).execute(
        _USER, expense.id, ExpensePatch(merchant_keyword="netflix", name="Netflix")
    )

    assert _october(repos).transaction_id == tx.id


async def test_editar_gasto_ajeno_o_inexistente_falla() -> None:
    repos = _repos()
    expense = await _create(repos).execute(_USER, _input())
    with pytest.raises(RecurringExpenseNotFound):
        await _update(repos).execute(_OTHER, expense.id, ExpensePatch(name="X"))
    with pytest.raises(RecurringExpenseNotFound):
        await DeleteExpense(expenses=repos.expenses, uow=repos.uow).execute(_OTHER, expense.id)


async def test_listar_ordena_por_dia_y_nombre() -> None:
    repos = _repos()
    await _create(repos).execute(_USER, _input(name="Zeta", day_of_month=5))
    await _create(repos).execute(_USER, _input(name="arriendo", day_of_month=5))
    await _create(repos).execute(_USER, _input(name="Agua", day_of_month=1))

    names = [e.name for e in await ListExpenses(expenses=repos.expenses).execute(_USER)]

    assert names == ["Agua", "arriendo", "Zeta"]


# --- Emparejar y acciones -----------------------------------------------------------------


async def test_captura_empareja_y_una_repetida_no_hace_nada() -> None:
    repos = _repos()
    await _create(repos).execute(_USER, _input())
    tx = _tx()

    first = await _match(repos).execute(_USER, tx)
    second = await _match(repos).execute(_USER, tx)

    assert first == _october(repos).id
    assert second is None


async def test_deshacer_registra_rechazo_y_no_se_reempareja() -> None:
    repos = _repos()
    await _create(repos).execute(_USER, _input())
    tx = _tx()
    await _match(repos).execute(_USER, tx)
    october = _october(repos)

    await Unmark(occurrences=repos.occurrences, rejections=repos.rejections, uow=repos.uow).execute(
        _USER, october.id
    )

    assert (october.id, tx.id) in repos.rejections.pairs
    assert await _match(repos).execute(_USER, tx) is None
    with pytest.raises(OccurrenceNotPaid):
        await Unmark(
            occurrences=repos.occurrences, rejections=repos.rejections, uow=repos.uow
        ).execute(_USER, october.id)


async def test_marcar_pagado_valida_la_transaccion() -> None:
    repos = _repos()
    await _create(repos).execute(_USER, _input())
    await _create(repos).execute(_USER, _input(name="Otro", merchant_keyword="otro"))
    october, other = sorted(
        (o for o in repos.occurrences.rows.values() if o.period == date(2026, 10, 1)),
        key=lambda o: str(o.recurring_expense_id),
    )
    mark = MarkPaid(
        occurrences=repos.occurrences, ledger=repos.ledger, clock=repos.clock, uow=repos.uow
    )
    tx = _tx()
    income = TxCandidate(
        id=uuid4(),
        amount=Decimal("1"),
        merchant=None,
        account_id=None,
        occurred_at=_NOW,
        is_expense_debit=False,
    )
    repos.ledger.add(_USER, tx)
    repos.ledger.add(_USER, income)

    with pytest.raises(TransactionNotFound):
        await mark.execute(_USER, october.id, uuid4())
    with pytest.raises(TransactionNotExpense):
        await mark.execute(_USER, october.id, income.id)
    await mark.execute(_USER, october.id, tx.id)
    with pytest.raises(TransactionAlreadyPays):
        await mark.execute(_USER, other.id, tx.id)
    with pytest.raises(OccurrenceNotFound):
        await mark.execute(_OTHER, october.id, None)

    paid = repos.occurrences.rows[october.id]
    assert paid.status is OccurrenceStatus.PAID
    assert paid.matched_by is MatchedBy.MANUAL
    assert paid.paid_at == _NOW


async def test_omitir_libera_la_transaccion_y_no_se_empareja() -> None:
    repos = _repos()
    await _create(repos).execute(_USER, _input())
    tx = _tx()
    await _match(repos).execute(_USER, tx)
    october = _october(repos)

    await Skip(occurrences=repos.occurrences, uow=repos.uow).execute(_USER, october.id)

    skipped = repos.occurrences.rows[october.id]
    assert skipped.status is OccurrenceStatus.SKIPPED
    assert skipped.transaction_id is None


async def test_borrar_la_transaccion_devuelve_a_pendiente() -> None:
    repos = _repos()
    await _create(repos).execute(_USER, _input())
    tx = _tx()
    await _match(repos).execute(_USER, tx)
    revert = RevertDeletedTransaction(occurrences=repos.occurrences, uow=repos.uow)

    assert await revert.execute(_USER, tx.id) is True
    assert _october(repos).status is OccurrenceStatus.PENDING
    assert await revert.execute(_USER, tx.id) is False


async def test_listar_ocurrencias_con_transaccion_y_rango_maximo() -> None:
    repos = _repos()
    await _create(repos).execute(_USER, _input())
    tx = _tx()
    repos.ledger.add(_USER, tx)
    await _match(repos).execute(_USER, tx)
    list_use_case = ListOccurrences(
        occurrences=repos.occurrences, expenses=repos.expenses, ledger=repos.ledger
    )

    views = await list_use_case.execute(_USER, date(2026, 10, 1), date(2026, 11, 1))

    assert [v.occurrence.period for v in views] == [date(2026, 10, 1), date(2026, 11, 1)]
    assert views[0].transaction is not None
    assert views[0].transaction.id == tx.id
    with pytest.raises(InvalidMonthRange):
        await list_use_case.execute(_USER, date(2026, 1, 1), date(2027, 1, 1))
    with pytest.raises(InvalidMonthRange):
        await list_use_case.execute(_USER, date(2026, 5, 1), date(2026, 4, 1))

    single = await GetOccurrence(
        occurrences=repos.occurrences, expenses=repos.expenses, ledger=repos.ledger
    ).execute(_USER, views[0].occurrence.id)
    assert single.expense.name == "Spotify"


async def test_cron_crea_lo_que_falta_y_respeta_la_fecha_de_creacion() -> None:
    repos = _repos()
    expense = await _create(repos).execute(_USER, _input())
    repos.occurrences.rows.clear()

    summary = await EnsureAllOccurrences(
        expenses=repos.expenses,
        occurrences=repos.occurrences,
        clock=repos.clock,
        ids=repos.ids,
        uow=repos.uow,
    ).execute()

    assert summary.expenses == 1
    assert summary.created == 2
    assert all(o.recurring_expense_id == expense.id for o in repos.occurrences.rows.values())


# --- Recordatorios (spec 011 SS5) ----------------------------------------------------------


class _Bus:
    def __init__(self) -> None:
        self.events: list[object] = []

    async def publish(self, event: object) -> None:
        self.events.append(event)


async def test_avisa_a_los_7_2_y_1_dias_una_vez_cada_uno() -> None:
    from luka.modules.recurring.application.use_cases.background import (  # noqa: PLC0415
        PublishDueReminders,
        ReminderStatus,
        reminder_event_id,
    )
    from luka.modules.recurring.events import PaymentDueSoon  # noqa: PLC0415

    repos = RecurringRepos(datetime(2026, 10, 15, 14, 0, tzinfo=UTC))
    await _create(repos).execute(_USER, _input())
    status = ReminderStatus(occurrences=repos.occurrences, clock=repos.clock, uow=repos.uow)
    sent: list[int] = []

    for day in (15, 16, 20, 21, 22):
        repos.clock._now = datetime(2026, 10, day, 14, 0, tzinfo=UTC)
        bus = _Bus()
        await PublishDueReminders(
            occurrences=repos.occurrences, events=bus, clock=repos.clock
        ).execute()
        for event in bus.events:
            assert isinstance(event, PaymentDueSoon)
            assert event.event_id == reminder_event_id(event.occurrence_id, event.days_before)
            assert await status.still_due(event.occurrence_id, event.days_before)
            assert await status.mark_reminded(event.occurrence_id, event.days_before)
            assert not await status.mark_reminded(event.occurrence_id, event.days_before)
            sent.append(event.days_before)

    assert sent == [7, 2, 1]
    assert await status.still_due(uuid4(), 1) is False


async def test_no_publica_antes_de_tiempo_ni_si_ya_esta_pagado() -> None:
    from luka.modules.recurring.application.use_cases.background import (  # noqa: PLC0415
        PublishDueReminders,
    )

    # 14 de octubre: faltan 8 dias para Spotify (22) y 7 para Netflix (21), que ya se pago.
    repos = RecurringRepos(datetime(2026, 10, 14, 14, 0, tzinfo=UTC))
    await _create(repos).execute(_USER, _input())
    await _create(repos).execute(
        _USER, _input(name="Netflix", merchant_keyword="netflix", day_of_month=21)
    )
    tx = _tx(day=20, merchant="NETFLIX")
    await _match(repos).execute(_USER, tx)
    bus = _Bus()

    published = await PublishDueReminders(
        occurrences=repos.occurrences, events=bus, clock=repos.clock
    ).execute()

    assert published == 0


async def test_sin_keyword_usa_el_nombre_y_renombrar_la_mueve() -> None:
    repos = _repos()

    expense = await _create(repos).execute(_USER, _input(merchant_keyword=None))
    assert expense.merchant_keyword == "Spotify"
    assert expense.amount_tolerance_pct == 0

    renamed = await _update(repos).execute(_USER, expense.id, ExpensePatch(name="YouTube Premium"))
    assert renamed.merchant_keyword == "YouTube Premium"
