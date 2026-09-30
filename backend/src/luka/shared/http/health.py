"""Router de health-check: liveness (`/health`) y readiness (`/health/ready`)."""

import asyncio

from fastapi import APIRouter, Request, Response, status
from redis.asyncio import Redis
from redis.exceptions import RedisError
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncEngine

router = APIRouter(tags=["health"])

_CHECK_TIMEOUT_SECONDS = 2.0


@router.get("/health")
async def health() -> dict[str, str]:
    """Liveness: la aplicacion esta arriba y responde peticiones."""
    return {"status": "ok"}


async def _check_database(engine: AsyncEngine) -> bool:
    async def _select_1() -> None:
        async with engine.connect() as connection:
            await connection.execute(text("SELECT 1"))

    try:
        await asyncio.wait_for(_select_1(), timeout=_CHECK_TIMEOUT_SECONDS)
    except (SQLAlchemyError, TimeoutError, OSError):
        return False
    return True


async def _check_redis(redis: Redis) -> bool:
    try:
        # redis-py tipa `ping` de forma incompleta (union Awaitable[Any] | Any).
        pong = redis.ping()  # pyright: ignore[reportUnknownMemberType]
        await asyncio.wait_for(pong, timeout=_CHECK_TIMEOUT_SECONDS)
    except (RedisError, TimeoutError, OSError):
        return False
    return True


@router.get("/health/ready")
async def health_ready(request: Request, response: Response) -> dict[str, object]:
    """Readiness: verifica dependencias criticas (DB y Redis) con timeout corto."""
    engine: AsyncEngine = request.app.state.engine
    redis: Redis = request.app.state.redis

    database_ok, redis_ok = await asyncio.gather(
        _check_database(engine),
        _check_redis(redis),
    )

    checks = {
        "database": "ok" if database_ok else "error",
        "redis": "ok" if redis_ok else "error",
    }
    is_ready = database_ok and redis_ok
    response.status_code = status.HTTP_200_OK if is_ready else status.HTTP_503_SERVICE_UNAVAILABLE
    return {"status": "ok" if is_ready else "degraded", "checks": checks}
