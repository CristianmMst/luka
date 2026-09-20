"""Composition root: `create_app` ensambla la aplicacion FastAPI (spec 003 F0.4)."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import redis.asyncio as redis_asyncio
from fastapi import FastAPI

from finanzia.modules.identity.infrastructure.api.errors import (
    EXCEPTION_MAP as IDENTITY_EXCEPTION_MAP,
)
from finanzia.modules.identity.infrastructure.api.router import router as identity_router
from finanzia.shared.db.engine import create_engine, create_session_factory
from finanzia.shared.http.body_limit import BodyLimitMiddleware
from finanzia.shared.http.error_handlers import install_error_handlers
from finanzia.shared.http.health import router as health_router
from finanzia.shared.http.request_id import RequestIdMiddleware
from finanzia.shared.http.security_headers import SecurityHeadersMiddleware
from finanzia.shared.logging import configure_logging
from finanzia.shared.settings import Settings, get_settings


def create_app(settings: Settings | None = None) -> FastAPI:
    """Crea la aplicacion FastAPI, cableando settings, DB y Redis en `app.state`."""
    resolved_settings = settings if settings is not None else get_settings()
    configure_logging(resolved_settings)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        engine = create_engine(resolved_settings)
        session_factory = create_session_factory(engine)
        redis_client = redis_asyncio.from_url(
            str(resolved_settings.redis_url), decode_responses=False
        )

        app.state.settings = resolved_settings
        app.state.engine = engine
        app.state.session_factory = session_factory
        app.state.redis = redis_client

        try:
            yield
        finally:
            await redis_client.aclose()
            await engine.dispose()

    app = FastAPI(title="finanzia", lifespan=lifespan)

    # `add_middleware` apila en orden inverso: el ultimo agregado queda mas afuera.
    # Orden de ejecucion resultante: RequestId -> SecurityHeaders -> BodyLimit -> router.
    app.add_middleware(BodyLimitMiddleware, max_bytes=resolved_settings.max_body_bytes)
    app.add_middleware(SecurityHeadersMiddleware, is_prod=resolved_settings.env == "prod")
    app.add_middleware(RequestIdMiddleware)

    install_error_handlers(app, [IDENTITY_EXCEPTION_MAP])

    app.include_router(health_router)
    app.include_router(identity_router, prefix="/v1")
    return app
