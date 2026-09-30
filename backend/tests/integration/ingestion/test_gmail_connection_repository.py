"""Tests de integracion de `SqlAlchemyGmailConnectionRepository` (spec 004 §2.3, F3.2)."""

from collections.abc import Awaitable, Callable
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser

from luka.modules.ingestion.domain.entities import GmailConnection
from luka.modules.ingestion.domain.enums import GmailConnectionStatus
from luka.modules.ingestion.infrastructure.repositories import (
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


# --- F3.4: webhook push y sync --------------------------------------------------------


async def _seed(
    session_factory: async_sessionmaker[AsyncSession], connection: GmailConnection
) -> None:
    async with session_factory() as session:
        await SqlAlchemyGmailConnectionRepository(session).upsert(connection)
        await session.commit()


async def _get(
    session_factory: async_sessionmaker[AsyncSession], user_id: object
) -> GmailConnection:
    async with session_factory() as session:
        found = await SqlAlchemyGmailConnectionRepository(session).get(user_id)  # type: ignore[arg-type]
    assert found is not None
    return found


async def test_list_active_user_ids_by_email_solo_devuelve_conexiones_activas(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    ana = await user_factory()
    beatriz = await user_factory(sub="sub-2", email="beatriz@example.com")
    carla = await user_factory(sub="sub-3", email="carla@example.com")
    await _seed(session_factory, _connection(user_id=ana.id, email="compartida@gmail.com"))
    await _seed(
        session_factory,
        _connection(
            user_id=beatriz.id, email="compartida@gmail.com", status=GmailConnectionStatus.REVOKED
        ),
    )
    await _seed(session_factory, _connection(user_id=carla.id, email="otra@gmail.com"))

    async with session_factory() as session:
        found = await SqlAlchemyGmailConnectionRepository(session).list_active_user_ids_by_email(
            "compartida@gmail.com"
        )

    assert found == [ana.id]


async def test_record_sync_avanza_el_cursor_solo_hacia_adelante(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    await _seed(session_factory, _connection(user_id=user.id, history_id=500))
    later = datetime(2026, 5, 2, tzinfo=UTC)

    for history_id in (400, 700):
        async with session_factory() as session:
            await SqlAlchemyGmailConnectionRepository(session).record_sync(
                user.id, "ana@example.com", history_id, later
            )
            await session.commit()
        stored = await _get(session_factory, user.id)
        assert stored.history_id == max(500, history_id)
        assert stored.last_sync_at == later


async def test_record_sync_y_mark_status_no_tocan_la_conexion_de_otra_cuenta(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    # El usuario reconecto con otra cuenta mientras corria un sync de la vieja.
    user = await user_factory()
    await _seed(
        session_factory, _connection(user_id=user.id, email="nueva@gmail.com", history_id=10)
    )

    async with session_factory() as session:
        repo = SqlAlchemyGmailConnectionRepository(session)
        await repo.record_sync(user.id, "vieja@gmail.com", 999, NOW)
        await repo.mark_status(user.id, "vieja@gmail.com", GmailConnectionStatus.REVOKED, NOW)
        await session.commit()

    stored = await _get(session_factory, user.id)
    assert (stored.history_id, stored.status) == (10, GmailConnectionStatus.ACTIVE)
    assert stored.last_sync_at is None


async def test_mark_status_cambia_el_estado(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    await _seed(session_factory, _connection(user_id=user.id))

    async with session_factory() as session:
        await SqlAlchemyGmailConnectionRepository(session).mark_status(
            user.id, "ana@example.com", GmailConnectionStatus.REVOKED, NOW
        )
        await session.commit()

    assert (await _get(session_factory, user.id)).status is GmailConnectionStatus.REVOKED


# --- F3.5: renovacion diaria de watches --------------------------------------------


async def test_list_renewable_before_trae_activas_por_vencer_y_error_recuperables(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    por_vencer = await user_factory()
    lejos = await user_factory(sub="sub-2", email="beatriz@example.com")
    revocada = await user_factory(sub="sub-3", email="carla@example.com")
    sin_watch = await user_factory(sub="sub-4", email="diana@example.com")
    error_sin_watch = await user_factory(sub="sub-5", email="elena@example.com")
    error_por_vencer = await user_factory(sub="sub-6", email="fabiola@example.com")
    error_lejos = await user_factory(sub="sub-7", email="gloria@example.com")
    limite = NOW + timedelta(hours=48)
    error = GmailConnectionStatus.ERROR

    await _seed(
        session_factory,
        _connection(user_id=por_vencer.id, watch_expires_at=NOW + timedelta(hours=10)),
    )
    await _seed(
        session_factory,
        _connection(user_id=lejos.id, watch_expires_at=NOW + timedelta(days=6)),
    )
    await _seed(
        session_factory,
        _connection(
            user_id=revocada.id,
            watch_expires_at=NOW + timedelta(hours=1),
            status=GmailConnectionStatus.REVOKED,
        ),
    )
    await _seed(session_factory, _connection(user_id=sin_watch.id, watch_expires_at=None))
    await _seed(
        session_factory,
        _connection(user_id=error_sin_watch.id, watch_expires_at=None, status=error),
    )
    await _seed(
        session_factory,
        _connection(
            user_id=error_por_vencer.id, watch_expires_at=NOW + timedelta(hours=20), status=error
        ),
    )
    await _seed(
        session_factory,
        _connection(user_id=error_lejos.id, watch_expires_at=NOW + timedelta(days=6), status=error),
    )

    async with session_factory() as session:
        found = await SqlAlchemyGmailConnectionRepository(session).list_renewable_before(limite)

    assert [c.user_id for c in found] == [error_sin_watch.id, por_vencer.id, error_por_vencer.id]


async def test_renew_watch_no_mueve_un_cursor_existente_y_deja_la_conexion_active(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    await _seed(
        session_factory,
        _connection(user_id=user.id, history_id=500, status=GmailConnectionStatus.ERROR),
    )
    later = datetime(2026, 5, 8, 12, 0, tzinfo=UTC)

    for watch_history_id in (300, 700):  # ni retrocede ni se adelanta
        async with session_factory() as session:
            await SqlAlchemyGmailConnectionRepository(session).renew_watch(
                user.id, "ana@example.com", watch_history_id, later, NOW
            )
            await session.commit()

        stored = await _get(session_factory, user.id)
        assert stored.history_id == 500
        assert stored.watch_expires_at == later
        assert stored.status is GmailConnectionStatus.ACTIVE


async def test_renew_watch_siembra_un_cursor_nulo(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    await _seed(session_factory, _connection(user_id=user.id, history_id=None))

    async with session_factory() as session:
        await SqlAlchemyGmailConnectionRepository(session).renew_watch(
            user.id, "ana@example.com", 700, NOW + timedelta(days=7), NOW
        )
        await session.commit()

    assert (await _get(session_factory, user.id)).history_id == 700


async def test_renew_watch_no_toca_la_conexion_de_otra_cuenta(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    await _seed(
        session_factory, _connection(user_id=user.id, email="nueva@gmail.com", history_id=10)
    )
    later = datetime(2026, 5, 8, 12, 0, tzinfo=UTC)

    async with session_factory() as session:
        await SqlAlchemyGmailConnectionRepository(session).renew_watch(
            user.id, "vieja@gmail.com", 999, later, NOW
        )
        await session.commit()

    stored = await _get(session_factory, user.id)
    assert (stored.history_id, stored.watch_expires_at) == (10, None)


async def test_delete_con_email_solo_borra_si_la_fila_es_de_esa_cuenta(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    await _seed(session_factory, _connection(user_id=user.id, email="nueva@gmail.com"))

    async with session_factory() as session:
        repo = SqlAlchemyGmailConnectionRepository(session)
        wrong = await repo.delete(user.id, "vieja@gmail.com")
        await session.commit()
    assert wrong is False
    assert (await _get(session_factory, user.id)).email == "nueva@gmail.com"

    async with session_factory() as session:
        right = await SqlAlchemyGmailConnectionRepository(session).delete(
            user.id, "nueva@gmail.com"
        )
        await session.commit()
    assert right is True
