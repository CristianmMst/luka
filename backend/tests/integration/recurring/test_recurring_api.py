"""Integracion de gastos fijos: API, barrido, consumers e idempotencia (spec 011, 005 SS10).

La API usa el reloj real, asi que las fechas se calculan desde "hoy" en Colombia:
un gasto fijo con `day_of_month = hoy` tiene su ocurrencia del mes actual y la del
siguiente, y un pago registrado hoy cae dentro de la ventana de deteccion.
"""

from __future__ import annotations

import asyncio
from collections.abc import Awaitable, Callable
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal
from typing import Any
from uuid import UUID, uuid4
from zoneinfo import ZoneInfo

import pytest
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser

from luka.modules.ledger.domain.enums import Direction, FiscalTag, Kind
from luka.modules.ledger.events import TransactionCaptured, TransactionDeleted
from luka.modules.recurring import public as recurring_public
from luka.shared.clock import SystemClock

pytestmark = pytest.mark.integration

_BOGOTA = ZoneInfo("America/Bogota")


def _today() -> date:
    return datetime.now(_BOGOTA).date()


def _month(day: date) -> str:
    return day.strftime("%Y-%m")


def _next_month(day: date) -> str:
    first = day.replace(day=1)
    following = (first + timedelta(days=32)).replace(day=1)
    return _month(following)


async def _create_expense(
    client: AsyncClient, user: AuthedUser, **overrides: Any
) -> dict[str, Any]:
    body: dict[str, Any] = {
        "name": "Spotify",
        "merchant_keyword": "spotify",
        "expected_amount": "16900",
        "day_of_month": min(_today().day, 28),
    }
    body.update(overrides)
    response = await client.post("/v1/recurring-expenses", json=body, headers=user.headers)
    assert response.status_code == 201, response.text
    return response.json()


async def _occurrences(client: AsyncClient, user: AuthedUser) -> list[dict[str, Any]]:
    today = _today()
    response = await client.get(
        "/v1/recurring-occurrences",
        params={"from": _month(today), "to": _next_month(today)},
        headers=user.headers,
    )
    assert response.status_code == 200, response.text
    return response.json()


async def _manual_tx(  # noqa: PLR0913 - builder con un default por campo
    client: AsyncClient,
    user: AuthedUser,
    *,
    merchant: str = "SPOTIFY P3A9C1",
    amount: str = "16900.00",
    direction: str = "debit",
    when: datetime | None = None,
) -> dict[str, Any]:
    occurred = when or datetime.now(UTC) - timedelta(minutes=5)
    response = await client.post(
        "/v1/transactions",
        json={
            "amount": amount,
            "direction": direction,
            "occurred_at": occurred.isoformat(),
            "merchant": merchant,
        },
        headers=user.headers,
    )
    assert response.status_code == 201, response.text
    return response.json()


def _captured_event(user: AuthedUser, tx: dict[str, Any]) -> TransactionCaptured:
    direction = Direction(tx["direction"])
    return TransactionCaptured(
        event_id=uuid4(),
        occurred_at=datetime.now(UTC),
        user_id=user.id,
        transaction_id=UUID(tx["id"]),
        kind=Kind(tx["kind"]),
        fiscal_tag=FiscalTag.NO_DEDUCIBLE,
        amount=Decimal(tx["amount"]),
        direction=direction,
        category_id=UUID(tx["category_id"]),
        transaction_occurred_at=datetime.fromisoformat(tx["occurred_at"]),
        created=True,
        merchant=tx["merchant"],
        account_id=None,
    )


def _current(occurrences: list[dict[str, Any]]) -> dict[str, Any]:
    (current,) = [o for o in occurrences if o["period"] == _month(_today())]
    return current


# --- CRUD y ocurrencias --------------------------------------------------------------


