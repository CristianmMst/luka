"""Tests del adaptador httpx de Google OAuth + Gmail API (MockTransport, sin red)."""

from __future__ import annotations

import base64
import json
from collections.abc import AsyncGenerator, Callable
from datetime import UTC, datetime
from typing import Any
from urllib.parse import parse_qs

import httpx
import pytest
import structlog
from support.email_fixtures import bancolombia_fixtures

from finanzia.modules.ingestion.application.ports import GmailClientPort
from finanzia.modules.ingestion.domain.errors import (
    GmailAuthRevoked,
    GmailHistoryExpired,
    GmailRefreshTokenMissing,
    GmailRequestRejected,
    GmailTransientError,
)
from finanzia.modules.ingestion.infrastructure.gmail_client import GoogleGmailClient

_API = "https://gmail.googleapis.com/gmail/v1/users/me"
_TOKEN_URL = "https://oauth2.googleapis.com/token"
_REVOKE_URL = "https://oauth2.googleapis.com/revoke"
_SECRET_REFRESH = "1//refresh-secreto"
_SECRET_ACCESS = "ya29.access-secreto"
_SECRET_CODE = "4/0server-auth-code"
_ACCOUNT_EMAIL = "cristianmmst@gmail.com"
_BANCOLOMBIA = "alertasynotificaciones@an.notificacionesbancolombia.com"

Handler = Callable[[httpx.Request], httpx.Response]
ClientFactory = Callable[[Handler], GoogleGmailClient]


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("ascii").rstrip("=")


def _form(request: httpx.Request) -> dict[str, str]:
    return {k: v[0] for k, v in parse_qs(request.content.decode(), keep_blank_values=True).items()}


@pytest.fixture
async def make_client() -> AsyncGenerator[ClientFactory, None]:
    clients: list[httpx.AsyncClient] = []

    def factory(handler: Handler) -> GoogleGmailClient:
        http = httpx.AsyncClient(transport=httpx.MockTransport(handler))
        clients.append(http)
        return GoogleGmailClient(http, client_id="cid.apps", client_secret="csecret")

    yield factory

    for http in clients:
        await http.aclose()


@pytest.mark.unit
class TestOAuth:
    async def test_exchange_code_canjea_y_lee_el_email_del_perfil(
        self, make_client: ClientFactory
    ) -> None:
        seen: list[httpx.Request] = []

        def handler(request: httpx.Request) -> httpx.Response:
            seen.append(request)
            if str(request.url) == _TOKEN_URL:
                return httpx.Response(
                    200,
                    json={
                        "access_token": _SECRET_ACCESS,
                        "refresh_token": _SECRET_REFRESH,
                        "expires_in": 3599,
                        "token_type": "Bearer",
                    },
                )
            assert str(request.url) == f"{_API}/profile"
            assert request.headers["authorization"] == f"Bearer {_SECRET_ACCESS}"
            return httpx.Response(200, json={"emailAddress": _ACCOUNT_EMAIL, "historyId": "99"})

        client = make_client(handler)

        refresh, email = await client.exchange_code(_SECRET_CODE)

        assert (refresh, email) == (_SECRET_REFRESH, _ACCOUNT_EMAIL)
        token_req = seen[0]
        assert token_req.method == "POST"
        assert _form(token_req) == {
            "grant_type": "authorization_code",
            "code": _SECRET_CODE,
            "client_id": "cid.apps",
            "client_secret": "csecret",
            "redirect_uri": "",
        }

    async def test_exchange_code_con_redirect_uri_propio(self) -> None:
        captured: dict[str, str] = {}

        def handler(request: httpx.Request) -> httpx.Response:
            if str(request.url) == _TOKEN_URL:
                captured.update(_form(request))
                return httpx.Response(200, json={"access_token": "a", "refresh_token": "r"})
            return httpx.Response(200, json={"emailAddress": _ACCOUNT_EMAIL})

        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
            client = GoogleGmailClient(
                http, client_id="c", client_secret="s", redirect_uri="https://x.co/cb"
            )
            await client.exchange_code("code")

        assert captured["redirect_uri"] == "https://x.co/cb"

    async def test_exchange_code_invalid_grant_lanza_auth_revoked(
        self, make_client: ClientFactory
    ) -> None:
        client = make_client(
            lambda _: httpx.Response(400, json={"error": "invalid_grant", "error_description": "x"})
        )
        with pytest.raises(GmailAuthRevoked):
            await client.exchange_code(_SECRET_CODE)

    async def test_exchange_code_sin_refresh_token_lanza_refresh_token_missing(
        self, make_client: ClientFactory
    ) -> None:
        client = make_client(lambda _: httpx.Response(200, json={"access_token": "a"}))
        with pytest.raises(GmailRefreshTokenMissing, match="refresh_token"):
            await client.exchange_code(_SECRET_CODE)

    async def test_access_token_refresca(self, make_client: ClientFactory) -> None:
        captured: dict[str, str] = {}

        def handler(request: httpx.Request) -> httpx.Response:
            assert str(request.url) == _TOKEN_URL
            captured.update(_form(request))
            return httpx.Response(200, json={"access_token": _SECRET_ACCESS, "expires_in": 3599})

        client = make_client(handler)

        assert await client.access_token(_SECRET_REFRESH) == _SECRET_ACCESS
        assert captured == {
            "grant_type": "refresh_token",
            "refresh_token": _SECRET_REFRESH,
            "client_id": "cid.apps",
            "client_secret": "csecret",
        }

    async def test_access_token_invalid_grant_lanza_auth_revoked(
        self, make_client: ClientFactory
    ) -> None:
        client = make_client(lambda _: httpx.Response(400, json={"error": "invalid_grant"}))
        with pytest.raises(GmailAuthRevoked):
            await client.access_token(_SECRET_REFRESH)

    async def test_access_token_otro_error_4xx_es_rechazo(self, make_client: ClientFactory) -> None:
        client = make_client(lambda _: httpx.Response(401, json={"error": "invalid_client"}))
        with pytest.raises(GmailRequestRejected):
            await client.access_token(_SECRET_REFRESH)

    async def test_access_token_respuesta_sin_access_token_es_rechazo(
        self, make_client: ClientFactory
    ) -> None:
        client = make_client(lambda _: httpx.Response(200, json={"expires_in": 1}))
        with pytest.raises(GmailRequestRejected):
            await client.access_token(_SECRET_REFRESH)

    async def test_revoke_manda_el_token_en_el_cuerpo_no_en_la_url(
        self, make_client: ClientFactory
    ) -> None:
        seen: list[httpx.Request] = []

        def handler(request: httpx.Request) -> httpx.Response:
            seen.append(request)
            return httpx.Response(200)

        client = make_client(handler)

        await client.revoke(_SECRET_REFRESH)

        assert seen[0].method == "POST"
        assert str(seen[0].url) == _REVOKE_URL
        assert _form(seen[0]) == {"token": _SECRET_REFRESH}

    async def test_revoke_token_ya_invalido_es_idempotente(
        self, make_client: ClientFactory
    ) -> None:
        client = make_client(lambda _: httpx.Response(400, json={"error": "invalid_token"}))
        await client.revoke(_SECRET_REFRESH)


