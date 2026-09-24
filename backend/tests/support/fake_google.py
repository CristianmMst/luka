"""Google OAuth + Gmail API falsos sobre `httpx.MockTransport` (tests de integracion, F3.3).

La app usa el `GoogleGmailClient` real; solo cambia el transporte, asi que el
test ejercita tambien el adapter httpx. Nada de esto vive en `src/`.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any
from urllib.parse import parse_qs

import httpx

from finanzia.modules.ingestion.infrastructure.gmail_client import (
    GMAIL_API_BASE,
    REVOKE_URL,
    TOKEN_URL,
)

ACCOUNT_EMAIL = "cuenta-gmail-secreta@gmail.com"
REFRESH_TOKEN = "1//refresh-token-secreto"
ACCESS_TOKEN = "ya29.access-token-secreto"
HISTORY_ID = 987654
#: 2026-05-08T12:00:00Z en milisegundos, como lo devuelve `users.watch`.
WATCH_EXPIRATION_MS = 1_778_241_600_000


@dataclass
class FakeGoogle:
    """Estado y respuestas configurables del Google falso.

    `status_by_operation["watch"] = 503` hace fallar esa operacion con ese status;
    `refresh_token=None` simula un canje sin refresh token. `requests` guarda
    `(operacion, form o json)` de cada llamada para las aserciones.
    """

    refresh_token: str | None = REFRESH_TOKEN
    status_by_operation: dict[str, int] = field(default_factory=dict[str, int])
    requests: list[tuple[str, dict[str, Any]]] = field(
        default_factory=list[tuple[str, dict[str, Any]]]
    )

    def operations(self) -> list[str]:
        return [operation for operation, _ in self.requests]

    def transport(self) -> httpx.MockTransport:
        return httpx.MockTransport(self._handle)

    def _handle(self, request: httpx.Request) -> httpx.Response:
        url = str(request.url).split("?")[0]
        operation, payload = self._classify(request, url)
        self.requests.append((operation, payload))
        status = self.status_by_operation.get(operation)
        if status is not None:
            error = "invalid_grant" if status == httpx.codes.BAD_REQUEST else "error"
            return httpx.Response(status, json={"error": error})
        return self._ok(operation, payload)

    def _classify(self, request: httpx.Request, url: str) -> tuple[str, dict[str, Any]]:
        if url == TOKEN_URL:
            form = {k: v[0] for k, v in parse_qs(request.content.decode()).items()}
            kind = "exchange" if form.get("grant_type") == "authorization_code" else "refresh"
            return kind, form
        if url == REVOKE_URL:
            return "revoke", {k: v[0] for k, v in parse_qs(request.content.decode()).items()}
        path = url.removeprefix(GMAIL_API_BASE).lstrip("/")
        body: dict[str, Any] = {}
        if request.content:
            body = httpx.Response(200, content=request.content).json()
        return path, body

    def _ok(self, operation: str, payload: dict[str, Any]) -> httpx.Response:
        if operation == "exchange":
            grant: dict[str, Any] = {"access_token": ACCESS_TOKEN, "expires_in": 3599}
            if self.refresh_token is not None:
                grant["refresh_token"] = self.refresh_token
            return httpx.Response(200, json=grant)
        if operation == "refresh":
            return httpx.Response(200, json={"access_token": ACCESS_TOKEN, "expires_in": 3599})
        if operation == "profile":
            return httpx.Response(200, json={"emailAddress": ACCOUNT_EMAIL, "historyId": "1"})
        if operation == "watch":
            return httpx.Response(
                200, json={"historyId": str(HISTORY_ID), "expiration": str(WATCH_EXPIRATION_MS)}
            )
        if operation in {"stop", "revoke"}:
            return httpx.Response(200 if operation == "revoke" else 204)
        del payload
        return httpx.Response(404, json={"error": "not_found"})


__all__ = [
    "ACCESS_TOKEN",
    "ACCOUNT_EMAIL",
    "HISTORY_ID",
    "REFRESH_TOKEN",
    "WATCH_EXPIRATION_MS",
    "FakeGoogle",
]
