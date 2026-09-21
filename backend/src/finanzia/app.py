"""Composition root: `create_app` ensambla la aplicacion FastAPI (spec 003 F0.4)."""

import asyncio
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import redis.asyncio as redis_asyncio
import redis.exceptions
import structlog
from fastapi import FastAPI

from finanzia.events_registry import build_registry, ensure_consumer_groups
from finanzia.modules.identity.infrastructure.api.errors import (
    EXCEPTION_MAP as IDENTITY_EXCEPTION_MAP,
)
from finanzia.modules.identity.infrastructure.api.router import router as identity_router
from finanzia.modules.identity.infrastructure.google_verifier import (
    FakeGoogleIdTokenVerifier,
    GoogleAuthIdTokenVerifier,
)
from finanzia.modules.ingestion.infrastructure.api.errors import INGESTION_EXCEPTION_MAP
from finanzia.modules.ingestion.infrastructure.api.router_config import (
    router as ingestion_config_router,
)
from finanzia.modules.ingestion.infrastructure.api.router_ingest import (
    router as ingestion_ingest_router,
)
from finanzia.modules.ledger.infrastructure.api.errors import LEDGER_EXCEPTION_MAP
from finanzia.modules.ledger.infrastructure.api.router_accounts import (
    router as ledger_accounts_router,
)
from finanzia.modules.ledger.infrastructure.api.router_categories import (
    router as ledger_categories_router,
)
from finanzia.modules.ledger.infrastructure.api.router_review import (
    router as ledger_review_router,
)
from finanzia.modules.ledger.infrastructure.api.router_transactions import (
    router as ledger_transactions_router,
)
from finanzia.shared.db.engine import create_engine, create_session_factory
from finanzia.shared.events.redis_streams import RedisStreamsEventBus
from finanzia.shared.http.body_limit import BodyLimitMiddleware
from finanzia.shared.http.error_handlers import install_error_handlers
from finanzia.shared.http.health import router as health_router
from finanzia.shared.http.idempotency import IdempotencyMiddleware
from finanzia.shared.http.rate_limit import SlidingWindowLimiter
from finanzia.shared.http.rate_limit_middleware import RateLimitMiddleware, Rule
from finanzia.shared.http.request_id import RequestIdMiddleware
from finanzia.shared.http.security_headers import SecurityHeadersMiddleware
from finanzia.shared.logging import configure_logging
from finanzia.shared.settings import Settings, get_settings

_logger = structlog.get_logger()

# `ensure_consumer_groups` en el lifespan (D10) no debe poder colgar el arranque
# de la API: un Redis que acepta la conexion TCP pero nunca responde (a
# diferencia de un connection-refused, que ya falla rapido) dejaria la espera
# sin cota (fix round 1, finding Important). `socket_connect_timeout`/
# `socket_timeout` del cliente cubren el resto de usos de `redis_client`
# (rate limiter, idempotency, bus) fuera de este `await` puntual.
_CONSUMER_GROUPS_TIMEOUT_S = 2.0
_REDIS_CONNECT_TIMEOUT_S = 2.0
_REDIS_SOCKET_TIMEOUT_S = 5.0


def _default_rate_limit_rules(settings: Settings) -> list[Rule]:
    """Reglas por defecto (spec 009 SS4, F1.4): `/auth/*` por IP y global por usuario.

    `ingest_user` (spec 009 §4, Task 5/F4.3) va ANTES de la regla global: el orden
    importa porque `RateLimitMiddleware` evalua todas las reglas que matcheen el
    path y el primer rechazo responde 429. Un `POST /v1/ingest/notifications`
    matchea ambas reglas (`/v1/ingest/` y `/v1/`) y consume cupo de las DOS, no
    solo de la mas especifica.
    """
    return [
        Rule("/v1/auth/", "ip", settings.rate_limit_auth_per_minute, 60, "auth_ip"),
        Rule("/v1/ingest/", "user", settings.rate_limit_ingest_per_minute, 60, "ingest_user"),
        Rule("/v1/", "user", settings.rate_limit_user_per_minute, 60, "user_global"),
    ]