@pytest.mark.unit
class TestWatch:
    async def test_watch_crea_el_watch_sobre_inbox(self, make_client: ClientFactory) -> None:
        captured: dict[str, Any] = {}

        def handler(request: httpx.Request) -> httpx.Response:
            captured["url"] = str(request.url)
            captured["method"] = request.method
            captured["auth"] = request.headers["authorization"]
            captured["json"] = json.loads(request.content)
            return httpx.Response(200, json={"historyId": "12345", "expiration": "1790000000000"})

        client = make_client(handler)

        history_id, expires_at = await client.watch(_SECRET_ACCESS, "projects/p/topics/t")

        assert captured["url"] == f"{_API}/watch"
        assert captured["method"] == "POST"
        assert captured["auth"] == f"Bearer {_SECRET_ACCESS}"
        assert captured["json"] == {
            "topicName": "projects/p/topics/t",
            "labelIds": ["INBOX"],
            "labelFilterBehavior": "INCLUDE",
        }
        assert history_id == 12345
        assert expires_at == datetime.fromtimestamp(1_790_000_000, tz=UTC)

    async def test_watch_respuesta_ilegible_es_rechazo(self, make_client: ClientFactory) -> None:
        client = make_client(lambda _: httpx.Response(200, json={"historyId": "no-numero"}))
        with pytest.raises(GmailRequestRejected):
            await client.watch(_SECRET_ACCESS, "t")

    async def test_stop(self, make_client: ClientFactory) -> None:
        seen: list[httpx.Request] = []

        def handler(request: httpx.Request) -> httpx.Response:
            seen.append(request)
            return httpx.Response(204)

        client = make_client(handler)

        await client.stop(_SECRET_ACCESS)

        assert seen[0].method == "POST"
        assert str(seen[0].url) == f"{_API}/stop"


