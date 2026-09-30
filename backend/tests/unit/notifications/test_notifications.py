"""Unit de notifications: texto del aviso, adapter FCM y envio (spec 011 SS5-SS6)."""

from __future__ import annotations

import json
from collections.abc import Callable
from datetime import UTC, date, datetime
from decimal import Decimal
from uuid import UUID, uuid4

import httpx
import pytest

from luka.modules.notifications.application.use_cases.push_tokens import (
    PurgeStaleTokens,
    RegisterPushToken,
    UnregisterPushToken,
)
from luka.modules.notifications.application.use_cases.send_due_reminder import (
    DueReminderCommand,
    SendDueReminder,
)
from luka.modules.notifications.domain.entities import (
    DeviceToken,
    Platform,
    PushMessage,
    SendOutcome,
)
from luka.modules.notifications.domain.errors import InvalidPushToken, PushUnavailable
from luka.modules.notifications.domain.messages import due_reminder_message, format_cop
from luka.modules.notifications.infrastructure.fcm_sender import FcmPushSender, build_fcm_payload
from luka.modules.notifications.public import decode_service_account

pytestmark = pytest.mark.unit

_NOW = datetime(2026, 10, 21, 14, 0, tzinfo=UTC)
_USER = uuid4()
_OCC = uuid4()


# --- Texto del aviso (spec 011 SS5) -------------------------------------------------------


@pytest.mark.parametrize(
    ("amount", "text"),
    [
        ("16900.00", "$16.900"),
        ("1234567.00", "$1.234.567"),
        ("16900.50", "$16.900,50"),
        ("900", "$900"),
    ],
)
def test_format_cop_como_la_app(amount: str, text: str) -> None:
    assert format_cop(Decimal(amount)) == text


def test_aviso_de_un_dia_dice_manana() -> None:
    message = due_reminder_message(
        occurrence_id=_OCC,
        name="Spotify",
        amount=Decimal("16900.00"),
        due_date=date(2026, 10, 22),
        today=date(2026, 10, 21),
    )

    assert message.title == "Se acerca tu pago de Spotify"
    assert message.body == "Mañana, 22 de octubre, se te descontarán $16.900 de tu cuenta."
    assert message.data == {"type": "recurring_due", "occurrence_id": str(_OCC)}


def test_aviso_de_siete_y_dos_dias_y_atrasado() -> None:
    week = due_reminder_message(
        occurrence_id=_OCC,
        name="Arriendo",
        amount=Decimal("1500000"),
        due_date=date(2026, 11, 5),
        today=date(2026, 10, 29),
    )
    two_days = due_reminder_message(
        occurrence_id=_OCC,
        name="Arriendo",
        amount=Decimal("1500000"),
        due_date=date(2026, 11, 5),
        today=date(2026, 11, 3),
    )
    late = due_reminder_message(
        occurrence_id=_OCC,
        name="Arriendo",
        amount=Decimal("1500000"),
        due_date=date(2026, 11, 5),
        today=date(2026, 11, 5),
    )

    assert week.body == "El 5 de noviembre se te descontarán $1.500.000 de tu cuenta."
    assert two_days.body == (
        "Pasado mañana, 5 de noviembre, se te descontarán $1.500.000 de tu cuenta."
    )
    assert late.body == "Hoy se te descontarán $1.500.000 de tu cuenta."


# --- Payload y adapter FCM ------------------------------------------------------------------


def _token(platform: Platform = Platform.ANDROID, value: str = "tok-1") -> DeviceToken:
    return DeviceToken(
        id=uuid4(),
        user_id=_USER,
        token=value,
        platform=platform,
        created_at=_NOW,
        last_seen_at=_NOW,
    )


_MESSAGE = PushMessage(title="T", body="B", data={"type": "recurring_due", "occurrence_id": "x"})


def test_payload_android_usa_el_canal_y_oculta_en_bloqueo() -> None:
    payload = build_fcm_payload(_token(), _MESSAGE)["message"]

    assert payload["token"] == "tok-1"
    assert payload["notification"] == {"title": "T", "body": "B"}
    assert payload["android"]["notification"] == {
        "channel_id": "recordatorios_pagos",
        "visibility": "PRIVATE",
    }
    assert "apns" not in payload


