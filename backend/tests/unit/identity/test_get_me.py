"""Tests unitarios de `GetMe`."""

from datetime import UTC, datetime
from uuid import uuid4

import pytest

from finanzia.modules.identity.application.use_cases.get_me import GetMe
from finanzia.modules.identity.domain.entities import User, UserStatus
from finanzia.modules.identity.domain.errors import UserNotFound
from identity.fakes import InMemoryUserRepo

NOW = datetime(2024, 1, 1, 12, 0, 0, tzinfo=UTC)


@pytest.mark.unit
async def test_usuario_encontrado_devuelve_perfil_y_conexiones() -> None:
    users = InMemoryUserRepo()
    user = User(
        id=uuid4(),
        google_sub="google-sub-1",
        email="eva@example.com",
        display_name="Eva",
        photo_url=None,
        status=UserStatus.ACTIVE,
        consents={},
        created_at=NOW,
        updated_at=NOW,
    )
    await users.add(user)
    use_case = GetMe(users=users)

    result = await use_case.execute(user.id)

    assert result.user == user
    assert result.connections == {"gmail": "none", "notifications": "none"}


@pytest.mark.unit
async def test_usuario_inexistente_lanza_user_not_found() -> None:
    use_case = GetMe(users=InMemoryUserRepo())

    with pytest.raises(UserNotFound):
        await use_case.execute(uuid4())


@pytest.mark.unit
async def test_consentimiento_de_notificaciones_marca_conexion_granted() -> None:
    users = InMemoryUserRepo()
    user = User(
        id=uuid4(),
        google_sub="google-sub-2",
        email="finn@example.com",
        display_name="Finn",
        photo_url=None,
        status=UserStatus.ACTIVE,
        consents={"notifications": NOW},
        created_at=NOW,
        updated_at=NOW,
    )
    await users.add(user)
    use_case = GetMe(users=users)

    result = await use_case.execute(user.id)

    assert result.connections["notifications"] == "granted"