@pytest.mark.unit
class TestHistory:
    async def test_history_pagina_y_deduplica(self, make_client: ClientFactory) -> None:
        seen: list[httpx.URL] = []

        def handler(request: httpx.Request) -> httpx.Response:
            seen.append(request.url)
            if "pageToken" not in request.url.params:
                return httpx.Response(
                    200,
                    json={
                        "history": [
                            {"id": "101", "messagesAdded": [{"message": {"id": "m1"}}]},
                            {
                                "id": "102",
                                "messagesAdded": [
                                    {"message": {"id": "m2"}},
                                    {"message": {"id": "m1"}},
                                ],
                            },
                            {"id": "103"},
                        ],
                        "nextPageToken": "p2",
                        "historyId": "150",
                    },
                )
            return httpx.Response(
                200,
                json={
                    "history": [{"id": "104", "messagesAdded": [{"message": {"id": "m3"}}]}],
                    "historyId": "160",
                },
            )

        client = make_client(handler)

        ids, new_history_id = await client.history_new_message_ids(_SECRET_ACCESS, 100)

        assert ids == ["m1", "m2", "m3"]
        assert new_history_id == 160
        assert seen[0].path == "/gmail/v1/users/me/history"
        assert dict(seen[0].params) == {
            "startHistoryId": "100",
            "historyTypes": "messageAdded",
        }
        assert seen[1].params["pageToken"] == "p2"

    async def test_history_sin_cambios(self, make_client: ClientFactory) -> None:
        client = make_client(lambda _: httpx.Response(200, json={"historyId": "100"}))
        assert await client.history_new_message_ids(_SECRET_ACCESS, 100) == ([], 100)

    async def test_history_404_lanza_history_expired(self, make_client: ClientFactory) -> None:
        client = make_client(lambda _: httpx.Response(404, json={"error": {"code": 404}}))
        with pytest.raises(GmailHistoryExpired):
            await client.history_new_message_ids(_SECRET_ACCESS, 1)

    async def test_recent_message_ids_pagina(self, make_client: ClientFactory) -> None:
        seen: list[httpx.URL] = []

        def handler(request: httpx.Request) -> httpx.Response:
            seen.append(request.url)
            if "pageToken" not in request.url.params:
                return httpx.Response(
                    200,
                    json={
                        "messages": [{"id": "a", "threadId": "t"}, {"id": "b", "threadId": "t"}],
                        "nextPageToken": "n",
                    },
                )
            return httpx.Response(200, json={"messages": [{"id": "c", "threadId": "t"}]})

        client = make_client(handler)

        assert await client.recent_message_ids(_SECRET_ACCESS, days=3) == ["a", "b", "c"]
        assert seen[0].path == "/gmail/v1/users/me/messages"
        assert dict(seen[0].params) == {"q": "newer_than:3d", "maxResults": "100"}
        assert seen[1].params["pageToken"] == "n"

    async def test_recent_message_ids_buzon_vacio(self, make_client: ClientFactory) -> None:
        client = make_client(lambda _: httpx.Response(200, json={"resultSizeEstimate": 0}))
        assert await client.recent_message_ids(_SECRET_ACCESS) == []


def _full_message(fixture_body: str) -> dict[str, Any]:
    html_body = "<table>" + "".join(
        f"<tr><td>{line}</td></tr>" for line in fixture_body.splitlines() if line.strip()
    )
    return {
        "id": "18f0c0ffee",
        "threadId": "18f0c0ffee",
        "internalDate": "1714597231000",
        "payload": {
            "mimeType": "multipart/mixed",
            "headers": [
                {"name": "Subject", "value": "Alertas y Notificaciones"},
                {"name": "from", "value": f"Bancolombia <{_BANCOLOMBIA}>"},
            ],
            "body": {"size": 0},
            "parts": [
                {
                    "mimeType": "multipart/alternative",
                    "headers": [],
                    "body": {"size": 0},
                    "parts": [
                        {
                            "mimeType": "text/html",
                            "headers": [
                                {"name": "Content-Type", "value": 'text/html; charset="UTF-8"'}
                            ],
                            "body": {"data": _b64url(html_body.encode()), "size": 1},
                        }
                    ],
                },
                {
                    "mimeType": "application/pdf",
                    "filename": "extracto.pdf",
                    "headers": [],
                    "body": {"attachmentId": "ANGj", "size": 1000},
                },
            ],
        },
    }