def test_payload_ios_usa_apns() -> None:
    payload = build_fcm_payload(_token(Platform.IOS), _MESSAGE)["message"]

    assert "android" not in payload
    assert payload["apns"] == {"payload": {"aps": {"sound": "default"}}}


class _StaticToken:
    async def token(self) -> str:
        return "ya29.test"


def _sender(handler: Callable[[httpx.Request], httpx.Response]) -> FcmPushSender:
    client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    return FcmPushSender(client, _StaticToken(), project_id="luka-510204")


async def test_fcm_envia_con_bearer_al_proyecto_y_sin_datos_del_usuario() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, json={"name": "projects/luka-510204/messages/1"})

    outcome = await _sender(handler).send(_token(), _MESSAGE)

    assert outcome is SendOutcome.SENT
    (request,) = seen
    assert str(request.url) == ("https://fcm.googleapis.com/v1/projects/luka-510204/messages:send")
    assert request.headers["Authorization"] == "Bearer ya29.test"
    body = request.content.decode()
    assert str(_USER) not in body
    assert json.loads(body)["message"]["data"]["type"] == "recurring_due"


@pytest.mark.parametrize(
    ("status", "error"),
    [
        (404, {"status": "NOT_FOUND"}),
        (
            400,
            {
                "status": "INVALID_ARGUMENT",
                "details": [{"errorCode": "INVALID_ARGUMENT"}],
            },
        ),
        (403, {"status": "PERMISSION_DENIED", "details": [{"errorCode": "SENDER_ID_MISMATCH"}]}),
    ],
)
async def test_fcm_token_muerto_devuelve_unregistered(
    status: int, error: dict[str, object]
) -> None:
    sender = _sender(lambda _: httpx.Response(status, json={"error": error}))

    assert await sender.send(_token(), _MESSAGE) is SendOutcome.UNREGISTERED


@pytest.mark.parametrize("status", [429, 500, 503, 401])
async def test_fcm_temporal_lanza_push_unavailable(status: int) -> None:
    sender = _sender(lambda _: httpx.Response(status, json={"error": {"status": "UNAVAILABLE"}}))

    with pytest.raises(PushUnavailable):
        await sender.send(_token(), _MESSAGE)


async def test_fcm_sin_red_lanza_push_unavailable() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("sin red", request=request)

    with pytest.raises(PushUnavailable):
        await _sender(handler).send(_token(), _MESSAGE)


def test_decode_service_account_exige_los_campos() -> None:
    import base64  # noqa: PLC0415

    good = base64.b64encode(
        json.dumps({"project_id": "p", "client_email": "c", "private_key": "k"}).encode()
    ).decode()
    assert decode_service_account(good)["project_id"] == "p"
    with pytest.raises(ValueError, match="base64"):
        decode_service_account("no es base64 !!")
    with pytest.raises(ValueError, match="project_id"):
        decode_service_account(base64.b64encode(b'{"project_id": "p"}').decode())


# --- Casos de uso ------------------------------------------------------------------------------


class _Clock:
    def now(self) -> datetime:
        return _NOW


class _Ids:
    def new_id(self) -> UUID:
        return uuid4()


class _Uow:
    def __init__(self) -> None:
        self.commits = 0

    async def commit(self) -> None:
        self.commits += 1


class _Tokens:
    def __init__(self, tokens: list[DeviceToken] | None = None) -> None:
        self.tokens = list(tokens or [])
        self.upserts: list[tuple[UUID, str, Platform]] = []
        self.deleted: list[str] = []
        self.purged_before: datetime | None = None

    async def upsert(
        self, *, id: UUID, user_id: UUID, token: str, platform: Platform, now: datetime
    ) -> None:
        del id, now
        self.upserts.append((user_id, token, platform))

    async def delete_for_user(self, user_id: UUID, token: str) -> None:
        del user_id
        self.deleted.append(token)

    async def delete_token(self, token: str) -> None:
        self.deleted.append(token)

    async def list_for_user(self, user_id: UUID) -> list[DeviceToken]:
        return [t for t in self.tokens if t.user_id == user_id]

    async def purge_seen_before(self, cutoff: datetime) -> int:
        self.purged_before = cutoff
        return 3


