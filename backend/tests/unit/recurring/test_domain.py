"""Dominio de recurring: calendario, validacion y matcher (spec 011 SS3, SS4, SS7)."""

from __future__ import annotations

from dataclasses import replace
from datetime import UTC, date, datetime, timedelta, timezone
from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from luka.modules.recurring.domain.entities import (
    Occurrence,
    RecurringExpense,
    normalize_text,
    validate_expense_fields,
)
from luka.modules.recurring.domain.enums import MatchedBy, OccurrenceStatus
from luka.modules.recurring.domain.errors import InvalidRecurringExpense
from luka.modules.recurring.domain.matcher import (
    TxCandidate,
    matches,
    pick_occurrence,
    reminder_offset_due,
    within_tolerance,
)
from luka.modules.recurring.domain.schedule import (
    colombia_date,
    due_date,
    months_between,
    next_month,
    parse_month,
    periods_to_ensure,
    window,
)

pytestmark = pytest.mark.unit

_BOGOTA = timezone(timedelta(hours=-5))
_NOW = datetime(2026, 10, 1, 12, 0, tzinfo=UTC)
_USER = uuid4()


def _expense(**overrides: object) -> RecurringExpense:
    base = RecurringExpense(
        id=uuid4(),
        user_id=_USER,
        name="Spotify",
        merchant_keyword="spotify",
        expected_amount=Decimal("16900.00"),
        amount_tolerance_pct=10,
        day_of_month=22,
        category_id=None,
        account_id=None,
        remind_days_before=1,
        active=True,
        created_at=_NOW,
        updated_at=_NOW,
    )
    return replace(base, **overrides)  # type: ignore[arg-type]


def _occurrence(expense: RecurringExpense, due: date, **overrides: object) -> Occurrence:
    base = Occurrence(
        id=uuid4(),
        user_id=expense.user_id,
        recurring_expense_id=expense.id,
        period=due.replace(day=1),
        due_date=due,
        status=OccurrenceStatus.PENDING,
        transaction_id=None,
        matched_by=None,
        paid_at=None,
        reminded_at=None,
    )
    return replace(base, **overrides)  # type: ignore[arg-type]


def _tx(
    *,
    amount: str = "16900.00",
    merchant: str | None = "SPOTIFY P3A9C1",
    when: datetime | None = None,
    account_id: UUID | None = None,
    is_expense_debit: bool = True,
) -> TxCandidate:
    return TxCandidate(
        id=uuid4(),
        amount=Decimal(amount),
        merchant=merchant,
        account_id=account_id,
        occurred_at=when or datetime(2026, 10, 22, 7, 12, tzinfo=_BOGOTA),
        is_expense_debit=is_expense_debit,
    )


# --- Calendario (caso 1) ---------------------------------------------------------


@pytest.mark.parametrize(
    ("period", "day", "expected"),
    [
        (date(2027, 2, 1), 31, date(2027, 2, 28)),
        (date(2028, 2, 1), 31, date(2028, 2, 29)),
        (date(2028, 2, 1), 29, date(2028, 2, 29)),
        (date(2027, 2, 1), 30, date(2027, 2, 28)),
        (date(2026, 4, 1), 31, date(2026, 4, 30)),
        (date(2026, 10, 1), 1, date(2026, 10, 1)),
        (date(2026, 10, 1), 22, date(2026, 10, 22)),
    ],
)
def test_due_date_usa_el_ultimo_dia_si_el_mes_es_mas_corto(
    period: date, day: int, expected: date
) -> None:
    assert due_date(period, day) == expected


def test_next_month_cruza_el_anio() -> None:
    assert next_month(date(2026, 12, 1)) == date(2027, 1, 1)
    assert next_month(date(2026, 10, 1)) == date(2026, 11, 1)


def test_periods_to_ensure_incluye_el_mes_actual_si_no_paso_la_ventana() -> None:
    today = date(2026, 10, 27)
    assert periods_to_ensure(today, today, 22) == [date(2026, 10, 1), date(2026, 11, 1)]


def test_periods_to_ensure_salta_el_mes_actual_si_se_creo_despues_de_la_ventana() -> None:
    today = date(2026, 10, 28)
    assert periods_to_ensure(today, today, 22) == [date(2026, 11, 1)]


def test_periods_to_ensure_usa_la_fecha_de_inicio_no_la_de_hoy() -> None:
    assert periods_to_ensure(date(2026, 10, 30), date(2026, 10, 3), 22) == [
        date(2026, 10, 1),
        date(2026, 11, 1),
    ]


