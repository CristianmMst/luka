"""Middleware ASGI puro: rechaza cuerpos que excedan `max_bytes` (spec 009 SS4).

Estrategia de dos capas:
1. Si el cliente declara `Content-Length` mayor al limite, respondemos 400 de
   inmediato sin leer el body (evita bufferizar payloads gigantes).
2. Si no hay `Content-Length` fiable (streaming/chunked) envolvemos `receive` y
   contamos los bytes reales; al superar el limite levantamos `ValidationAppError`.
   Esta excepcion se levanta mientras Starlette consume el stream *dentro* del
   try/except de `ExceptionMiddleware` (este middleware se agrega antes que
   `SecurityHeaders`/`RequestId`, por lo que en la pila de ejecucion queda por
   fuera de `ExceptionMiddleware`), asi que el handler de `install_error_handlers`
   la renderiza igual que cualquier otro `AppError`.
"""

from collections.abc import Awaitable, Callable, MutableMapping
from typing import Any

from luka.shared.errors import ValidationAppError

Scope = MutableMapping[str, Any]
Message = MutableMapping[str, Any]
Receive = Callable[[], Awaitable[Message]]
Send = Callable[[Message], Awaitable[None]]
ASGIApp = Callable[[Scope, Receive, Send], Awaitable[None]]

_TOO_LARGE_BODY = (
    b'{"error":{"code":"validation_error","message":"Request body too large","field":"body"}}'
)


class BodyLimitMiddleware:
    """Limita el tamano del body de las peticiones HTTP a `max_bytes`."""

    def __init__(self, app: ASGIApp, max_bytes: int) -> None:
        self._app = app
        self._max_bytes = max_bytes

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self._app(scope, receive, send)
            return

        content_length = _content_length(scope)
        if content_length is not None and content_length > self._max_bytes:
            await _send_too_large(send)
            return

        received_bytes = 0

        async def receive_wrapper() -> Message:
            nonlocal received_bytes
            message = await receive()
            if message.get("type") == "http.request":
                received_bytes += len(message.get("body", b""))
                if received_bytes > self._max_bytes:
                    raise ValidationAppError(field="body", message="Request body too large")
            return message

        await self._app(scope, receive_wrapper, send)


def _content_length(scope: Scope) -> int | None:
    for key, value in scope.get("headers", []):
        if key == b"content-length":
            try:
                return int(value)
            except ValueError:
                return None
    return None


async def _send_too_large(send: Send) -> None:
    await send(
        {
            "type": "http.response.start",
            "status": 400,
            "headers": [(b"content-type", b"application/json")],
        }
    )
    await send({"type": "http.response.body", "body": _TOO_LARGE_BODY})
