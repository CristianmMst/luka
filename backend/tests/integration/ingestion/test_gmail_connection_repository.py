"""Tests de integracion de `SqlAlchemyGmailConnectionRepository` (spec 004 §2.3, F3.2)."""

from collections.abc import Awaitable, Callable
from datetime import UTC, datetime
from uuid import uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser

from finanzia.modules.ingestion.domain.entities import GmailConnection
from finanzia.modules.ingestion.domain.enums import GmailConnectionStatus
from finanzia.modules.ingestion.infrastructure.repositories import (
    SqlAlchemyGmailConnectionRepository,
)

pytestmark = pytest.mark.integration

NOW = datetime(2026, 5, 1, 12, 0, tzinfo=UTC)


def _connection(*, user_id: object, **overrides: object) -> GmailConnection:
    defaults: dict[str, object] = {
        "user_id": user_id,
        "email": "ana@example.com",
        "refresh_token_enc": b"nonce-de-prueba+ciphertext",
        "history_id": None,
        "watch_expires_at": None,
        "status": GmailConnectionStatus.ACTIVE,
        "last_sync_at": None,
        "created_at": NOW,
        "updated_at": NOW,
    }
    defaults.update(overrides)
    return GmailConnection(**defaults)  # type: ignore[arg-type]


async def test_get_de_usuario_sin_conexion_devuelve_none(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        repo = SqlAlchemyGmailConnectionRepository(session)
        found = await repo.get(uuid4())
    assert found is None


async def test_upsert_inserta_y_get_la_recupera(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    connection = _connection(user_id=user.id, history_id=1000)

    async with session_factory() as session:
        repo = SqlAlchemyGmailConnectionRepository(session)
        await repo.upsert(connection)
        await session.commit()

    async with session_factory() as session:
        repo = SqlAlchemyGmailConnectionRepository(session)
        found = await repo.get(user.id)

    assert found is not None
    assert found.user_id == user.id
    assert found.email == "ana@example.com"
    assert found.refresh_token_enc == connection.refresh_token_enc
    assert found.history_id == 1000
    assert found.status == GmailConnectionStatus.ACTIVE


async def test_upsert_sobre_una_fila_existente_la_reemplaza(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()

    async with session_factory() as session:
        repo = SqlAlchemyGmailConnectionRepository(session)
        await repo.upsert(_connection(user_id=user.id, status=GmailConnectionStatus.ACTIVE))
        await session.commit()

        await repo.upsert(
            _connection(
                user_id=user.id,
                status=GmailConnectionStatus.REVOKED,
                refresh_token_enc=b"otro-blob-cifrado",
            )
        )
        await session.commit()

    async with session_factory() as session:
        repo = SqlAlchemyGmailConnectionRepository(session)
        found = await repo.get(user.id)

    assert found is not None
    assert found.status == GmailConnectionStatus.REVOKED
    assert found.refresh_token_enc == b"otro-blob-cifrado"


async def test_delete_de_fila_existente_devuelve_true_y_la_elimina(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()

    async with session_factory() as session:
        repo = SqlAlchemyGmailConnectionRepository(session)
        await repo.upsert(_connection(user_id=user.id))
        await session.commit()

        deleted = await repo.delete(user.id)
        await session.commit()
    assert deleted is True

    async with session_factory() as session:
        repo = SqlAlchemyGmailConnectionRepository(session)
        found = await repo.get(user.id)
    assert found is None


async def test_delete_de_usuario_sin_conexion_devuelve_false(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        repo = SqlAlchemyGmailConnectionRepository(session)
        deleted = await repo.delete(uuid4())
    assert deleted is False


async def test_upsert_sobre_una_fila_existente_conserva_created_at(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    later = datetime(2026, 6, 1, 12, 0, tzinfo=UTC)

    async with session_factory() as session:
        repo = SqlAlchemyGmailConnectionRepository(session)
        await repo.upsert(_connection(user_id=user.id, created_at=NOW, updated_at=NOW))
        await session.commit()

        await repo.upsert(_connection(user_id=user.id, created_at=later, updated_at=later))
        await session.commit()

    async with session_factory() as session:
        repo = SqlAlchemyGmailConnectionRepository(session)
        found = await repo.get(user.id)

    assert found is not None
    assert found.created_at == NOW
    assert found.updated_at == later