def test_parse_month_y_meses_entre() -> None:
    assert parse_month("2026-09") == date(2026, 9, 1)
    assert months_between(date(2026, 9, 1), date(2027, 9, 1)) == 12
    for bad in ("2026-9", "202609", "2026-13", "abcd-01"):
        with pytest.raises(ValueError):
            parse_month(bad)


# --- Caso 3: fecha local de Colombia ------------------------------------------------


def test_colombia_date_toma_la_fecha_local_no_la_utc() -> None:
    late_night = datetime(2026, 10, 17, 4, 30, tzinfo=UTC)  # 23:30 del 16 en Bogota
    assert colombia_date(late_night) == date(2026, 10, 16)


def test_colombia_date_rechaza_naive() -> None:
    with pytest.raises(ValueError):
        colombia_date(datetime(2026, 10, 1, 12, 0))


# --- Validacion ------------------------------------------------------------------


def test_validate_limpia_espacios_y_cuantiza_el_monto() -> None:
    name, keyword, amount = validate_expense_fields(
        name="  Spotify   Familiar ",
        merchant_keyword=" spotify ",
        expected_amount="16900",
        amount_tolerance_pct=10,
        day_of_month=22,
        remind_days_before=2,
    )
    assert (name, keyword, amount) == ("Spotify Familiar", "spotify", Decimal("16900.00"))


@pytest.mark.parametrize(
    ("overrides", "field"),
    [
        ({"name": "   "}, "name"),
        ({"name": "x" * 61}, "name"),
        ({"merchant_keyword": "a"}, "merchant_keyword"),
        ({"merchant_keyword": "*-"}, "merchant_keyword"),
        ({"merchant_keyword": "x" * 41}, "merchant_keyword"),
        ({"expected_amount": "0"}, "expected_amount"),
        ({"expected_amount": "abc"}, "expected_amount"),
        ({"amount_tolerance_pct": 51}, "amount_tolerance_pct"),
        ({"amount_tolerance_pct": -1}, "amount_tolerance_pct"),
        ({"day_of_month": 0}, "day_of_month"),
        ({"day_of_month": 32}, "day_of_month"),
        ({"remind_days_before": 3}, "remind_days_before"),
    ],
)
def test_validate_rechaza_cada_campo_invalido(overrides: dict[str, object], field: str) -> None:
    fields: dict[str, object] = {
        "name": "Spotify",
        "merchant_keyword": "SPOTIFY",
        "expected_amount": "16900",
        "amount_tolerance_pct": 10,
        "day_of_month": 22,
        "remind_days_before": 1,
    }
    fields.update(overrides)
    with pytest.raises(InvalidRecurringExpense) as exc:
        validate_expense_fields(**fields)  # type: ignore[arg-type]
    assert exc.value.field == field


# --- Caso 4: normalizacion del comercio ---------------------------------------------


def test_normalize_text_quita_tildes_mayusculas_y_puntuacion() -> None:
    assert normalize_text("Pagó  Energía*EPM.") == "PAGO ENERGIA EPM"


def test_keyword_con_tildes_coincide_con_comercio_en_mayusculas() -> None:
    expense = _expense(merchant_keyword="energía")
    occ = _occurrence(expense, date(2026, 10, 22))
    assert matches(_tx(merchant="PAGO ENERGIA EPM"), occ, expense)


def test_comercio_vacio_o_nulo_nunca_coincide() -> None:
    expense = _expense()
    occ = _occurrence(expense, date(2026, 10, 22))
    assert not matches(_tx(merchant=None), occ, expense)
    assert not matches(_tx(merchant="  "), occ, expense)


def test_keyword_es_subcadena_del_comercio() -> None:
    expense = _expense()
    occ = _occurrence(expense, date(2026, 10, 22))
    assert matches(_tx(merchant="PAYU*SPOTIFY"), occ, expense)
    assert not matches(_tx(merchant="NETFLIX"), occ, expense)


# --- Caso 2: tolerancia de monto ------------------------------------------------------


@pytest.mark.parametrize(
    ("amount", "ok"),
    [("15210.00", True), ("18590.00", True), ("18591.00", False), ("15209.99", False)],
)
def test_borde_de_la_tolerancia(amount: str, ok: bool) -> None:
    assert within_tolerance(Decimal(amount), Decimal("16900.00"), 10) is ok