def create_app(settings: Settings | None = None) -> FastAPI:
    """Crea la aplicacion FastAPI, cableando settings, DB y Redis en `app.state`."""
    resolved_settings = settings if settings is not None else get_settings()
    configure_logging(resolved_settings)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        engine = create_engine(resolved_settings)
        session_factory = create_session_factory(engine)
        redis_client = redis_asyncio.from_url(
            str(resolved_settings.redis_url),
            decode_responses=False,
            socket_connect_timeout=_REDIS_CONNECT_TIMEOUT_S,
            socket_timeout=_REDIS_SOCKET_TIMEOUT_S,
        )

        app.state.settings = resolved_settings
        app.state.engine = engine
        app.state.session_factory = session_factory
        app.state.redis = redis_client
        app.state.rate_limiter = SlidingWindowLimiter(redis_client)
        app.state.event_bus = RedisStreamsEventBus(redis_client, build_registry())
        # D10: crea (idempotente) los grupos de consumidores en el arranque de la
        # API, no solo en el worker, para que un evento publicado antes del primer
        # arranque del worker no se pierda. Fail-soft (igual que el rate limiter)
        # Y acotado en el tiempo (fix round 1): un Redis que acepta la conexion
        # TCP pero nunca responde no debe colgar el arranque de la API para
        # siempre; `asyncio.wait_for` corta la espera a los `_CONSUMER_GROUPS_
        # TIMEOUT_S` segundos.
        try:
            await asyncio.wait_for(
                ensure_consumer_groups(app.state.event_bus), timeout=_CONSUMER_GROUPS_TIMEOUT_S
            )
        except (redis.exceptions.RedisError, OSError, TimeoutError) as exc:
            _logger.warning("consumer_groups_not_ensured", error_type=type(exc).__name__)
        # Construido una unica vez por proceso (no por request): evita recrear la
        # sesion HTTP con cache de claves publicas de Google en cada login (review
        # final, item D). Settings ya prohibe "fake" en env="prod".
        app.state.google_verifier = (
            FakeGoogleIdTokenVerifier()
            if resolved_settings.google_verifier == "fake"
            else GoogleAuthIdTokenVerifier(resolved_settings.google_client_id)
        )

        try:
            yield
        finally:
            await redis_client.aclose()
            await engine.dispose()

    # En prod se apagan los docs interactivos y el schema OpenAPI (controller ruling,
    # review final item H): no hay motivo para exponer la superficie de la API sin
    # autenticacion en un ambiente publico.
    is_prod = resolved_settings.env == "prod"
    app = FastAPI(
        title="finanzia",
        lifespan=lifespan,
        docs_url=None if is_prod else "/docs",
        redoc_url=None if is_prod else "/redoc",
        openapi_url=None if is_prod else "/openapi.json",
    )

    # `add_middleware` apila en orden inverso: el ultimo agregado queda mas afuera.
    # Orden de ejecucion resultante: RequestId -> SecurityHeaders -> BodyLimit -> RateLimit
    # -> Idempotency -> router. Idempotency se agrega PRIMERO (queda mas adentro, junto
    # al router) para que ya haya pasado el rate limiting antes de tocar Redis por la
    # clave de idempotencia. `redis_provider`/`limiter_provider` son perezosos porque
    # `app.state.redis`/`app.state.rate_limiter` recien existen despues de que el
    # lifespan corrio (ver docstrings de IdempotencyMiddleware/RateLimitMiddleware).
    app.add_middleware(
        IdempotencyMiddleware,
        redis_provider=lambda: app.state.redis,
        ttl_seconds=resolved_settings.idempotency_ttl_seconds,
        jwt_secret=resolved_settings.jwt_secret.get_secret_value(),
    )
    app.add_middleware(
        RateLimitMiddleware,
        limiter_provider=lambda: app.state.rate_limiter,
        rules=_default_rate_limit_rules(resolved_settings),
        jwt_secret=resolved_settings.jwt_secret.get_secret_value(),
        trust_proxy_headers=resolved_settings.trust_proxy_headers,
    )
    app.add_middleware(BodyLimitMiddleware, max_bytes=resolved_settings.max_body_bytes)
    app.add_middleware(SecurityHeadersMiddleware, is_prod=resolved_settings.env == "prod")
    app.add_middleware(RequestIdMiddleware)

    install_error_handlers(
        app, [IDENTITY_EXCEPTION_MAP, LEDGER_EXCEPTION_MAP, INGESTION_EXCEPTION_MAP]
    )

    app.include_router(health_router)
    app.include_router(identity_router, prefix="/v1")
    app.include_router(ledger_transactions_router, prefix="/v1")
    app.include_router(ledger_categories_router, prefix="/v1")
    app.include_router(ledger_accounts_router, prefix="/v1")
    app.include_router(ledger_review_router, prefix="/v1")
    app.include_router(ingestion_ingest_router, prefix="/v1")
    app.include_router(ingestion_config_router, prefix="/v1")
    return app
