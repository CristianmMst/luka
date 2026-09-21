"""Tests de integracion de `SqlAlchemyRawMessageRepository` (spec 004 §2.7, ruling 5).

Ejercita el repositorio contra Postgres real: idempotencia de `insert_if_absent`
(incluida bajo concurrencia real, ADR-7), `set_status` y `purge_bodies`.
"""

import asyncio
from collections.abc import Awaitable, Callable
from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from support.auth import AuthedUser

from finanzia.modules.ingestion.domain.entities import RawMessage
from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus
from finanzia.modules.ingestion.infrastructure.repositories import SqlAlchemyRawMessageRepository

pytestmark = pytest.mark.integration

NOW = datetime(2026, 5, 1, 12, 0, tzinfo=UTC)


def _msg(  # noqa: PLR0913 - fabrica de test, un parametro por atributo relevante
    *,
    user_id: UUID,
    external_id: str,
    channel: Channel = Channel.EMAIL,
    received_at: datetime = NOW,
    status: RawMessageStatus = RawMessageStatus.PENDING,
    body: str | None = "cuerpo de prueba",
    purge_after: datetime | None = None,
) -> RawMessage:
    return RawMessage(
        id=uuid4(),
        user_id=user_id,
        channel=channel,
        external_id=external_id,
        sender="alertasynotificaciones@an.notificacionesbancolombia.com",
        bank="bancolombia",
        body=body,
        status=status,
        received_at=received_at,
        purge_after=purge_after or (received_at + timedelta(days=90)),
    )


async def test_insert_if_absent_devuelve_none_en_el_segundo_insert(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    msg = _msg(user_id=user.id, external_id="repo-dup-1")

    async with session_factory() as session:
        repo = SqlAlchemyRawMessageRepository(session)
        first_id = await repo.insert_if_absent(msg)
        await session.commit()
    assert first_id == msg.id

    async with session_factory() as session:
        repo = SqlAlchemyRawMessageRepository(session)
        second = _msg(user_id=user.id, external_id="repo-dup-1")
        second_id = await repo.insert_if_absent(second)
        await session.commit()
    assert second_id is None


async def test_dos_sesiones_concurrentes_mismo_triple_generan_una_sola_fila(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()

    async def _insert() -> UUID | None:
        msg = _msg(user_id=user.id, external_id="repo-concurrente")
        async with session_factory() as session:
            repo = SqlAlchemyRawMessageRepository(session)
            result = await repo.insert_if_absent(msg)
            await session.commit()
            return result

    results = await asyncio.gather(_insert(), _insert())

    inserted = [r for r in results if r is not None]
    assert len(inserted) == 1

    async with session_factory() as session:
        repo = SqlAlchemyRawMessageRepository(session)
        rows = await repo.get_many_for_user(user.id, [inserted[0]])
    assert len(rows) == 1


async def test_get_by_external_id_encuentra_la_fila_existente(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    msg = _msg(user_id=user.id, external_id="repo-get-1")

    async with session_factory() as session:
        repo = SqlAlchemyRawMessageRepository(session)
        await repo.insert_if_absent(msg)
        await session.commit()

    async with session_factory() as session:
        repo = SqlAlchemyRawMessageRepository(session)
        found = await repo.get_by_external_id(user.id, Channel.EMAIL, "repo-get-1")
    assert found is not None
    assert found.id == msg.id
    assert found.status == RawMessageStatus.PENDING


async def test_set_status_actualiza_y_devuelve_true(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    msg = _msg(user_id=user.id, external_id="repo-status-1")

    async with session_factory() as session:
        repo = SqlAlchemyRawMessageRepository(session)
        await repo.insert_if_absent(msg)
        await session.commit()

        updated = await repo.set_status(msg.id, RawMessageStatus.PARSED, NOW)
        await session.commit()
    assert updated is True

    async with session_factory() as session:
        repo = SqlAlchemyRawMessageRepository(session)
        found = await repo.get(msg.id)
    assert found is not None
    assert found.status == RawMessageStatus.PARSED


async def test_set_status_de_id_inexistente_devuelve_false(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        repo = SqlAlchemyRawMessageRepository(session)
        updated = await repo.set_status(uuid4(), RawMessageStatus.PARSED, NOW)
    assert updated is False


async def test_purge_bodies_solo_anula_filas_con_purge_after_vencido(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    vencido = _msg(
        user_id=user.id,
        external_id="repo-purge-vencido",
        received_at=NOW - timedelta(days=200),
        purge_after=NOW - timedelta(days=110),
    )
    vigente = _msg(
        user_id=user.id,
        external_id="repo-purge-vigente",
        received_at=NOW,
        purge_after=NOW + timedelta(days=90),
    )

    async with session_factory() as session:
        repo = SqlAlchemyRawMessageRepository(session)
        await repo.insert_if_absent(vencido)
        await repo.insert_if_absent(vigente)
        await session.commit()

        count = await repo.purge_bodies(NOW, NOW)
        await session.commit()
    assert count == 1

    async with session_factory() as session:
        repo = SqlAlchemyRawMessageRepository(session)
        found_vencido = await repo.get(vencido.id)
        found_vigente = await repo.get(vigente.id)

    assert found_vencido is not None
    assert found_vencido.body is None
    assert found_vencido.status == RawMessageStatus.PENDING  # el status no cambia

    assert found_vigente is not None
    assert found_vigente.body is not None


async def test_purge_bodies_no_reafecta_filas_ya_purgadas(
    session_factory: async_sessionmaker[AsyncSession],
    user_factory: Callable[..., Awaitable[AuthedUser]],
) -> None:
    user = await user_factory()
    vencido = _msg(
        user_id=user.id,
        external_id="repo-purge-idempotente",
        received_at=NOW - timedelta(days=200),
        purge_after=NOW - timedelta(days=110),
    )

    async with session_factory() as session:
        repo = SqlAlchemyRawMessageRepository(session)
        await repo.insert_if_absent(vencido)
        await session.commit()
        await repo.purge_bodies(NOW, NOW)
        await session.commit()

        # Segunda pasada: la fila ya tiene `body IS NULL`, no debe contarse de nuevo.
        second_count = await repo.purge_bodies(NOW, NOW)
        await session.commit()
    assert second_count == 0