def test_tolerancia_cero_exige_monto_exacto() -> None:
    assert within_tolerance(Decimal("16900.00"), Decimal("16900.00"), 0)
    assert not within_tolerance(Decimal("16900.01"), Decimal("16900.00"), 0)


# --- Caso 3: ventana de fechas -------------------------------------------------------


@pytest.mark.parametrize(
    ("day", "ok"), [(17, True), (27, True), (16, False), (28, False), (22, True)]
)
def test_bordes_de_la_ventana(day: int, ok: bool) -> None:
    expense = _expense()
    occ = _occurrence(expense, date(2026, 10, 22))
    tx = _tx(when=datetime(2026, 10, day, 12, 0, tzinfo=_BOGOTA))
    assert matches(tx, occ, expense) is ok


def test_pago_de_noche_en_colombia_cuenta_por_la_fecha_local() -> None:
    expense = _expense()
    occ = _occurrence(expense, date(2026, 10, 22))
    # 23:30 del 16 en Bogota = 04:30 UTC del 17: queda fuera (ventana desde el 17).
    tx = _tx(when=datetime(2026, 10, 17, 4, 30, tzinfo=UTC))
    assert not matches(tx, occ, expense)
    assert window(date(2026, 10, 22)) == (date(2026, 10, 17), date(2026, 10, 27))


# --- Caso 5: tipo de transaccion -------------------------------------------------------


def test_ingreso_o_transferencia_no_empareja() -> None:
    expense = _expense()
    occ = _occurrence(expense, date(2026, 10, 22))
    assert not matches(_tx(is_expense_debit=False), occ, expense)


def test_cuenta_definida_exige_la_misma_cuenta() -> None:
    account = uuid4()
    expense = _expense(account_id=account)
    occ = _occurrence(expense, date(2026, 10, 22))
    assert matches(_tx(account_id=account), occ, expense)
    assert not matches(_tx(account_id=uuid4()), occ, expense)
    assert not matches(_tx(account_id=None), occ, expense)


def test_sin_cuenta_acepta_cualquier_cuenta() -> None:
    expense = _expense()
    occ = _occurrence(expense, date(2026, 10, 22))
    assert matches(_tx(account_id=uuid4()), occ, expense)


def test_ocurrencia_pagada_omitida_o_gasto_pausado_no_empareja() -> None:
    expense = _expense()
    due = date(2026, 10, 22)
    assert not matches(_tx(), _occurrence(expense, due, status=OccurrenceStatus.PAID), expense)
    assert not matches(_tx(), _occurrence(expense, due, status=OccurrenceStatus.SKIPPED), expense)
    paused = replace(expense, active=False)
    assert not matches(_tx(), _occurrence(paused, due), paused)


# --- Caso 6: ambiguedad ---------------------------------------------------------------


def test_dos_gastos_con_la_misma_keyword_gana_el_monto_mas_cercano() -> None:
    individual = _expense(expected_amount=Decimal("16900.00"))
    familiar = _expense(name="Spotify Familiar", expected_amount=Decimal("17500.00"))
    due = date(2026, 10, 22)
    occ_ind = _occurrence(individual, due)
    occ_fam = _occurrence(familiar, due)
    tx = _tx(amount="17400.00")

    chosen = pick_occurrence(tx, [(occ_ind, individual), (occ_fam, familiar)], rejected=())

    assert chosen == occ_fam


def test_mismo_monto_gana_la_fecha_mas_cercana() -> None:
    expense_a = _expense(day_of_month=20)
    expense_b = _expense(day_of_month=24)
    occ_a = _occurrence(expense_a, date(2026, 10, 20))
    occ_b = _occurrence(expense_b, date(2026, 10, 24))
    tx = _tx(when=datetime(2026, 10, 23, 9, 0, tzinfo=_BOGOTA))

    assert pick_occurrence(tx, [(occ_a, expense_a), (occ_b, expense_b)], rejected=()) == occ_b


def test_empate_total_no_empareja() -> None:
    expense_a = _expense()
    expense_b = _expense(name="Spotify 2")
    due = date(2026, 10, 22)
    occ_a = _occurrence(expense_a, due)
    occ_b = _occurrence(expense_b, due)

    assert pick_occurrence(_tx(), [(occ_a, expense_a), (occ_b, expense_b)], rejected=()) is None


def test_sin_candidatas_devuelve_none() -> None:
    assert pick_occurrence(_tx(), [], rejected=()) is None


