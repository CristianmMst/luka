"""Tests unitarios de `RefreshSession` (spec 009 SS2.2, AC-1.4)."""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from finanzia.modules.identity.application.use_cases.refresh_session import RefreshSession
from finanzia.modules.identity.domain.entities import User, UserStatus
from finanzia.modules.identity.domain.errors import (
    RefreshTokenExpired,
    RefreshTokenInvalid,
    RefreshTokenReused,
    UserNotFound,
)
from finanzia.modules.identity.domain.sessions import hash_refresh_token, new_family
from identity.fakes import (
    FakeAccessTokenIssuer,
    FixedClock,
    InMemoryRefreshTokenRepo,
    InMemoryUserRepo,
    NoopUoW,
    RecordingAudit,
    SequenceTokenGenerator,
)

NOW = datetime(2024, 1, 1, 12, 0, 0, tzinfo=UTC)
REFRESH_TTL = timedelta(days=60)


async def _seed_user_and_token(
    users: InMemoryUserRepo, tokens: InMemoryRefreshTokenRepo, *, raw: str = "raw-refresh"
) -> tuple[User, str]:
    user = User(
        id=uuid4(),
        google_sub="google-sub-1",
        email="dana@example.com",
        display_name="Dana",
        photo_url=None,
        status=UserStatus.ACTIVE,
        consents={},
        created_at=NOW,
        updated_at=NOW,
    )
    await users.add(user)
    token = new_family(
        id=uuid4(),
        user_id=user.id,
        token_hash=hash_refresh_token(raw),
        family_id=uuid4(),
        now=NOW,
        ttl=REFRESH_TTL,
        device_info="pixel-8",
    )
    await tokens.add(token)
    return user, raw


def _build(
    clock: FixedClock,
) -> tuple[RefreshSession, InMemoryUserRepo, InMemoryRefreshTokenRepo, RecordingAudit, NoopUoW]:
    users = InMemoryUserRepo()
    tokens = InMemoryRefreshTokenRepo()
    audit = RecordingAudit()
    uow = NoopUoW()
    use_case = RefreshSession(
        users=users,
        tokens=tokens,
        clock=clock,
        token_generator=SequenceTokenGenerator(),
        issuer=FakeAccessTokenIssuer(),
        audit=audit,
        uow=uow,
        refresh_ttl=REFRESH_TTL,
    )
    return use_case, users, tokens, audit, uow


@pytest.mark.unit
async def test_token_valido_rota_y_revoca_el_anterior_manteniendo_familia() -> None:
    clock = FixedClock(NOW)
    use_case, users, tokens, _audit, _uow = _build(clock)
    user, raw = await _seed_user_and_token(users, tokens)
    old_stored = await tokens.get_by_hash_for_update(hash_refresh_token(raw))
    assert old_stored is not None

    result = await use_case.execute(raw, device_info="pixel-8")

    assert result.user.id == user.id
    assert result.expires_in == 900
    assert result.refresh_token != raw

    refreshed_old = await tokens.get_by_hash_for_update(hash_refresh_token(raw))
    assert refreshed_old is not None
    assert refreshed_old.revoked_at == NOW

    new_stored = await tokens.get_by_hash_for_update(hash_refresh_token(result.refresh_token))
    assert new_stored is not None
    assert new_stored.family_id == old_stored.family_id
    assert new_stored.revoked_at is None


@pytest.mark.unit
async def test_reusar_token_ya_rotado_revoca_toda_la_familia_y_lanza() -> None:
    clock = FixedClock(NOW)
    use_case, users, tokens, audit, _uow = _build(clock)
    _user, raw = await _seed_user_and_token(users, tokens)

    first = await use_case.execute(raw, device_info="pixel-8")

    with pytest.raises(RefreshTokenReused):
        await use_case.execute(raw, device_info="pixel-8")

    # El token ya rotado sigue revocado...
    stale = await tokens.get_by_hash_for_update(hash_refresh_token(raw))
    assert stale is not None
    assert stale.revoked_at is not None

    # ...y el que se acababa de emitir tambien queda revocado (familia completa).
    just_issued = await tokens.get_by_hash_for_update(hash_refresh_token(first.refresh_token))
    assert just_issued is not None
    assert just_issued.revoked_at is not None

    events = [event for event, *_ in audit.events]
    assert "refresh_reuse_detected" in events


@pytest.mark.unit
async def test_token_expirado_lanza_y_queda_revocado() -> None:
    clock = FixedClock(NOW)
    use_case, users, tokens, _audit, _uow = _build(clock)
    _user, raw = await _seed_user_and_token(users, tokens)
    clock.advance(REFRESH_TTL + timedelta(seconds=1))

    with pytest.raises(RefreshTokenExpired):
        await use_case.execute(raw, device_info="pixel-8")

    stored = await tokens.get_by_hash_for_update(hash_refresh_token(raw))
    assert stored is not None
    assert stored.revoked_at is not None


@pytest.mark.unit
async def test_token_desconocido_lanza_invalid_sin_commit() -> None:
    clock = FixedClock(NOW)
    use_case, _users, _tokens, _audit, uow = _build(clock)

    with pytest.raises(RefreshTokenInvalid):
        await use_case.execute("no-existe", device_info=None)

    assert uow.commits == 0


@pytest.mark.unit
async def test_usuario_borrado_entre_emision_y_refresh_lanza_user_not_found() -> None:
    clock = FixedClock(NOW)
    use_case, users, tokens, _audit, _uow = _build(clock)
    user, raw = await _seed_user_and_token(users, tokens)
    del users._by_id[user.id]  # acceso directo al doble: simula usuario borrado

    with pytest.raises(UserNotFound):
        await use_case.execute(raw, device_info="pixel-8")


@pytest.mark.unit
async def test_ttl_desliza_al_refrescar_despues_de_10_dias() -> None:
    clock = FixedClock(NOW)
    use_case, users, tokens, _audit, _uow = _build(clock)
    _user, raw = await _seed_user_and_token(users, tokens)
    clock.advance(timedelta(days=10))
    refresh_time = clock.now()

    result = await use_case.execute(raw, device_info="pixel-8")

    new_stored = await tokens.get_by_hash_for_update(hash_refresh_token(result.refresh_token))
    assert new_stored is not None
    assert new_stored.expires_at == refresh_time + REFRESH_TTL
