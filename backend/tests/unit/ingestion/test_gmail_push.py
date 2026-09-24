"""Tests del envelope de Pub/Sub de Gmail y del remitente del mensaje (F3.4, spec 005 §4)."""

import base64
import json
from datetime import UTC, datetime

import pytest

from finanzia.modules.ingestion.domain.errors import InvalidPushEnvelope
from finanzia.modules.ingestion.domain.gmail_message import GmailMessage, MimePart
from finanzia.modules.ingestion.domain.gmail_push import GmailPushNotification, decode_push_envelope

pytestmark = pytest.mark.unit


def _envelope(data: object, *, encode: bool = True) -> bytes:
    raw = json.dumps(data).encode() if not isinstance(data, bytes) else data
    encoded = base64.b64encode(raw).decode() if encode else data
    return json.dumps(
        {
            "message": {"data": encoded, "messageId": "1", "publishTime": "2026-05-01T12:00:00Z"},
            "subscription": "projects/p/subscriptions/gmail-push",
        }
    ).encode()


def test_decodifica_email_e_history_id() -> None:
    raw = _envelope({"emailAddress": "ana@gmail.com", "historyId": 9876543210})

    assert decode_push_envelope(raw) == GmailPushNotification("ana@gmail.com", 9876543210)


def test_acepta_history_id_como_string_y_base64_url_sin_padding() -> None:
    data = json.dumps({"emailAddress": "ana@gmail.com", "historyId": "42"}).encode()
    encoded = base64.urlsafe_b64encode(data).decode().rstrip("=")
    raw = json.dumps({"message": {"data": encoded}}).encode()

    assert decode_push_envelope(raw) == GmailPushNotification("ana@gmail.com", 42)


@pytest.mark.parametrize(
    "raw",
    [
        b"",
        b"no es json",
        b"[]",
        json.dumps({"subscription": "s"}).encode(),
        json.dumps({"message": "texto"}).encode(),
        json.dumps({"message": {}}).encode(),
        json.dumps({"message": {"data": 5}}).encode(),
        json.dumps({"message": {"data": "@@no-base64@@"}}).encode(),
        _envelope(b"\xff\xfe no utf8"),
        _envelope(b"no es json"),
        _envelope(["lista"]),
        _envelope({"historyId": 1}),
        _envelope({"emailAddress": "", "historyId": 1}),
        _envelope({"emailAddress": "ana@gmail.com"}),
        _envelope({"emailAddress": "ana@gmail.com", "historyId": "abc"}),
        _envelope({"emailAddress": "ana@gmail.com", "historyId": 0}),
        _envelope({"emailAddress": "ana@gmail.com", "historyId": True}),
        _envelope({"emailAddress": "ana@gmail.com", "historyId": 1.5}),
    ],
)
def test_envelope_malformado_lanza_invalid_push_envelope(raw: bytes) -> None:
    with pytest.raises(InvalidPushEnvelope):
        decode_push_envelope(raw)


@pytest.mark.parametrize(
    ("header", "address"),
    [
        (
            "Bancolombia <AlertasYNotificaciones@an.notificacionesbancolombia.com>",
            "alertasynotificaciones@an.notificacionesbancolombia.com",
        ),
        ("alertas@bancolombia.com.co", "alertas@bancolombia.com.co"),
        ('"Nequi, alertas" <avisos@nequi.com.co>', "avisos@nequi.com.co"),
        # Sin una direccion inequivoca queda vacio: el filtro de remitentes lo descarta.
        ("", ""),
        ("sin direccion", ""),
        ("Evil <x@evil.com> <alertas@bancolombia.com.co>", ""),
    ],
)
def test_sender_address_es_la_direccion_del_from_en_minusculas(header: str, address: str) -> None:
    message = GmailMessage(
        id="m1",
        sender=header,
        internal_date=datetime(2026, 5, 1, tzinfo=UTC),
        payload=MimePart(mime_type="text/plain"),
    )

    assert message.sender_address == address
