"""Adaptador httpx de `GmailClientPort`: Google OAuth (`oauth2.googleapis.com`) y
Gmail REST API (`gmail.googleapis.com/gmail/v1/users/me`), spec 006 §2 y 005 §3/§4.

Nunca loguea tokens, codigos, emails, ids de mensaje ni contenido (spec 009 §5):
solo `gmail_request` con `operation` (plantilla fija), `status_code` y `latency_ms`.
El refresh token de `revoke` viaja en el cuerpo del POST, no en la URL.
"""

from __future__ import annotations

import base64
import binascii
import re
import time
from datetime import UTC, datetime
from typing import Any

import httpx
import structlog

from finanzia.modules.ingestion.domain.errors import (
    GmailAuthRevoked,
    GmailHistoryExpired,
    GmailRequestRejected,
    GmailTransientError,
)
from finanzia.modules.ingestion.domain.gmail_message import GmailMessage, MimePart

_logger = structlog.get_logger()

TOKEN_URL = "https://oauth2.googleapis.com/token"  # noqa: S105 - URL publica, no secreto
REVOKE_URL = "https://oauth2.googleapis.com/revoke"
GMAIL_API_BASE = "https://gmail.googleapis.com/gmail/v1/users/me"

_PAGE_SIZE = 100
_CHARSET_PATTERN = re.compile(r"""charset\s*=\s*["']?([^"';\s]+)""", re.IGNORECASE)


class GoogleGmailClient:
    """`GmailClientPort` real sobre un `httpx.AsyncClient` compartido.

    `redirect_uri` va vacio por defecto: es lo que exige Google al canjear un
    `serverAuthCode` emitido para una app Android (sin redirect propio).
    """

    def __init__(
        self,
        client: httpx.AsyncClient,
        *,
        client_id: str,
        client_secret: str,
        redirect_uri: str = "",
        timeout_s: float = 10.0,
    ) -> None:
        self._client = client
        self._client_id = client_id
        self._client_secret = client_secret
        self._redirect_uri = redirect_uri
        self._timeout_s = timeout_s

    # --- OAuth ---------------------------------------------------------------

    async def exchange_code(self, code: str) -> tuple[str, str]:
        grant = await self._token_request(
            {
                "grant_type": "authorization_code",
                "code": code,
                "client_id": self._client_id,
                "client_secret": self._client_secret,
                "redirect_uri": self._redirect_uri,
            }
        )
        refresh_token = grant.get("refresh_token")
        access_token = grant.get("access_token")
        if not isinstance(refresh_token, str) or not refresh_token:
            # Google solo entrega refresh token en el primer consentimiento (o con
            # `forceCodeForRefreshToken`); sin el no hay conexion posible.
            raise GmailRequestRejected("token: respuesta sin refresh_token")
        if not isinstance(access_token, str) or not access_token:
            raise GmailRequestRejected("token: respuesta sin access_token")
        profile = await self._api("profile", "GET", "/profile", access_token)
        email = profile.get("emailAddress")
        if not isinstance(email, str) or not email:
            raise GmailRequestRejected("profile: respuesta sin emailAddress")
        return refresh_token, email

    async def access_token(self, refresh_token: str) -> str:
        grant = await self._token_request(
            {
                "grant_type": "refresh_token",
                "refresh_token": refresh_token,
                "client_id": self._client_id,
                "client_secret": self._client_secret,
            }
        )
        access_token = grant.get("access_token")
        if not isinstance(access_token, str) or not access_token:
            raise GmailRequestRejected("token: respuesta sin access_token")
        return access_token

    async def revoke(self, refresh_token: str) -> None:
        response = await self._send("revoke", "POST", REVOKE_URL, data={"token": refresh_token})
        # 400 `invalid_token`: ya estaba revocado/expirado; revocar es idempotente.
        if response.status_code != httpx.codes.BAD_REQUEST:
            _raise_for_status("revoke", response)

    # --- Gmail API -----------------------------------------------------------

    async def watch(self, access_token: str, topic: str) -> tuple[int, datetime]:
        body = {"topicName": topic, "labelIds": ["INBOX"], "labelFilterBehavior": "INCLUDE"}
        data = await self._api("watch", "POST", "/watch", access_token, json=body)
        try:
            history_id = int(data["historyId"])
            expires_at = datetime.fromtimestamp(int(data["expiration"]) / 1000, tz=UTC)
        except (KeyError, TypeError, ValueError) as exc:
            raise GmailRequestRejected("watch: respuesta ilegible") from exc
        return history_id, expires_at

    async def stop(self, access_token: str) -> None:
        response = await self._send(
            "stop", "POST", f"{GMAIL_API_BASE}/stop", headers=_bearer(access_token)
        )
        _raise_for_status("stop", response)

    async def history_new_message_ids(
        self, access_token: str, start_history_id: int
    ) -> tuple[list[str], int]:
        ids: dict[str, None] = {}  # dict como set ordenado
        params: dict[str, str] = {
            "startHistoryId": str(start_history_id),
            "historyTypes": "messageAdded",
        }
        while True:
            response = await self._send(
                "history.list",
                "GET",
                f"{GMAIL_API_BASE}/history",
                headers=_bearer(access_token),
                params=params,
            )
            if response.status_code == httpx.codes.NOT_FOUND:
                raise GmailHistoryExpired("history.list: startHistoryId demasiado viejo")
            page = _json_object("history.list", response)
            try:
                for record in page.get("history", []):
                    for added in record.get("messagesAdded", []):
                        ids[str(added["message"]["id"])] = None
                new_history_id = int(page["historyId"])
            except (KeyError, TypeError, ValueError, AttributeError) as exc:
                raise GmailRequestRejected("history.list: respuesta ilegible") from exc
            next_token = page.get("nextPageToken")
            if not next_token:
                return list(ids), new_history_id
            params = {**params, "pageToken": str(next_token)}

    async def recent_message_ids(self, access_token: str, days: int = 7) -> list[str]:
        ids: list[str] = []
        params: dict[str, str] = {"q": f"newer_than:{days}d", "maxResults": str(_PAGE_SIZE)}
        while True:
            page = await self._api("messages.list", "GET", "/messages", access_token, params=params)
            try:
                ids.extend(str(item["id"]) for item in page.get("messages", []))
            except (KeyError, TypeError) as exc:
                raise GmailRequestRejected("messages.list: respuesta ilegible") from exc
            next_token = page.get("nextPageToken")
            if not next_token:
                return ids
            params = {**params, "pageToken": str(next_token)}

    async def get_message(self, access_token: str, message_id: str) -> GmailMessage:
        data = await self._api(
            "messages.get",
            "GET",
            f"/messages/{message_id}",
            access_token,
            params={"format": "full"},
        )
        try:
            payload = data["payload"]
            internal_date = datetime.fromtimestamp(int(data["internalDate"]) / 1000, tz=UTC)
            return GmailMessage(
                id=str(data["id"]),
                sender=_header(payload, "from") or "",
                internal_date=internal_date,
                payload=_parse_part(payload),
            )
        except (KeyError, TypeError, ValueError, AttributeError, binascii.Error) as exc:
            raise GmailRequestRejected("messages.get: respuesta ilegible") from exc

    # --- HTTP ----------------------------------------------------------------

    async def _token_request(self, form: dict[str, str]) -> dict[str, Any]:
        response = await self._send("token", "POST", TOKEN_URL, data=form)
        if response.is_client_error and _oauth_error(response) == "invalid_grant":
            raise GmailAuthRevoked("token: invalid_grant")
        return _json_object("token", response)

    async def _api(
        self,
        operation: str,
        method: str,
        path: str,
        access_token: str,
        **kwargs: Any,
    ) -> dict[str, Any]:
        response = await self._send(
            operation, method, f"{GMAIL_API_BASE}{path}", headers=_bearer(access_token), **kwargs
        )
        return _json_object(operation, response)

    async def _send(self, operation: str, method: str, url: str, **kwargs: Any) -> httpx.Response:
        """Hace la peticion y traduce timeouts/red/5xx/429 a `GmailTransientError`.

        Los demas codigos vuelven al llamador, que decide (404 de history,
        `invalid_grant`, 400 de revoke) antes de `_raise_for_status`.
        """
        start = time.monotonic()
        status_code: int | None = None
        try:
            response = await self._client.request(method, url, timeout=self._timeout_s, **kwargs)
            status_code = response.status_code
        except httpx.RequestError as exc:
            raise GmailTransientError(f"{operation}: {type(exc).__name__}") from exc
        finally:
            _logger.info(
                "gmail_request",
                operation=operation,
                status_code=status_code,
                latency_ms=int((time.monotonic() - start) * 1000),
            )
        if response.is_server_error or response.status_code == httpx.codes.TOO_MANY_REQUESTS:
            raise GmailTransientError(f"{operation}: {response.status_code}")
        return response


