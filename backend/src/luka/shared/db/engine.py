"""Fabrica del engine async de SQLAlchemy y del session factory (spec 003 F0.4)."""

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from luka.shared.settings import Settings


def create_engine(settings: Settings) -> AsyncEngine:
    """Crea el `AsyncEngine` de SQLAlchemy a partir de la configuracion de la app."""
    return create_async_engine(
        str(settings.database_url),
        pool_pre_ping=True,
        pool_size=settings.db_pool_size,
        echo=settings.db_echo,
        connect_args={"server_settings": {"timezone": "UTC"}},
    )


def create_session_factory(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    """Crea el `async_sessionmaker` asociado al engine dado."""
    return async_sessionmaker(engine, expire_on_commit=False)
