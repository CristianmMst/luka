"""Tests unitarios de `Logout`: idempotente, solo afecta tokens propios."""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from identity.fakes import FixedClock, InMemoryRefreshTokenRepo, NoopUoW
from luka.modules.identity.application.use_cases.logout import Logout
from luka.modules.identity.domain.sessions import hash_refresh_token, new_family

NOW = datetime(2024, 1, 1, 12, 0, 0, tzinfo=UTC)


def _build() -> tuple[Logout, InMemoryRefreshTokenRepo, NoopUoW]:
    tokens = InMemoryRefreshTokenRepo()
    uow = NoopUoW()
    use_case = Logout(tokens=tokens, clock=FixedClock(NOW), uow=uow)
    return use_case, tokens, uow


@pytest.mark.unit
async def test_revoca_el_token_propio() -> None:
    use_case, tokens, uow = _build()
    user_id = uuid4()
    raw = "raw-refresh"
    token = new_family(
        id=uuid4(),
        user_id=user_id,
        token_hash=hash_refresh_token(raw),
        family_id=uuid4(),
        now=NOW,
        ttl=timedelta(days=60),
        device_info=None,
    )
    await tokens.add(token)

    await use_case.execute(user_id, raw)

    stored = await tokens.get_by_hash_for_update(hash_refresh_token(raw))
    assert stored is not None
    assert stored.revoked_at == NOW
    assert uow.commits == 1


@pytest.mark.unit
async def test_token_desconocido_no_lanza_ni_confirma() -> None:
    use_case, _tokens, uow = _build()

    await use_case.execute(uuid4(), "no-existe")

    assert uow.commits == 0


@pytest.mark.unit
async def test_token_de_otro_usuario_no_se_revoca() -> None:
    use_case, tokens, uow = _build()
    owner_id = uuid4()
    other_id = uuid4()
    raw = "raw-refresh"
    token = new_family(
        id=uuid4(),
        user_id=owner_id,
        token_hash=hash_refresh_token(raw),
        family_id=uuid4(),
        now=NOW,
        ttl=timedelta(days=60),
        device_info=None,
    )
    await tokens.add(token)

    await use_case.execute(other_id, raw)

    stored = await tokens.get_by_hash_for_update(hash_refresh_token(raw))
    assert stored is not None
    assert stored.revoked_at is None
    assert uow.commits == 0