@pytest.mark.unit
class TestGetMessage:
    async def test_get_message_arma_el_mensaje_y_el_cuerpo(
        self, make_client: ClientFactory
    ) -> None:
        fixture = bancolombia_fixtures()[0]
        seen: list[httpx.URL] = []

        def handler(request: httpx.Request) -> httpx.Response:
            seen.append(request.url)
            return httpx.Response(200, json=_full_message(fixture.body))

        client = make_client(handler)

        msg = await client.get_message(_SECRET_ACCESS, "18f0c0ffee")

        assert seen[0].path == "/gmail/v1/users/me/messages/18f0c0ffee"
        assert seen[0].params["format"] == "full"
        assert msg.id == "18f0c0ffee"
        assert msg.sender == (
            "Bancolombia <alertasynotificaciones@an.notificacionesbancolombia.com>"
        )
        assert msg.internal_date == datetime(2024, 5, 1, 21, 0, 31, tzinfo=UTC)
        assert msg.payload.parts[1].filename == "extracto.pdf"
        assert msg.payload.parts[1].data == b""
        assert "Bancolombia: Compraste $176.824,00" in msg.body()

    async def test_get_message_charset_latin1(self, make_client: ClientFactory) -> None:
        payload = {
            "id": "x1",
            "internalDate": "0",
            "payload": {
                "mimeType": "text/plain",
                "headers": [
                    {"name": "From", "value": "a@b.co"},
                    {"name": "Content-Type", "value": "text/plain; charset=ISO-8859-1"},
                ],
                "body": {"data": _b64url("PANADERÍA".encode("latin-1"))},
            },
        }
        client = make_client(lambda _: httpx.Response(200, json=payload))

        msg = await client.get_message(_SECRET_ACCESS, "x1")

        assert msg.body() == "PANADERÍA"

    async def test_get_message_sin_from_queda_vacio(self, make_client: ClientFactory) -> None:
        payload = {"id": "x2", "internalDate": "0", "payload": {"mimeType": "text/plain"}}
        client = make_client(lambda _: httpx.Response(200, json=payload))

        msg = await client.get_message(_SECRET_ACCESS, "x2")

        assert msg.sender == ""
        assert msg.body() == ""

    async def test_get_message_malformado_es_rechazo(self, make_client: ClientFactory) -> None:
        client = make_client(lambda _: httpx.Response(200, json={"id": "x"}))
        with pytest.raises(GmailRequestRejected):
            await client.get_message(_SECRET_ACCESS, "x")


@pytest.mark.unit
class TestErroresTransitorios:
    @pytest.mark.parametrize("status", [500, 502, 503, 429])
    async def test_5xx_y_429_son_transitorios(
        self, make_client: ClientFactory, status: int
    ) -> None:
        client = make_client(lambda _: httpx.Response(status, text="boom"))
        with pytest.raises(GmailTransientError):
            await client.get_message(_SECRET_ACCESS, "x")
        with pytest.raises(GmailTransientError):
            await client.access_token(_SECRET_REFRESH)

    async def test_timeout_es_transitorio(self, make_client: ClientFactory) -> None:
        def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ReadTimeout("lento", request=request)

        client = make_client(handler)
        with pytest.raises(GmailTransientError):
            await client.history_new_message_ids(_SECRET_ACCESS, 1)

    async def test_error_de_red_es_transitorio(self, make_client: ClientFactory) -> None:
        def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.ConnectError("sin red", request=request)

        client = make_client(handler)
        with pytest.raises(GmailTransientError):
            await client.watch(_SECRET_ACCESS, "t")

    async def test_otro_4xx_es_rechazo(self, make_client: ClientFactory) -> None:
        client = make_client(lambda _: httpx.Response(403, json={"error": {"code": 403}}))
        with pytest.raises(GmailRequestRejected):
            await client.recent_message_ids(_SECRET_ACCESS)

    async def test_200_no_json_es_rechazo(self, make_client: ClientFactory) -> None:
        client = make_client(lambda _: httpx.Response(200, text="<html>proxy</html>"))
        with pytest.raises(GmailRequestRejected):
            await client.recent_message_ids(_SECRET_ACCESS)


@pytest.mark.unit
class TestLogsSinSecretos:
    async def test_logs_solo_llevan_operacion_status_y_latencia(
        self, make_client: ClientFactory
    ) -> None:
        fixture = bancolombia_fixtures()[0]

        def handler(request: httpx.Request) -> httpx.Response:
            url = str(request.url)
            if url == _TOKEN_URL:
                return httpx.Response(
                    200, json={"access_token": _SECRET_ACCESS, "refresh_token": _SECRET_REFRESH}
                )
            if url.endswith("/profile"):
                return httpx.Response(200, json={"emailAddress": _ACCOUNT_EMAIL})
            return httpx.Response(200, json=_full_message(fixture.body))

        client = make_client(handler)

        with structlog.testing.capture_logs() as logs:
            await client.exchange_code(_SECRET_CODE)
            await client.get_message(_SECRET_ACCESS, "18f0c0ffee")

        assert [entry["operation"] for entry in logs] == ["token", "profile", "messages.get"]
        for entry in logs:
            assert set(entry) <= {"event", "log_level", "operation", "status_code", "latency_ms"}
        dumped = json.dumps(logs)
        for secret in (_SECRET_ACCESS, _SECRET_REFRESH, _SECRET_CODE, _ACCOUNT_EMAIL, "18f0c0ffee"):
            assert secret not in dumped
        assert "Compraste" not in dumped


@pytest.mark.unit
async def test_adaptador_cumple_el_puerto() -> None:
    async with httpx.AsyncClient() as http:
        port: GmailClientPort = GoogleGmailClient(http, client_id="c", client_secret="s")
        assert port is not None
