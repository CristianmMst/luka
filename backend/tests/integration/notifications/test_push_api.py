"""Integracion de notifications: tokens, cron de avisos y consumer (spec 011 SS5-SS6)."""

from __future__ import annotations

from collections.abc import Awaitable, Callable
from datetime import UTC, date, datetime, timedelta
from typing import Any
from uuid import UUID
from zoneinfo import ZoneInfo

import pytest
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser

from luka.modules.notifications import public as notifications_public
from luka.modules.notifications.domain.entities import DeviceToken, PushMessage, SendOutcome
from luka.modules.recurring import public as recurring_public
from luka.modules.recurring.events import PaymentDueSoon
from luka.shared.clock import SystemClock

pytestmark = pytest.mark.integration

_BOGOTA = ZoneInfo("America/Bogota")


def _tomorrow() -> date:
    return datetime.now(_BOGOTA).date() + timedelta(days=1)


class _RecordingBus:
    """Bus que solo guarda lo publicado (los consumers se llaman a mano)."""

    def __init__(self) -> None:
        self.published: list[object] = []

    async def publish(self, event: object) -> None:
        self.published.append(event)


class _RecordingSender:
    def __init__(self, outcome: SendOutcome = SendOutcome.SENT) -> None:
        self.outcome = outcome
        self.sent: list[tuple[str, PushMessage]] = []

    async def send(self, token: DeviceToken, message: PushMessage) -> SendOutcome:
        self.sent.append((token.token, message))
        return self.outcome


async def _register(client: AsyncClient, user: AuthedUser, token: str, platform: str = "android"):
    return await client.put(
        "/v1/devices/push-token",
        json={"token": token, "platform": platform},
        headers=user.headers,
    )


async def _tokens(session_factory: async_sessionmaker[AsyncSession]) -> list[tuple[Any, ...]]:
    async with session_factory() as session:
        rows = await session.execute(
            text("SELECT token, user_id, platform FROM device_tokens ORDER BY token")
        )
        return [tuple(r) for r in rows]


async def test_registrar_reasigna_el_token_y_borrar_es_idempotente(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
    second_user: AuthedUser,
) -> None:
    ana = await user_factory()

    assert (await _register(client, ana, "tok-1")).status_code == 204
    assert (await _register(client, ana, "tok-1", "ios")).status_code == 204
    assert await _tokens(session_factory) == [("tok-1", ana.id, "ios")]

    assert (await _register(client, second_user, "tok-1")).status_code == 204
    assert await _tokens(session_factory) == [("tok-1", second_user.id, "android")]

    # Ana ya no es duena: su DELETE no borra el token de Bea.
    gone = await client.request(
        "DELETE", "/v1/devices/push-token", json={"token": "tok-1"}, headers=ana.headers
    )
    assert gone.status_code == 204
    assert len(await _tokens(session_factory)) == 1
    mine = await client.request(
        "DELETE", "/v1/devices/push-token", json={"token": "tok-1"}, headers=second_user.headers
    )
    assert mine.status_code == 204
    assert await _tokens(session_factory) == []


async def test_registrar_valida_plataforma_y_token(
    client: AsyncClient, user_factory: Callable[..., Awaitable[AuthedUser]]
) -> None:
    ana = await user_factory()

    bad_platform = await _register(client, ana, "tok-1", "web")
    empty = await _register(client, ana, "")

    assert bad_platform.status_code == 400
    assert bad_platform.json()["error"]["field"] == "platform"
    assert empty.status_code == 400
    assert empty.json()["error"]["field"] == "token"
    assert (await client.put("/v1/devices/push-token", json={})).status_code == 401


