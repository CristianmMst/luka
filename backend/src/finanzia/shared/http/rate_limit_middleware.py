"""Middleware ASGI puro: rate limiting por IP/usuario con ventana deslizante (spec 009 SS4).

Espeja `request_id.py`/`body_limit.py`: implementa el protocolo ASGI directamente
(no `BaseHTTPMiddleware`) para no romper streaming/backpressure.

El cliente Redis (y por lo tanto el `SlidingWindowLimiter`) se crea recien dentro
del lifespan de la app, *despues* de que `add_middleware` ya instancio este
middleware. Por eso `limiter_provider` es un callable perezoso (p. ej.
`lambda: app.state.rate_limiter`) en vez de una instancia — se resuelve en cada
request, cuando el lifespan ya corrio.
"""

from __future__ import annotations

import asyncio
import json
from collections.abc import Awaitable, Callable, MutableMapping, Sequence
from dataclasses import dataclass
from typing import Any, Literal

import redis.exceptions
import structlog

from finanzia.shared.errors import AppError, RateLimitedError
from finanzia.shared.http.rate_limit import Decision, SlidingWindowLimiter
from finanzia.shared.security import bearer_token, decode_access_token

Scope = MutableMapping[str, Any]
Message = MutableMapping[str, Any]
Receive = Callable[[], Awaitable[Message]]
Send = Callable[[Message], Awaitable[None]]
ASGIApp = Callable[[Scope, Receive, Send], Awaitable[None]]

_REDIS_TIMEOUT_S = 0.5

_logger = structlog.get_logger()


@dataclass(frozen=True, slots=True)
class Rule:
    """Regla de rate limiting: aplica a todo path que empiece con `path_prefix`."""

    path_prefix: str
    scope: Literal["ip", "user"]
    limit: int
    window_s: int
    name: str


class RateLimitMiddleware:
    """Evalua todas las reglas que matcheen el path; el primer rechazo responde 429."""

    def __init__(  # noqa: PLR0913 - firma fijada por controller ruling (Task 8/F1.4)
        self,
        app: ASGIApp,
        *,
        limiter_provider: Callable[[], SlidingWindowLimiter],
        rules: Sequence[Rule],
        jwt_secret: str,
        trust_proxy_headers: bool,
        exempt_prefixes: Sequence[str] = ("/health",),
    ) -> None:
        self._app = app
        self._limiter_provider = limiter_provider
        self._rules = rules
        self._jwt_secret = jwt_secret
        self._trust_proxy_headers = trust_proxy_headers
        self._exempt_prefixes = exempt_prefixes

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self._app(scope, receive, send)
            return

        path = scope.get("path", "")
        if any(path.startswith(prefix) for prefix in self._exempt_prefixes):
            await self._app(scope, receive, send)
            return

        matching_rules = [rule for rule in self._rules if path.startswith(rule.path_prefix)]
        if matching_rules:
            limiter = self._limiter_provider()
            ip = _client_ip(scope, trust_proxy_headers=self._trust_proxy_headers)
            user_id = _silent_user_id(scope, self._jwt_secret)

            for rule in matching_rules:
                if rule.scope == "user" and user_id is None:
                    continue
                key = (
                    f"rl:ip:{ip}:{rule.name}"
                    if rule.scope == "ip"
                    else f"rl:user:{user_id}:{rule.name}"
                )
                decision = await _safe_hit(limiter, key, rule)
                if decision is not None and not decision.allowed:
                    await _send_rate_limited(send, decision.retry_after)
                    return

        await self._app(scope, receive, send)


async def _safe_hit(limiter: SlidingWindowLimiter, key: str, rule: Rule) -> Decision | None:
    """Ejecuta `limiter.hit` con timeout; None (fail-open) si Redis no responde."""
    try:
        return await asyncio.wait_for(limiter.hit(key, rule.limit, rule.window_s), _REDIS_TIMEOUT_S)
    except (redis.exceptions.RedisError, OSError, TimeoutError):
        # No se loguea la IP/user_id: solo el nombre de la regla (spec 009 SS5).
        _logger.warning("rate_limit_backend_unavailable", rule=rule.name)
        return None


def _client_ip(scope: Scope, *, trust_proxy_headers: bool) -> str:
    """IP segun spec 009 SS1.5: `client.host`, salvo proxy de confianza con XFF."""
    if trust_proxy_headers:
        forwarded_for = _get_header(scope, b"x-forwarded-for")
        if forwarded_for is not None:
            first = forwarded_for.split(",")[0].strip()
            if first:
                return first

    client = scope.get("client")
    if not client:
        return "unknown"
    return str(client[0])


def _silent_user_id(scope: Scope, jwt_secret: str) -> str | None:
    """Decodifica el bearer JWT sin levantar: cualquier fallo => sin regla `user`."""
    authorization = _get_header(scope, b"authorization")
    try:
        token = bearer_token(authorization)
        claims = decode_access_token(token, jwt_secret)
    except AppError:
        return None
    return str(claims.sub)


def _get_header(scope: Scope, name: bytes) -> str | None:
    for key, value in scope.get("headers", []):
        if key == name:
            return value.decode("latin-1")
    return None


async def _send_rate_limited(send: Send, retry_after: int) -> None:
    """Renderiza el mismo envoltorio que `RateLimitedError` (status/code/mensaje/header)."""
    error = RateLimitedError(retry_after)
    body = json.dumps({"error": {"code": error.code, "message": error.message}}).encode()
    headers = [(b"content-type", b"application/json")]
    for header_name, header_value in error.headers.items():
        headers.append((header_name.encode("latin-1"), header_value.encode("latin-1")))

    await send({"type": "http.response.start", "status": error.status, "headers": headers})
    await send({"type": "http.response.body", "body": body})
