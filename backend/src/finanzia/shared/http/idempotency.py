"""Middleware ASGI puro: `Idempotency-Key` en mutaciones de la app (spec 005 SS1, 009 SS4).

Espeja `rate_limit_middleware.py`: protocolo ASGI directo (no `BaseHTTPMiddleware`)
para no romper streaming/backpressure, `redis_provider` perezoso (recien resuelto
en cada request, porque `app.state.redis` no existe hasta que corre el lifespan) y
fail-open ante cualquier falla de Redis.

Solo aplica a `POST` bajo `path_prefix` con header `Idempotency-Key` presente. El
body se drena una vez (para poder calcular el fingerprint y, si aplica, guardarlo)
y se re-inyecta intacto para que el resto de la app lo lea normalmente.
"""

from __future__ import annotations

import base64
import hashlib
import json
import uuid
from collections.abc import Awaitable, Callable, MutableMapping
from typing import Any

import redis.exceptions
import structlog
from redis.asyncio import Redis

from finanzia.shared.errors import AppError, ConflictError, ValidationAppError
from finanzia.shared.security import bearer_token, decode_access_token

Scope = MutableMapping[str, Any]
Message = MutableMapping[str, Any]
Receive = Callable[[], Awaitable[Message]]
Send = Callable[[Message], Awaitable[None]]
ASGIApp = Callable[[Scope, Receive, Send], Awaitable[None]]

_LOCK_TTL_S = 30
_PERSISTED_HEADERS = (b"content-type", b"location")
_MAX_STORED_BODY = 256 * 1024

_RedisErrors = (redis.exceptions.RedisError, OSError, TimeoutError)
_ProviderErrors = (AttributeError, LookupError, RuntimeError)

_logger = structlog.get_logger()


class IdempotencyMiddleware:
    """Deduplica `POST` bajo `path_prefix` via `Idempotency-Key` almacenada en Redis."""

    def __init__(
        self,
        app: ASGIApp,
        *,
        redis_provider: Callable[[], Redis],
        ttl_seconds: int,
        jwt_secret: str,
        path_prefix: str = "/v1/",
    ) -> None:
        self._app = app
        self._redis_provider = redis_provider
        self._ttl_seconds = ttl_seconds
        self._jwt_secret = jwt_secret
        self._path_prefix = path_prefix

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        raw_key = self._match(scope)
        if raw_key is None:
            await self._app(scope, receive, send)
            return
        await self._handle(scope, receive, send, raw_key)

    def _match(self, scope: Scope) -> str | None:
        """Devuelve el valor del header `Idempotency-Key` si esta request aplica."""
        if scope["type"] != "http" or scope.get("method") != "POST":
            return None
        path = scope.get("path", "")
        if not isinstance(path, str) or not path.startswith(self._path_prefix):
            return None
        return _get_header(scope, b"idempotency-key")

    async def _handle(self, scope: Scope, receive: Receive, send: Send, raw_key: str) -> None:
        try:
            uuid.UUID(raw_key)
        except ValueError:
            await _send_app_error(
                send,
                ValidationAppError(message="Idempotency-Key invalida", field="Idempotency-Key"),
            )
            return

        user_id = _silent_user_id(scope, self._jwt_secret)
        if user_id is None:
            # El bearer no es valido: la ruta protegida respondera 401 igual.
            await self._app(scope, receive, send)
            return

        body, replay_receive = await _drain_body(receive)
        fingerprint = _fingerprint(scope, body)
        record_key = f"idem:{user_id}:{raw_key}"
        lock_key = f"{record_key}:lock"

        try:
            redis_client = self._redis_provider()
            stored_raw = await redis_client.get(record_key)
        except (*_RedisErrors, *_ProviderErrors):
            _logger.warning("idempotency_backend_unavailable")
            await self._app(scope, replay_receive, send)
            return

        if stored_raw is not None:
            await _handle_existing_record(send, stored_raw, fingerprint)
            return

        try:
            acquired = await redis_client.set(lock_key, b"1", nx=True, ex=_LOCK_TTL_S)
        except _RedisErrors:
            _logger.warning("idempotency_backend_unavailable")
            await self._app(scope, replay_receive, send)
            return

        if not acquired:
            await _send_app_error(
                send, ConflictError(message="Solicitud en curso con la misma Idempotency-Key")
            )
            return

        await _run_and_store(
            self._app,
            scope,
            replay_receive,
            send,
            redis_client=redis_client,
            record_key=record_key,
            lock_key=lock_key,
            fingerprint=fingerprint,
            ttl_seconds=self._ttl_seconds,
        )


