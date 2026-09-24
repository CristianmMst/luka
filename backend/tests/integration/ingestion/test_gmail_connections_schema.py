"""Tests de integracion del esquema de ingestion: migracion 0005 `gmail_connections`
(spec 004 §2.3, F3.2).
"""

from uuid import UUID

import pytest
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.db import clean_user_tables
from support.gmail_connections import insert_gmail_connection

pytestmark = pytest.mark.integration


async def _insert_user(session: AsyncSession, *, sub: str, email: str) -> UUID:
    result = await session.execute(
        text("INSERT INTO users (google_sub, email) VALUES (:sub, :email) RETURNING id"),
        {"sub": sub, "email": email},
    )
    return result.scalar_one()


async def test_status_invalido_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-gmail-status", email="gmail-status@example.com"
        )
        await session.commit()

    with pytest.raises(IntegrityError):
        await insert_gmail_connection(session_factory, user_id=user_id, status="pausado")


async def test_dos_filas_para_el_mismo_usuario_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-gmail-dup", email="gmail-dup@example.com")
        await session.commit()

    await insert_gmail_connection(session_factory, user_id=user_id)

    with pytest.raises(IntegrityError):
        await insert_gmail_connection(session_factory, user_id=user_id)


async def test_borrar_usuario_encascada_gmail_connections(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-gmail-cascada", email="gmail-cascada@example.com"
        )
        await session.commit()

    await insert_gmail_connection(session_factory, user_id=user_id)

    async with session_factory() as session:
        await session.execute(text("DELETE FROM users WHERE id = :id"), {"id": user_id})
        await session.commit()

    async with session_factory() as session:
        cantidad = (
            await session.execute(
                text("SELECT count(*) FROM gmail_connections WHERE user_id = :id"), {"id": user_id}
            )
        ).scalar_one()

    assert cantidad == 0


async def test_catalogo_de_constraints_de_gmail_connections(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        constraints = (
            await session.execute(
                text(
                    "SELECT conname FROM pg_constraint "
                    "WHERE conrelid = 'gmail_connections'::regclass"
                )
            )
        ).scalars()

    assert {
        "pk_gmail_connections",
        "fk_gmail_connections_user_id_users",
        "ck_gmail_connections_status_valido",
    } <= set(constraints)


async def test_db_clean_vacia_gmail_connections(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-gmail-db-clean", email="gmail-db-clean@example.com"
        )
        await session.commit()

    await insert_gmail_connection(session_factory, user_id=user_id)

    async with session_factory() as session:
        antes = (await session.execute(text("SELECT count(*) FROM gmail_connections"))).scalar_one()
    assert antes == 1

    await clean_user_tables(session_factory)

    async with session_factory() as session:
        despues = (
            await session.execute(text("SELECT count(*) FROM gmail_connections"))
        ).scalar_one()
    assert despues == 0
