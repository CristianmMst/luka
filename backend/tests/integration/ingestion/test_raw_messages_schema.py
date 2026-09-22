"""Tests de integracion del esquema de ingestion: migracion 0003 `raw_messages`
(spec 004 SS2.7, F2.1).

Sin repos de dominio todavia (ese trabajo llega en tareas futuras de Fase 2): estos
tests ejercitan directamente la tabla via SQL, igual que
`tests/integration/ledger/test_schema.py`.
"""

from uuid import UUID

import pytest
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.db import clean_user_tables
from support.raw_messages import insert_raw_message

pytestmark = pytest.mark.integration


async def _insert_user(session: AsyncSession, *, sub: str, email: str) -> UUID:
    result = await session.execute(
        text("INSERT INTO users (google_sub, email) VALUES (:sub, :email) RETURNING id"),
        {"sub": sub, "email": email},
    )
    return result.scalar_one()


async def test_duplicar_user_id_channel_external_id_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-raw-dup", email="raw-dup@example.com")
        await session.commit()

    await insert_raw_message(
        session_factory, user_id=user_id, channel="email", external_id="msg-duplicado"
    )

    with pytest.raises(IntegrityError):
        await insert_raw_message(
            session_factory, user_id=user_id, channel="email", external_id="msg-duplicado"
        )


async def test_mismo_external_id_en_otro_canal_esta_permitido(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-raw-otro-canal", email="raw-otro-canal@example.com"
        )
        await session.commit()

    await insert_raw_message(
        session_factory, user_id=user_id, channel="email", external_id="msg-compartido"
    )
    # No debe lanzar: la unicidad es (user_id, channel, external_id), no solo
    # (user_id, external_id).
    await insert_raw_message(
        session_factory, user_id=user_id, channel="notification", external_id="msg-compartido"
    )


async def test_channel_invalido_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-raw-channel", email="raw-channel@example.com"
        )
        await session.commit()

    with pytest.raises(IntegrityError):
        await insert_raw_message(session_factory, user_id=user_id, channel="whatsapp")


async def test_bank_invalido_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-raw-bank", email="raw-bank@example.com")
        await session.commit()

    with pytest.raises(IntegrityError):
        await insert_raw_message(session_factory, user_id=user_id, bank="banco_fantasma")


async def test_status_invalido_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(session, sub="sub-raw-status", email="raw-status@example.com")
        await session.commit()

    with pytest.raises(IntegrityError):
        await insert_raw_message(session_factory, user_id=user_id, status="en_camino")


async def test_borrar_usuario_encascada_raw_messages(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-raw-cascada", email="raw-cascada@example.com"
        )
        await session.commit()

    await insert_raw_message(session_factory, user_id=user_id)

    async with session_factory() as session:
        await session.execute(text("DELETE FROM users WHERE id = :id"), {"id": user_id})
        await session.commit()

    async with session_factory() as session:
        cantidad = (
            await session.execute(
                text("SELECT count(*) FROM raw_messages WHERE user_id = :id"), {"id": user_id}
            )
        ).scalar_one()

    assert cantidad == 0


async def test_catalogo_de_constraints_e_indices_de_raw_messages(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        constraints = (
            await session.execute(
                text("SELECT conname FROM pg_constraint WHERE conrelid = 'raw_messages'::regclass")
            )
        ).scalars()
        result = await session.execute(
            text("SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'raw_messages'")
        )
        indices = {row.indexname: row.indexdef for row in result}

    assert {
        "pk_raw_messages",
        "fk_raw_messages_user_id_users",
        "uq_raw_messages_user_id_channel_external_id",
        "ck_raw_messages_channel_valido",
        "ck_raw_messages_bank_valido",
        "ck_raw_messages_status_valido",
    } <= set(constraints)
    assert "ix_raw_messages_user_id_status" in indices
    assert "ix_raw_messages_purge_after" in indices
    assert "WHERE (body IS NOT NULL)" in indices["ix_raw_messages_purge_after"]


async def test_db_clean_vacia_raw_messages(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    """La limpieza entre tests (`db_clean`) borra `raw_messages` (Task 1/F2.1).

    Un solo test: antes eran dos acoplados por orden ("inserta" + "quedo vacia"),
    y el segundo pasaba vacuamente al correrlo aislado.
    """
    async with session_factory() as session:
        user_id = await _insert_user(
            session, sub="sub-raw-db-clean", email="raw-db-clean@example.com"
        )
        await session.commit()

    await insert_raw_message(session_factory, user_id=user_id)

    async with session_factory() as session:
        antes = (await session.execute(text("SELECT count(*) FROM raw_messages"))).scalar_one()
    assert antes == 1

    await clean_user_tables(session_factory)

    async with session_factory() as session:
        despues = (await session.execute(text("SELECT count(*) FROM raw_messages"))).scalar_one()
    assert despues == 0