class _Sender:
    def __init__(self, outcomes: dict[str, SendOutcome | Exception]) -> None:
        self.outcomes = outcomes
        self.sent_to: list[str] = []

    async def send(self, token: DeviceToken, message: PushMessage) -> SendOutcome:
        del message
        outcome = self.outcomes[token.token]
        if isinstance(outcome, Exception):
            raise outcome
        self.sent_to.append(token.token)
        return outcome


class _Reminders:
    def __init__(self, *, due: bool = True) -> None:
        self.due = due
        self.marked: list[UUID] = []

    async def still_due(self, occurrence_id: UUID, slot: int) -> bool:
        del occurrence_id, slot
        return self.due

    async def mark_reminded(self, occurrence_id: UUID, slot: int) -> bool:
        del slot
        self.marked.append(occurrence_id)
        return True


def _cmd() -> DueReminderCommand:
    return DueReminderCommand(
        user_id=_USER,
        occurrence_id=_OCC,
        name="Spotify",
        expected_amount=Decimal("16900.00"),
        due_date=date(2026, 10, 22),
        today=date(2026, 10, 21),
    )


def _use_case(tokens: _Tokens, sender: _Sender, reminders: _Reminders) -> SendDueReminder:
    return SendDueReminder(
        tokens=tokens, sender=sender, reminders=reminders, clock=_Clock(), uow=_Uow()
    )


async def test_envia_a_todos_los_tokens_borra_los_muertos_y_marca() -> None:
    tokens = _Tokens([_token(value="a"), _token(value="b"), _token(Platform.IOS, "c")])
    sender = _Sender({"a": SendOutcome.SENT, "b": SendOutcome.UNREGISTERED, "c": SendOutcome.SENT})
    reminders = _Reminders()

    result = await _use_case(tokens, sender, reminders).execute(_cmd())

    assert (result.sent, result.removed, result.skipped) == (2, 1, False)
    assert tokens.deleted == ["b"]
    assert reminders.marked == [_OCC]


async def test_no_envia_si_ya_no_toca() -> None:
    tokens = _Tokens([_token(value="a")])
    sender = _Sender({"a": SendOutcome.SENT})
    reminders = _Reminders(due=False)

    result = await _use_case(tokens, sender, reminders).execute(_cmd())

    assert result.skipped is True
    assert sender.sent_to == []
    assert reminders.marked == []


async def test_sin_tokens_no_marca_ni_falla() -> None:
    reminders = _Reminders()

    result = await _use_case(_Tokens(), _Sender({}), reminders).execute(_cmd())

    assert result.sent == 0
    assert reminders.marked == []


async def test_fcm_caido_para_todos_relanza_para_reintentar() -> None:
    tokens = _Tokens([_token(value="a")])
    reminders = _Reminders()

    with pytest.raises(PushUnavailable):
        await _use_case(tokens, _Sender({"a": PushUnavailable()}), reminders).execute(_cmd())
    assert reminders.marked == []


async def test_fcm_caido_para_uno_marca_y_no_reintenta() -> None:
    tokens = _Tokens([_token(value="a"), _token(value="b")])
    sender = _Sender({"a": PushUnavailable(), "b": SendOutcome.SENT})
    reminders = _Reminders()

    result = await _use_case(tokens, sender, reminders).execute(_cmd())

    assert result.sent == 1
    assert reminders.marked == [_OCC]


async def test_registrar_limpia_el_token_y_rechaza_vacio() -> None:
    tokens = _Tokens()
    use_case = RegisterPushToken(tokens=tokens, clock=_Clock(), ids=_Ids(), uow=_Uow())

    await use_case.execute(_USER, "  tok-9  ", Platform.IOS)

    assert tokens.upserts == [(_USER, "tok-9", Platform.IOS)]
    with pytest.raises(InvalidPushToken):
        await use_case.execute(_USER, "   ", Platform.IOS)
    with pytest.raises(InvalidPushToken):
        await use_case.execute(_USER, "x" * 4097, Platform.IOS)


async def test_borrar_y_purgar() -> None:
    tokens = _Tokens()
    await UnregisterPushToken(tokens=tokens, uow=_Uow()).execute(_USER, "tok-1")
    removed = await PurgeStaleTokens(tokens=tokens, clock=_Clock(), uow=_Uow()).execute()

    assert tokens.deleted == ["tok-1"]
    assert removed == 3
    assert tokens.purged_before == datetime(2026, 1, 24, 14, 0, tzinfo=UTC)