# --- Caso 7: rechazo previo --------------------------------------------------------------


def test_rechazo_previo_no_se_reempareja() -> None:
    expense = _expense()
    occ = _occurrence(expense, date(2026, 10, 22))
    assert pick_occurrence(_tx(), [(occ, expense)], rejected={occ.id}) is None


def test_rechazo_de_una_ocurrencia_no_bloquea_las_demas() -> None:
    expense_a = _expense()
    expense_b = _expense(expected_amount=Decimal("17000.00"))
    due = date(2026, 10, 22)
    occ_a = _occurrence(expense_a, due)
    occ_b = _occurrence(expense_b, due)

    assert pick_occurrence(_tx(), [(occ_a, expense_a), (occ_b, expense_b)], {occ_a.id}) == occ_b


# --- Caso 10: recordatorios de 7, 2 y 1 dias --------------------------------------------


@pytest.mark.parametrize(
    ("today", "last", "expected"),
    [
        (date(2026, 10, 14), None, None),  # 8 dias antes: todavia no
        (date(2026, 10, 15), None, 7),
        (date(2026, 10, 16), None, 7),  # el cron fallo el dia 15: sale igual
        (date(2026, 10, 16), 7, None),  # ya salio el de 7
        (date(2026, 10, 20), 7, 2),
        (date(2026, 10, 20), 2, None),
        (date(2026, 10, 21), 2, 1),
        (date(2026, 10, 21), None, 1),  # sin avisos previos: el mas cercano
        (date(2026, 10, 22), 2, 1),  # el dia del pago cuenta como el de 1
        (date(2026, 10, 22), 1, None),
        (date(2026, 10, 23), None, None),  # vencido: nunca se avisa
    ],
)
def test_reminder_offset_due_elige_el_aviso_que_toca(
    today: date, last: int | None, expected: int | None
) -> None:
    expense = _expense()
    occ = _occurrence(expense, date(2026, 10, 22), last_reminder_days=last)
    assert reminder_offset_due(occ, expense, today) == expected


def test_no_avisa_pagado_omitido_o_pausado() -> None:
    expense = _expense()
    today = date(2026, 10, 21)
    due = date(2026, 10, 22)
    paid = _occurrence(
        expense, due, status=OccurrenceStatus.PAID, matched_by=MatchedBy.AUTO, paid_at=_NOW
    )
    assert reminder_offset_due(paid, expense, today) is None
    skipped = _occurrence(expense, due, status=OccurrenceStatus.SKIPPED)
    assert reminder_offset_due(skipped, expense, today) is None
    paused = replace(expense, active=False)
    assert reminder_offset_due(_occurrence(paused, due), paused, today) is None


# --- Nombre como palabra clave (spec 011 SS4) ---------------------------------------


def test_keyword_tokens_ignora_palabras_genericas_y_cortas() -> None:
    from luka.modules.recurring.domain.entities import keyword_tokens  # noqa: PLC0415

    assert keyword_tokens("Pago de Spotify Familiar") == ("SPOTIFY", "FAMILIAR")
    assert keyword_tokens("TV") == ()
    assert keyword_tokens("Plan celular Claro") == ("CELULAR", "CLARO")


def test_basta_una_palabra_del_nombre_en_el_comercio() -> None:
    expense = _expense(merchant_keyword="Spotify Familiar")
    occ = _occurrence(expense, date(2026, 10, 22))
    assert matches(_tx(merchant="SPOTIFY P3A9C1"), occ, expense)
    arriendo = _expense(merchant_keyword="Arriendo")
    occ_a = _occurrence(arriendo, date(2026, 10, 22))
    assert not matches(_tx(merchant="TRANSF INMOBILIARIA XYZ"), occ_a, arriendo)


def test_un_nombre_de_solo_palabras_cortas_nunca_empareja() -> None:
    expense = _expense(merchant_keyword="TV")
    occ = _occurrence(expense, date(2026, 10, 22))
    assert not matches(_tx(merchant="TV CABLE"), occ, expense)


def test_validacion_reporta_la_keyword_en_el_campo_pedido() -> None:
    with pytest.raises(InvalidRecurringExpense) as exc:
        validate_expense_fields(
            name="*",
            merchant_keyword="*",
            expected_amount="1000",
            amount_tolerance_pct=0,
            day_of_month=5,
            remind_days_before=1,
            keyword_field="name",
        )
    assert exc.value.field == "name"