async def test_cron_publica_y_el_consumer_avisa_una_sola_vez(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    """AC-12.5 y AC-12.7: el aviso llega el dia antes y no se repite."""
    ana = await user_factory()
    await _register(client, ana, "tok-ana")
    due = _tomorrow()
    created = await client.post(
        "/v1/recurring-expenses",
        json={
            "name": "Spotify",
            "merchant_keyword": "spotify",
            "expected_amount": "16900",
            "day_of_month": due.day,
        },
        headers=ana.headers,
    )
    assert created.status_code == 201, created.text
    bus = _RecordingBus()

    async with session_factory() as session:
        published = await recurring_public.publish_due_reminders(session, bus, SystemClock())
    assert published == 1
    (event,) = [e for e in bus.published if isinstance(e, PaymentDueSoon)]
    assert event.due_date == due.isoformat()

    sender = _RecordingSender()
    handler = notifications_public.make_payment_due_soon_handler(
        session_factory=session_factory, sender=sender, clock=SystemClock()
    )
    await handler(event)
    await handler(event)

    assert len(sender.sent) == 1
    token, message = sender.sent[0]
    assert token == "tok-ana"
    assert message.title == "Se acerca tu pago de Spotify"
    assert message.body.startswith("Mañana, ")
    assert "$16.900" in message.body
    async with session_factory() as session:
        again = await recurring_public.publish_due_reminders(session, bus, SystemClock())
    assert again == 0


async def test_consumer_no_avisa_un_pago_ya_detectado(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    ana = await user_factory()
    await _register(client, ana, "tok-ana")
    due = _tomorrow()
    await client.post(
        "/v1/recurring-expenses",
        json={
            "name": "Spotify",
            "merchant_keyword": "spotify",
            "expected_amount": "16900",
            "day_of_month": due.day,
        },
        headers=ana.headers,
    )
    bus = _RecordingBus()
    async with session_factory() as session:
        await recurring_public.publish_due_reminders(session, bus, SystemClock())
    (event,) = [e for e in bus.published if isinstance(e, PaymentDueSoon)]
    await client.post(
        f"/v1/recurring-occurrences/{event.occurrence_id}/mark-paid", json={}, headers=ana.headers
    )
    sender = _RecordingSender()

    handler = notifications_public.make_payment_due_soon_handler(
        session_factory=session_factory, sender=sender, clock=SystemClock()
    )
    await handler(event)

    assert sender.sent == []


async def test_token_invalido_se_borra_y_no_marca(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    ana = await user_factory()
    await _register(client, ana, "tok-muerto")
    due = _tomorrow()
    await client.post(
        "/v1/recurring-expenses",
        json={
            "name": "Spotify",
            "merchant_keyword": "spotify",
            "expected_amount": "16900",
            "day_of_month": due.day,
        },
        headers=ana.headers,
    )
    bus = _RecordingBus()
    async with session_factory() as session:
        await recurring_public.publish_due_reminders(session, bus, SystemClock())
    (event,) = [e for e in bus.published if isinstance(e, PaymentDueSoon)]

    handler = notifications_public.make_payment_due_soon_handler(
        session_factory=session_factory,
        sender=_RecordingSender(SendOutcome.UNREGISTERED),
        clock=SystemClock(),
    )
    await handler(event)

    assert await _tokens(session_factory) == []
    async with session_factory() as session:
        reminded = (
            await session.execute(
                text("SELECT reminded_at FROM recurring_occurrences WHERE id = :id"),
                {"id": UUID(str(event.occurrence_id))},
            )
        ).scalar_one()
    assert reminded is None


async def test_purga_borra_tokens_viejos(
    client: AsyncClient,
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    ana = await user_factory()
    await _register(client, ana, "tok-viejo")
    await _register(client, ana, "tok-nuevo")
    async with session_factory() as session:
        await session.execute(
            text("UPDATE device_tokens SET last_seen_at = :t WHERE token = 'tok-viejo'"),
            {"t": datetime.now(UTC) - timedelta(days=271)},
        )
        await session.commit()

    async with session_factory() as session:
        removed = await notifications_public.purge_stale_tokens(session, SystemClock())

    assert removed == 1
    assert [t[0] for t in await _tokens(session_factory)] == ["tok-nuevo"]
