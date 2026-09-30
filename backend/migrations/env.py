"""Composition root de Alembic (async): resuelve la URL de conexion y el metadata
objetivo a partir de los modelos ORM de cada modulo (spec 004, F1.1).

Solo aqui se importan los `infrastructure.orm` de los modulos: `shared` nunca
importa `luka.modules` (ver import-linter, contrato Kernel).
"""

import asyncio
import os
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

# Composition root de metadata: import explicito de cada modulo con tablas.
import luka.modules.identity.infrastructure.orm
import luka.modules.ingestion.infrastructure.orm
import luka.modules.ledger.infrastructure.orm  # noqa: F401
from luka.shared.db.base import Base
from luka.shared.settings import Settings

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def _resolve_url() -> str:
    """Resuelve la URL de conexion: `alembic.ini` (runtime) > env var > Settings."""
    configured = config.get_main_option("sqlalchemy.url")
    if configured:
        return configured

    env_url = os.environ.get("LUKA_DATABASE_URL")
    if env_url:
        return env_url

    return str(Settings().database_url)  # pyright: ignore[reportCallIssue]


def run_migrations_offline() -> None:
    """Corre las migraciones en modo 'offline' (solo emite SQL, sin conexion real)."""
    context.configure(
        url=_resolve_url(),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        compare_server_default=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
        compare_server_default=True,
    )

    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Crea el engine async y ejecuta las migraciones dentro de `run_sync`."""
    configuration = config.get_section(config.config_ini_section, {})
    configuration["sqlalchemy.url"] = _resolve_url()

    connectable = async_engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    """Corre las migraciones en modo 'online' contra una conexion real."""
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