async def _handle_existing_record(send: Send, stored_raw: bytes, fingerprint: str) -> None:
    record = json.loads(stored_raw)
    if record["fingerprint"] == fingerprint:
        await _send_replay(send, record)
        return
    await _send_app_error(
        send,
        ConflictError(
            message="Idempotency-Key reutilizada con otro cuerpo", field="Idempotency-Key"
        ),
    )


async def _run_and_store(  # noqa: PLR0913 - firma interna, agrupa el estado de una sola operacion
    app: ASGIApp,
    scope: Scope,
    receive: Receive,
    send: Send,
    *,
    redis_client: Redis,
    record_key: str,
    lock_key: str,
    fingerprint: str,
    ttl_seconds: int,
) -> None:
    captured: dict[str, Any] = {}
    body_chunks: list[bytes] = []

    async def send_wrapper(message: Message) -> None:
        if message["type"] == "http.response.start":
            captured["status"] = message["status"]
            captured["headers"] = list(message.get("headers", []))
        elif message["type"] == "http.response.body":
            body_chunks.append(message.get("body", b""))
        await send(message)

    try:
        await app(scope, receive, send_wrapper)
    finally:
        try:
            await redis_client.delete(lock_key)
        except _RedisErrors:
            _logger.warning("idempotency_backend_unavailable")

    status = captured.get("status")
    if status is None or status >= 500:  # noqa: PLR2004 - umbral del contrato (5xx no se persiste)
        return

    body = b"".join(body_chunks)
    if len(body) > _MAX_STORED_BODY:
        # No se guarda el registro: una respuesta tan grande no se replica en Redis
        # (evita inflar la clave); la siguiente request con el mismo key re-ejecuta.
        _logger.warning("idempotency_response_too_large", size=len(body))
        return

    record = {
        "fingerprint": fingerprint,
        "status": status,
        "headers": _persisted_headers(captured.get("headers", [])),
        "body_b64": base64.b64encode(body).decode("ascii"),
    }
    try:
        await redis_client.set(record_key, json.dumps(record), ex=ttl_seconds)
    except _RedisErrors:
        _logger.warning("idempotency_backend_unavailable")


async def _drain_body(receive: Receive) -> tuple[bytes, Receive]:
    """Lee el body completo (respetando `more_body`) y arma un `receive` de replay."""
    chunks: list[bytes] = []
    more_body = True
    while more_body:
        message = await receive()
        if message.get("type") != "http.request":
            break
        chunks.append(message.get("body", b""))
        more_body = bool(message.get("more_body", False))
    body = b"".join(chunks)

    already_replayed = False

    async def replay_receive() -> Message:
        nonlocal already_replayed
        if not already_replayed:
            already_replayed = True
            return {"type": "http.request", "body": body, "more_body": False}
        return await receive()

    return body, replay_receive


def _fingerprint(scope: Scope, body: bytes) -> str:
    method = str(scope.get("method", ""))
    path = str(scope.get("path", ""))
    payload = f"{method}\n{path}\n".encode() + body
    return hashlib.sha256(payload).hexdigest()


def _persisted_headers(headers: list[tuple[bytes, bytes]]) -> dict[str, str]:
    result: dict[str, str] = {}
    for name, value in headers:
        if name.lower() in _PERSISTED_HEADERS:
            result[name.decode("latin-1").lower()] = value.decode("latin-1")
    return result


def _silent_user_id(scope: Scope, jwt_secret: str) -> str | None:
    """Decodifica el bearer JWT sin levantar: cualquier fallo => sin idempotencia."""
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


async def _send_app_error(send: Send, error: AppError) -> None:
    """Renderiza el mismo envoltorio que `install_error_handlers` (spec 005 SS1)."""
    body: dict[str, object] = {"code": error.code, "message": error.message}
    if error.field is not None:
        body["field"] = error.field
    payload = json.dumps({"error": body}).encode()

    headers = [(b"content-type", b"application/json")]
    for header_name, header_value in error.headers.items():
        headers.append((header_name.encode("latin-1"), header_value.encode("latin-1")))

    await send({"type": "http.response.start", "status": error.status, "headers": headers})
    await send({"type": "http.response.body", "body": payload})


async def _send_replay(send: Send, record: dict[str, Any]) -> None:
    stored_headers: dict[str, str] = record.get("headers", {})
    headers = [
        (name.encode("latin-1"), value.encode("latin-1")) for name, value in stored_headers.items()
    ]
    headers.append((b"idempotency-replayed", b"true"))
    body = base64.b64decode(record["body_b64"])

    await send({"type": "http.response.start", "status": record["status"], "headers": headers})
    await send({"type": "http.response.body", "body": body})
