"""Tests de integracion de las migraciones Alembic (spec 004 SS2.1-2.2, F1.1).

Usa una base de datos dedicada `finanzia_test_migrations` (nunca `finanzia_test`,
que usa el resto de la suite) porque estos tests hacen upgrade/downgrade/upgrade y
dejarian la base sin tablas para el resto de los tests si compartieran base.

El primer test (`test_upgrade_downgrade_upgrade_sin_errores`) deja la base en
`head` con las tablas vacias; los tests siguientes dependen de ese orden (pytest,
sin plugins de aleatorizacion, ejecuta los tests de un modulo en orden de
declaracion) para partir de un estado limpio. El ultimo test no modifica el
estado de las migraciones, por lo que la base queda en `head` al terminar.
"""

import asyncio
import os
from collections.abc import AsyncIterator
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine

_BACKEND_DIR = Path(__file__).resolve().parents[2]
_ALEMBIC_INI = _BACKEND_DIR / "alembic.ini"

_MIGRATIONS_DATABASE_URL = os.environ.get(
    "FINANZIA_TEST_MIGRATIONS_DATABASE_URL",
    "postgresql+asyncpg://finanzia:finanzia@localhost:5432/finanzia_test_migrations",
)


def _alembic_config() -> Config:
    cfg = Config(str(_ALEMBIC_INI))
    cfg.set_main_option("script_location", str(_BACKEND_DIR / "migrations"))
    cfg.set_main_option("sqlalchemy.url", _MIGRATIONS_DATABASE_URL)
    return cfg


@pytest.fixture(scope="module")
async def engine() -> AsyncIterator[AsyncEngine]:
    """Engine async contra `finanzia_test_migrations`, sin tocar el esquema."""
    eng = create_async_engine(_MIGRATIONS_DATABASE_URL)
    try:
        yield eng
    finally:
        await eng.dispose()


@pytest.mark.integration
async def test_upgrade_downgrade_upgrade_sin_errores() -> None:
    cfg = _alembic_config()

    await asyncio.to_thread(command.upgrade, cfg, "head")
    await asyncio.to_thread(command.downgrade, cfg, "base")
    await asyncio.to_thread(command.upgrade, cfg, "head")


@pytest.mark.integration
async def test_alembic_check_sin_drift() -> None:
    cfg = _alembic_config()

    # No debe lanzar: el esquema en `head` coincide con `Base.metadata`.
    await asyncio.to_thread(command.check, cfg)


@pytest.mark.integration
async def test_extension_citext_instalada(engine: AsyncEngine) -> None:
    async with engine.connect() as conn:
        result = await conn.execute(text("SELECT extname FROM pg_extension"))
        nombres_extensiones = {row[0] for row in result}

    assert "citext" in nombres_extensiones


@pytest.mark.integration
async def test_email_citext_es_case_insensitive(engine: AsyncEngine) -> None:
    async with engine.begin() as conn:
        await conn.execute(
            text("INSERT INTO users (google_sub, email) VALUES (:sub, :email)"),
            {"sub": "sub-citext", "email": "Persona@Example.com"},
        )

    async with engine.connect() as conn:
        result = await conn.execute(
            text("SELECT id FROM users WHERE email = 'persona@example.com'")
        )
        fila = result.first()

    assert fila is not None


@pytest.mark.integration
async def test_google_sub_duplicado_lanza_integrity_error(engine: AsyncEngine) -> None:
    async with engine.begin() as conn:
        await conn.execute(
            text("INSERT INTO users (google_sub, email) VALUES (:sub, :email)"),
            {"sub": "sub-duplicado", "email": "uno-duplicado@example.com"},
        )

    with pytest.raises(IntegrityError):
        async with engine.begin() as conn:
            await conn.execute(
                text("INSERT INTO users (google_sub, email) VALUES (:sub, :email)"),
                {"sub": "sub-duplicado", "email": "dos-duplicado@example.com"},
            )


@pytest.mark.integration
async def test_borrar_usuario_encascada_sus_refresh_tokens(engine: AsyncEngine) -> None:
    async with engine.begin() as conn:
        user_id = (
            await conn.execute(
                text("INSERT INTO users (google_sub, email) VALUES (:sub, :email) RETURNING id"),
                {"sub": "sub-cascada", "email": "cascada@example.com"},
            )
        ).scalar_one()
        await conn.execute(
            text(
                "INSERT INTO refresh_tokens (user_id, token_hash, family_id, expires_at) "
                "VALUES (:user_id, :token_hash, :family_id, now() + interval '1 day')"
            ),
            {"user_id": user_id, "token_hash": "hash-cascada", "family_id": user_id},
        )

    async with engine.begin() as conn:
        await conn.execute(text("DELETE FROM users WHERE id = :id"), {"id": user_id})

    async with engine.connect() as conn:
        result = await conn.execute(
            text("SELECT count(*) FROM refresh_tokens WHERE user_id = :id"),
            {"id": user_id},
        )
        cantidad = result.scalar_one()

    assert cantidad == 0


@pytest.mark.integration
async def test_nombres_de_constraints_e_indices_siguen_la_convencion(
    engine: AsyncEngine,
) -> None:
    async with engine.connect() as conn:
        result = await conn.execute(
            text(
                "SELECT constraint_name FROM information_schema.table_constraints "
                "WHERE table_name = 'users'"
            )
        )
        constraints_users = {row[0] for row in result}

        result = await conn.execute(
            text(
                "SELECT constraint_name FROM information_schema.table_constraints "
                "WHERE table_name = 'refresh_tokens'"
            )
        )
        constraints_refresh_tokens = {row[0] for row in result}

        result = await conn.execute(
            text("SELECT indexname FROM pg_indexes WHERE tablename = 'refresh_tokens'")
        )
        indices_refresh_tokens = {row[0] for row in result}

    assert {
        "pk_users",
        "uq_users_google_sub",
        "uq_users_email",
        "ck_users_status_valido",
    } <= constraints_users
    assert {
        "fk_refresh_tokens_user_id_users",
        "uq_refresh_tokens_token_hash",
    } <= constraints_refresh_tokens
    assert {"ix_refresh_tokens_user_id", "ix_refresh_tokens_family_id"} <= indices_refresh_tokens
