"""Composition root: `create_app` ensambla la aplicacion FastAPI (spec 003 F0.4)."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import redis.asyncio as redis_asyncio
from fastapi import FastAPI

from finanzia.shared.db.engine import create_engine, create_session_factory
from finanzia.shared.http.health import router as health_router
from finanzia.shared.settings import Settings, get_settings


def create_app(settings: Settings | None = None) -> FastAPI:
    """Crea la aplicacion FastAPI, cableando settings, DB y Redis en `app.state`."""
    resolved_settings = settings if settings is not None else get_settings()

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
    app.include_router(health_router)
    return app
