"""Middleware ASGI puro: correlaciona requests via `X-Request-ID` y loguea acceso sin PII.

No usa `BaseHTTPMiddleware` (rompe streaming/backpressure); implementa el protocolo
ASGI directamente, como exige la spec 009 SS5 (logs sin cuerpo/query string).
"""

import re
import time
import uuid
from collections.abc import Awaitable, Callable, Iterable, MutableMapping
from typing import Any

import structlog

Scope = MutableMapping[str, Any]
Message = MutableMapping[str, Any]
Receive = Callable[[], Awaitable[Message]]
Send = Callable[[Message], Awaitable[None]]
ASGIApp = Callable[[Scope, Receive, Send], Awaitable[None]]

_REQUEST_ID_PATTERN = re.compile(r"^[A-Za-z0-9-]{1,64}$")

_logger = structlog.get_logger()


class RequestIdMiddleware:
    """Asigna/propaga `X-Request-ID`, liga contextvars de structlog y loguea `http_request`."""

    def __init__(self, app: ASGIApp) -> None:
        self._app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self._app(scope, receive, send)
            return

        request_id = _extract_request_id(scope)
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(request_id=request_id)

        status_holder: dict[str, int] = {}
        started_at = time.monotonic()

        async def send_wrapper(message: Message) -> None:
            if message["type"] == "http.response.start":
                status_holder["status"] = message["status"]
                headers = list(message.get("headers", []))
                headers.append((b"x-request-id", request_id.encode("ascii")))
                message["headers"] = headers
            await send(message)

        try:
            await self._app(scope, receive, send_wrapper)
        finally:
            duration_ms = int((time.monotonic() - started_at) * 1000)
            log_kwargs: dict[str, Any] = {
                "method": scope.get("method", ""),
                "route": _route_template(scope),
                "status": status_holder.get("status", 0),
                "duration_ms": duration_ms,
            }
            state: dict[str, Any] | None = scope.get("state")
            user_id: Any = state.get("user_id") if isinstance(state, dict) else None
            if user_id is not None:
                log_kwargs["user_id"] = user_id
            _logger.info("http_request", **log_kwargs)


def _extract_request_id(scope: Scope) -> str:
    for key, value in scope.get("headers", []):
        if key == b"x-request-id":
            candidate = value.decode("latin-1")
            if _REQUEST_ID_PATTERN.match(candidate):
                return candidate
            break
    return str(uuid.uuid4())


def _route_template(scope: Scope) -> str:
    """Devuelve la plantilla de ruta si el router la expuso; nunca la ruta cruda.

    El path crudo puede contener identificadores de recursos; para no arriesgar
    filtrarlos, nunca se usa `scope["path"]`. Se intenta primero `scope["route"]`
    (por si una version futura de Starlette lo publica); si no esta, se busca en
    `scope["app"].routes` la ruta cuyo `endpoint` coincide con `scope["endpoint"]`
    (dejado por el router al hacer match, incluso cuando levanta una excepcion
    despues, p. ej. 422/validation). Si no hay match, se reporta "unmatched".
    """
    route = scope.get("route")
    path = getattr(route, "path", None)
    if isinstance(path, str):
        return path

    endpoint = scope.get("endpoint")
    app = scope.get("app")
    routes: Iterable[Any] | None = getattr(app, "routes", None)
    if endpoint is not None and routes is not None:
        found = _find_route_path(routes, endpoint)
        if found is not None:
            return found
    return "unmatched"


def _find_route_path(routes: Iterable[Any], endpoint: object, prefix: str = "") -> str | None:
    """Busca recursivamente (via `Mount`/`.routes` anidados) la ruta de `endpoint`."""
    for route in routes:
        route_path = getattr(route, "path", None)
        route_prefix = f"{prefix}{route_path}" if isinstance(route_path, str) else prefix

        route_endpoint = getattr(route, "endpoint", None)
        if (
            route_endpoint is not None
            and route_endpoint is endpoint
            and isinstance(route_path, str)
        ):
            return route_prefix

        nested_routes = getattr(route, "routes", None)
        if nested_routes:
            found = _find_route_path(nested_routes, endpoint, route_prefix)
            if found is not None:
                return found
    return None