async def test_crear_gasto_fijo_crea_la_ocurrencia_del_mes_y_la_siguiente(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    ana = await user_factory()
    expense = await _create_expense(client, ana)

    assert expense["name"] == "Spotify"
    assert expense["expected_amount"] == "16900.00"
    assert expense["amount_tolerance_pct"] == 10
    assert expense["remind_days_before"] == 1
    assert expense["active"] is True

    listed = (await client.get("/v1/recurring-expenses", headers=ana.headers)).json()
    assert [e["id"] for e in listed] == [expense["id"]]

    occurrences = await _occurrences(client, ana)
    assert sorted(o["period"] for o in occurrences) == [
        _month(_today()),
        _next_month(_today()),
    ]
    assert all(o["status"] == "pending" for o in occurrences)
    assert all(o["recurring_expense"]["name"] == "Spotify" for o in occurrences)


async def test_barrido_retroactivo_tacha_un_pago_ya_capturado(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    """AC-12.3: el pago ya estaba capturado cuando se registra el gasto fijo."""
    ana = await user_factory()
    tx = await _manual_tx(client, ana)

    await _create_expense(client, ana)

    current = _current(await _occurrences(client, ana))
    assert current["status"] == "paid"
    assert current["matched_by"] == "auto"
    assert current["transaction"]["id"] == tx["id"]
    assert current["transaction"]["amount"] == "16900.00"


async def test_barrido_no_tacha_ingresos_ni_montos_fuera_de_tolerancia(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    ana = await user_factory()
    await _manual_tx(client, ana, direction="credit")
    await _manual_tx(client, ana, amount="25000.00")

    await _create_expense(client, ana)

    assert _current(await _occurrences(client, ana))["status"] == "pending"


async def test_patch_valida_y_pausar_borra_las_pendientes_futuras(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    ana = await user_factory()
    expense = await _create_expense(client, ana)

    bad = await client.patch(
        f"/v1/recurring-expenses/{expense['id']}", json={"name": None}, headers=ana.headers
    )
    assert bad.status_code == 400
    assert bad.json()["error"]["field"] == "name"

    paused = await client.patch(
        f"/v1/recurring-expenses/{expense['id']}",
        json={"active": False, "remind_days_before": 2},
        headers=ana.headers,
    )
    assert paused.status_code == 200, paused.text
    assert paused.json()["active"] is False
    assert paused.json()["remind_days_before"] == 2
    assert [o["period"] for o in await _occurrences(client, ana)] == [_month(_today())]

    resumed = await client.patch(
        f"/v1/recurring-expenses/{expense['id']}", json={"active": True}, headers=ana.headers
    )
    assert resumed.status_code == 200
    assert len(await _occurrences(client, ana)) == 2


async def test_borrar_gasto_fijo_borra_sus_ocurrencias(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    ana = await user_factory()
    expense = await _create_expense(client, ana)

    response = await client.delete(f"/v1/recurring-expenses/{expense['id']}", headers=ana.headers)

    assert response.status_code == 204
    assert await _occurrences(client, ana) == []
    assert (await client.get("/v1/recurring-expenses", headers=ana.headers)).json() == []


@pytest.mark.parametrize(
    ("overrides", "field"),
    [
        ({"name": "  "}, "name"),
        ({"merchant_keyword": "x"}, "merchant_keyword"),
        ({"expected_amount": "0"}, "expected_amount"),
        ({"day_of_month": 32}, "day_of_month"),
        ({"amount_tolerance_pct": 60}, "amount_tolerance_pct"),
        ({"remind_days_before": 3}, "remind_days_before"),
    ],
)
async def test_crear_con_campo_invalido_responde_400_con_field(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    overrides: dict[str, Any],
    field: str,
) -> None:
    ana = await user_factory()
    body: dict[str, Any] = {
        "name": "Spotify",
        "merchant_keyword": "spotify",
        "expected_amount": "16900",
        "day_of_month": 22,
        **overrides,
    }

    response = await client.post("/v1/recurring-expenses", json=body, headers=ana.headers)

    assert response.status_code == 400, response.text
    error = response.json()["error"]
    assert error["code"] == "validation_error"
    assert error["field"] == field


async def test_rango_de_meses_invalido_responde_400(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    ana = await user_factory()
    for params in (
        {"from": "2026-01", "to": "2027-01"},
        {"from": "2026-05", "to": "2026-04"},
        {"from": "2026-5", "to": "2026-06"},
    ):
        response = await client.get("/v1/recurring-occurrences", params=params, headers=ana.headers)
        assert response.status_code == 400, params


# --- Consumers ------------------------------------------------------------------------------


async def test_consumer_empareja_el_pago_capturado_una_sola_vez(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    """AC-12.2 y AC-12.7: el evento reprocesado no empareja dos veces."""
    ana = await user_factory()
    await _create_expense(client, ana)
    tx = await _manual_tx(client, ana)
    handler = recurring_public.make_transaction_captured_handler(
        session_factory=session_factory, clock=SystemClock()
    )
    event = _captured_event(ana, tx)

    await handler(event)
    await handler(event)

    current = _current(await _occurrences(client, ana))
    assert current["status"] == "paid"
    assert current["transaction"]["id"] == tx["id"]
    async with session_factory() as session:
        paid = (
            await session.execute(
                text("SELECT count(*) FROM recurring_occurrences WHERE transaction_id = :t"),
                {"t": UUID(tx["id"])},
            )
        ).scalar_one()
    assert paid == 1


async def test_dos_workers_en_carrera_emparejan_una_sola_ocurrencia(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    ana = await user_factory()
    await _create_expense(client, ana)
    tx = await _manual_tx(client, ana)
    handler = recurring_public.make_transaction_captured_handler(
        session_factory=session_factory, clock=SystemClock()
    )

    await asyncio.gather(handler(_captured_event(ana, tx)), handler(_captured_event(ana, tx)))

    occurrences = await _occurrences(client, ana)
    assert [o["status"] for o in occurrences].count("paid") == 1


async def test_deshacer_un_emparejamiento_automatico_no_se_repite(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    """AC-12.4: el rechazo impide que el matcher vuelva a proponer el par."""
    ana = await user_factory()
    await _create_expense(client, ana)
    tx = await _manual_tx(client, ana)
    handler = recurring_public.make_transaction_captured_handler(
        session_factory=session_factory, clock=SystemClock()
    )
    await handler(_captured_event(ana, tx))
    current = _current(await _occurrences(client, ana))

    undone = await client.post(
        f"/v1/recurring-occurrences/{current['id']}/unmark", headers=ana.headers
    )
    assert undone.status_code == 200, undone.text
    assert undone.json()["status"] == "pending"
    await handler(_captured_event(ana, tx))

    assert _current(await _occurrences(client, ana))["status"] == "pending"
    again = await client.post(
        f"/v1/recurring-occurrences/{current['id']}/unmark", headers=ana.headers
    )
    assert again.status_code == 409


async def test_marcar_pagado_a_mano_con_y_sin_movimiento(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    ana = await user_factory()
    await _create_expense(client, ana)
    await _create_expense(client, ana, name="Netflix", merchant_keyword="netflix")
    occurrences = [o for o in await _occurrences(client, ana) if o["period"] == _month(_today())]
    spotify = next(o for o in occurrences if o["recurring_expense"]["name"] == "Spotify")
    netflix = next(o for o in occurrences if o["recurring_expense"]["name"] == "Netflix")
    tx = await _manual_tx(client, ana, merchant="Pago en efectivo")

    manual = await client.post(
        f"/v1/recurring-occurrences/{spotify['id']}/mark-paid",
        json={"transaction_id": tx["id"]},
        headers=ana.headers,
    )
    assert manual.status_code == 200, manual.text
    assert manual.json()["status"] == "paid"
    assert manual.json()["matched_by"] == "manual"
    assert manual.json()["transaction"]["id"] == tx["id"]

    taken = await client.post(
        f"/v1/recurring-occurrences/{netflix['id']}/mark-paid",
        json={"transaction_id": tx["id"]},
        headers=ana.headers,
    )
    assert taken.status_code == 409
    assert taken.json()["error"]["field"] == "transaction_id"

    cash = await client.post(
        f"/v1/recurring-occurrences/{netflix['id']}/mark-paid", json={}, headers=ana.headers
    )
    assert cash.status_code == 200
    assert cash.json()["transaction"] is None

    skipped = await client.post(
        f"/v1/recurring-occurrences/{netflix['id']}/skip", headers=ana.headers
    )
    assert skipped.status_code == 200
    assert skipped.json()["status"] == "skipped"
    assert skipped.json()["matched_by"] is None


async def test_marcar_pagado_con_un_ingreso_responde_400(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    ana = await user_factory()
    await _create_expense(client, ana)
    current = _current(await _occurrences(client, ana))
    income = await _manual_tx(client, ana, direction="credit")

    response = await client.post(
        f"/v1/recurring-occurrences/{current['id']}/mark-paid",
        json={"transaction_id": income["id"]},
        headers=ana.headers,
    )

    assert response.status_code == 400
    assert response.json()["error"]["field"] == "transaction_id"


async def test_borrar_el_movimiento_devuelve_la_ocurrencia_a_pendiente(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    ana = await user_factory()
    tx = await _manual_tx(client, ana)
    await _create_expense(client, ana)
    assert _current(await _occurrences(client, ana))["status"] == "paid"

    deleted = await client.delete(f"/v1/transactions/{tx['id']}", headers=ana.headers)
    assert deleted.status_code == 204
    handler = recurring_public.make_transaction_deleted_handler(session_factory=session_factory)
    await handler(
        TransactionDeleted(
            event_id=uuid4(),
            occurred_at=datetime.now(UTC),
            user_id=ana.id,
            transaction_id=UUID(tx["id"]),
        )
    )

    current = _current(await _occurrences(client, ana))
    assert current["status"] == "pending"
    assert current["transaction"] is None


async def test_cron_de_ocurrencias_es_idempotente(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    ana = await user_factory()
    await _create_expense(client, ana)

    async with session_factory() as session:
        first = await recurring_public.ensure_occurrences(session, SystemClock())
    async with session_factory() as session:
        second = await recurring_public.ensure_occurrences(session, SystemClock())

    assert first.expenses == 1
    assert first.created == 0
    assert second.created == 0
    assert len(await _occurrences(client, ana)) == 2


# --- Authz (spec 009 SS4) ------------------------------------------------------------------------


async def test_recursos_ajenos_responden_404(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    second_user: AuthedUser,
) -> None:
    ana = await user_factory()
    expense = await _create_expense(client, ana)
    current = _current(await _occurrences(client, ana))
    bea = second_user

    calls = [
        client.patch(
            f"/v1/recurring-expenses/{expense['id']}", json={"name": "X"}, headers=bea.headers
        ),
        client.delete(f"/v1/recurring-expenses/{expense['id']}", headers=bea.headers),
        client.post(
            f"/v1/recurring-occurrences/{current['id']}/mark-paid", json={}, headers=bea.headers
        ),
        client.post(f"/v1/recurring-occurrences/{current['id']}/unmark", headers=bea.headers),
        client.post(f"/v1/recurring-occurrences/{current['id']}/skip", headers=bea.headers),
    ]
    for call in calls:
        response = await call
        assert response.status_code == 404, response.text
        assert response.json()["error"]["code"] == "not_found"

    assert (await client.get("/v1/recurring-expenses", headers=bea.headers)).json() == []
    assert await _occurrences(client, bea) == []
    assert _current(await _occurrences(client, ana))["status"] == "pending"


async def test_movimiento_o_categoria_ajena_responden_404(
    client: AsyncClient,
    user_factory: Callable[..., Awaitable[AuthedUser]],
    second_user: AuthedUser,
) -> None:
    ana = await user_factory()
    await _create_expense(client, ana)
    current = _current(await _occurrences(client, ana))
    bea_tx = await _manual_tx(client, second_user)
    bea_category = await client.post(
        "/v1/categories",
        json={"name": "Suscripciones", "fiscal_tag": "no_deducible"},
        headers=second_user.headers,
    )

    foreign_tx = await client.post(
        f"/v1/recurring-occurrences/{current['id']}/mark-paid",
        json={"transaction_id": bea_tx["id"]},
        headers=ana.headers,
    )
    foreign_category = await client.post(
        "/v1/recurring-expenses",
        json={
            "name": "Netflix",
            "merchant_keyword": "netflix",
            "expected_amount": "38900",
            "day_of_month": 5,
            "category_id": bea_category.json()["id"],
        },
        headers=ana.headers,
    )

    assert foreign_tx.status_code == 404
    assert foreign_category.status_code == 404
    assert foreign_category.json()["error"]["field"] == "category_id"