def _bearer(access_token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {access_token}"}


def _raise_for_status(operation: str, response: httpx.Response) -> None:
    if response.is_error:
        raise GmailRequestRejected(f"{operation}: {response.status_code}")


def _json_object(operation: str, response: httpx.Response) -> dict[str, Any]:
    _raise_for_status(operation, response)
    try:
        data = response.json()
    except ValueError as exc:
        raise GmailRequestRejected(f"{operation}: cuerpo no JSON") from exc
    if not isinstance(data, dict):
        raise GmailRequestRejected(f"{operation}: cuerpo no es un objeto")
    return data  # pyright: ignore[reportUnknownVariableType]


def _oauth_error(response: httpx.Response) -> str | None:
    try:
        data = response.json()
    except ValueError:
        return None
    return data.get("error") if isinstance(data, dict) else None  # pyright: ignore[reportUnknownMemberType, reportUnknownVariableType]


def _header(part: dict[str, Any], name: str) -> str | None:
    for header in part.get("headers") or []:
        if str(header.get("name", "")).lower() == name:
            return str(header.get("value", ""))
    return None


def _b64url_decode(data: str) -> bytes:
    return base64.urlsafe_b64decode(data + "=" * (-len(data) % 4))


def _parse_part(part: dict[str, Any]) -> MimePart:
    content_type = _header(part, "content-type") or ""
    charset_match = _CHARSET_PATTERN.search(content_type)
    raw = (part.get("body") or {}).get("data")
    return MimePart(
        mime_type=str(part.get("mimeType", "")),
        data=_b64url_decode(raw) if raw else b"",
        charset=charset_match.group(1) if charset_match else None,
        filename=str(part.get("filename") or ""),
        parts=tuple(_parse_part(child) for child in part.get("parts") or []),
    )


__all__ = ["GMAIL_API_BASE", "REVOKE_URL", "TOKEN_URL", "GoogleGmailClient"]
