"""Middleware ASGI puro: cabeceras de seguridad basicas para toda respuesta (spec 009 SS4)."""

from collections.abc import Awaitable, Callable, MutableMapping
from typing import Any

Scope = MutableMapping[str, Any]
Message = MutableMapping[str, Any]
Receive = Callable[[], Awaitable[Message]]
Send = Callable[[Message], Awaitable[None]]
ASGIApp = Callable[[Scope, Receive, Send], Awaitable[None]]

_HSTS_VALUE = b"max-age=63072000; includeSubDomains"


class SecurityHeadersMiddleware:
    """Agrega cabeceras de seguridad; agrega HSTS solo cuando `is_prod` es True."""

    def __init__(self, app: ASGIApp, is_prod: bool) -> None:
        self._app = app
        self._is_prod = is_prod

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self._app(scope, receive, send)
            return

        async def send_wrapper(message: Message) -> None:
            if message["type"] == "http.response.start":
                headers = list(message.get("headers", []))
                headers.append((b"x-content-type-options", b"nosniff"))
                headers.append((b"cache-control", b"no-store"))
                headers.append((b"referrer-policy", b"no-referrer"))
                if self._is_prod:
                    headers.append((b"strict-transport-security", _HSTS_VALUE))
                message["headers"] = headers
            await send(message)

        await self._app(scope, receive, send_wrapper)
