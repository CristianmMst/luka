"""Tests de integracion de los repositorios SQLAlchemy de identity (ruling 1)."""

from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from finanzia.modules.identity.domain.entities import RefreshToken, User, UserStatus
from finanzia.modules.identity.infrastructure.repositories import (
    SqlAlchemyRefreshTokenRepository,
    SqlAlchemyUserRepository,
)


def _make_user(
    *, sub: str, email: str, now: datetime, consents: dict[str, datetime] | None = None
) -> User:
    return User(
        id=uuid4(),
        google_sub=sub,
        email=email,
        display_name="Nombre",
        photo_url=None,
        status=UserStatus.ACTIVE,
        consents=consents or {},
        created_at=now,
        updated_at=now,
    )


def _make_refresh_token(
    *, user_id: UUID, token_hash: str, family_id: UUID, now: datetime
) -> RefreshToken:
    return RefreshToken(
        id=uuid4(),
        user_id=user_id,
        token_hash=token_hash,
        family_id=family_id,
        expires_at=now + timedelta(days=60),
        revoked_at=None,
        device_info=None,
        created_at=now,
    )


@pytest.mark.integration
async def test_add_y_roundtrip_por_sub_e_id_incluye_consents(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    now = datetime.now(UTC).replace(microsecond=0)
    consent_ts = now - timedelta(days=1)
    user = _make_user(
        sub="sub-repo-1",
        email="repo1@example.com",
        now=now,
        consents={"notifications": consent_ts},
    )

    async with session_factory() as session:
        await SqlAlchemyUserRepository(session).add(user)
        await session.commit()

    async with session_factory() as session:
        repo = SqlAlchemyUserRepository(session)
        by_sub = await repo.get_by_google_sub("sub-repo-1")
        by_id = await repo.get_by_id(user.id)

    assert by_sub is not None
    assert by_sub.id == user.id
    assert by_sub.consents["notifications"] == consent_ts
    assert by_id is not None
    assert by_id.email == "repo1@example.com"


@pytest.mark.integration
async def test_email_duplicado_por_mayusculas_lanza_integrity_error(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    now = datetime.now(UTC).replace(microsecond=0)

    async with session_factory() as session:
        await SqlAlchemyUserRepository(session).add(
            _make_user(sub="sub-dup-1", email="dup@example.com", now=now)
        )
        await session.commit()

    async with session_factory() as session:
        with pytest.raises(IntegrityError):
            await SqlAlchemyUserRepository(session).add(
                _make_user(sub="sub-dup-2", email="DUP@Example.com", now=now)
            )


@pytest.mark.integration
async def test_get_by_hash_for_update_devuelve_none_si_no_existe(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    async with session_factory() as session:
        result = await SqlAlchemyRefreshTokenRepository(session).get_by_hash_for_update(
            "hash-inexistente"
        )

    assert result is None


@pytest.mark.integration
async def test_revoke_family_no_afecta_otra_familia(
    session_factory: async_sessionmaker[AsyncSession],
) -> None:
    now = datetime.now(UTC).replace(microsecond=0)
    family_a, family_b = uuid4(), uuid4()

    async with session_factory() as session:
        user = _make_user(sub="sub-fam", email="fam@example.com", now=now)
        await SqlAlchemyUserRepository(session).add(user)

        token_repo = SqlAlchemyRefreshTokenRepository(session)
        await token_repo.add(
            _make_refresh_token(user_id=user.id, token_hash="hash-a", family_id=family_a, now=now)
        )
        await token_repo.add(
            _make_refresh_token(user_id=user.id, token_hash="hash-b", family_id=family_b, now=now)
        )
        await session.commit()

        await token_repo.revoke_family(family_a, now)
        await session.commit()

        revoked = await token_repo.get_by_hash_for_update("hash-a")
        untouched = await token_repo.get_by_hash_for_update("hash-b")

    assert revoked is not None
    assert revoked.revoked_at == now
    assert untouched is not None
    assert untouched.revoked_at is None
