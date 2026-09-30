"""Adapter de Firebase Cloud Messaging, API HTTP v1 (spec 011 SS5-SS6).

`POST https://fcm.googleapis.com/v1/projects/{project}/messages:send` con un token
OAuth2 de la cuenta de servicio (`ServiceAccountTokenProvider`). Nunca se loguea el
token del dispositivo, ni el titulo ni el cuerpo del aviso (P1, spec 009 SS5): solo
el estado HTTP y el codigo de error de FCM.
"""

from __future__ import annotations

import asyncio
from typing import TYPE_CHECKING, Any, Protocol

import httpx
import structlog

from luka.modules.notifications.domain.entities import (
    DeviceToken,
    Platform,
    PushMessage,
    SendOutcome,
)
from luka.modules.notifications.domain.errors import PushUnavailable
from luka.modules.notifications.domain.messages import REMINDER_CHANNEL_ID

if TYPE_CHECKING:
    from collections.abc import Mapping

_logger = structlog.get_logger()

FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
_FCM_URL = "https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
#: Codigos de FCM que significan "este token ya no sirve": se borra.
_DEAD_TOKEN_CODES = frozenset({"UNREGISTERED", "INVALID_ARGUMENT", "SENDER_ID_MISMATCH"})
_TIMEOUT_S = 10.0


class AccessTokenProvider(Protocol):
    """Da un access token OAuth2 vigente para FCM."""

    async def token(self) -> str: ...


class ServiceAccountTokenProvider:
    """Access token de la cuenta de servicio de Firebase (google-auth, refresco en hilo)."""

    def __init__(self, info: Mapping[str, Any]) -> None:
        from google.oauth2 import service_account  # noqa: PLC0415 - solo si hay push

        self._credentials = service_account.Credentials.from_service_account_info(  # pyright: ignore[reportUnknownMemberType]
            dict(info), scopes=[FCM_SCOPE]
        )
        self._lock = asyncio.Lock()

    async def token(self) -> str:
        from google.auth.transport.requests import Request  # noqa: PLC0415

        async with self._lock:
            if not self._credentials.valid:
                await asyncio.to_thread(self._credentials.refresh, Request())
            return str(self._credentials.token)


def build_fcm_payload(token: DeviceToken, message: PushMessage) -> dict[str, Any]:
    """Cuerpo de `messages:send` para un token (spec 011 SS5)."""
    payload: dict[str, Any] = {
        "token": token.token,
        "notification": {"title": message.title, "body": message.body},
        "data": dict(message.data),
    }
    if token.platform is Platform.ANDROID:
        payload["android"] = {
            "priority": "high",
            "notification": {"channel_id": REMINDER_CHANNEL_ID, "visibility": "PRIVATE"},
        }
    else:
        payload["apns"] = {"payload": {"aps": {"sound": "default"}}}
    return {"message": payload}


def _fcm_error_code(response: httpx.Response) -> str | None:
    try:
        body = response.json()
    except ValueError:
        return None
    error = body.get("error") if isinstance(body, dict) else None
    if not isinstance(error, dict):
        return None
    for detail in error.get("details") or []:
        if isinstance(detail, dict) and detail.get("errorCode"):
            return str(detail["errorCode"])
    status = error.get("status")
    return str(status) if status else None


class FcmPushSender:
    """Implementacion de `PushSenderPort` sobre FCM HTTP v1."""

    def __init__(
        self, client: httpx.AsyncClient, credentials: AccessTokenProvider, *, project_id: str
    ) -> None:
        self._client = client
        self._credentials = credentials
        self._url = _FCM_URL.format(project_id=project_id)

    async def send(self, token: DeviceToken, message: PushMessage) -> SendOutcome:
        try:
            access_token = await self._credentials.token()
            response = await self._client.post(
                self._url,
                json=build_fcm_payload(token, message),
                headers={"Authorization": f"Bearer {access_token}"},
                timeout=_TIMEOUT_S,
            )
        except httpx.RequestError as exc:
            _logger.warning("push_failed", reason="network", error_type=type(exc).__name__)
            raise PushUnavailable from exc
        except Exception as exc:  # google-auth: refresh fallido (red o credencial)
            _logger.warning("push_failed", reason="credentials", error_type=type(exc).__name__)
            raise PushUnavailable from exc

        if response.is_success:
            return SendOutcome.SENT
        code = _fcm_error_code(response)
        if response.status_code == httpx.codes.NOT_FOUND or code in _DEAD_TOKEN_CODES:
            _logger.info("push_token_invalid", status=response.status_code, fcm_error=code)
            return SendOutcome.UNREGISTERED
        _logger.warning("push_failed", status=response.status_code, fcm_error=code)
        raise PushUnavailable


__all__ = [
    "AccessTokenProvider",
    "FcmPushSender",
    "ServiceAccountTokenProvider",
    "build_fcm_payload",
]
