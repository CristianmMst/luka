"""Tests unitarios de `GetMe`."""

from datetime import UTC, datetime
from uuid import UUID, uuid4

import pytest

from identity.fakes import InMemoryUserRepo
from luka.modules.identity.application.use_cases.get_me import GetMe
from luka.modules.identity.domain.entities import User, UserStatus
from luka.modules.identity.domain.errors import UserNotFound

NOW = datetime(2024, 1, 1, 12, 0, 0, tzinfo=UTC)


class _FixedGmailStatus:
    """Doble de `GmailConnectionStatusPort`: mismo estado para cualquier usuario."""

    def __init__(self, status: str = "none") -> None:
        self.status = status
        self.asked: list[UUID] = []

    async def gmail_status(self, user_id: UUID) -> str:
        self.asked.append(user_id)
        return self.status


def _user(consents: dict[str, datetime] | None = None) -> User:
    return User(
        id=uuid4(),
        google_sub="google-sub-3",
        email="gael@example.com",
        display_name="Gael",
        photo_url=None,
        status=UserStatus.ACTIVE,
        consents=consents or {},
        created_at=NOW,
        updated_at=NOW,
    )


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
    use_case = GetMe(users=users, gmail=_FixedGmailStatus())

    result = await use_case.execute(user.id)

    assert result.user == user
    assert result.connections == {"gmail": "none", "notifications": "none"}


@pytest.mark.unit
async def test_usuario_inexistente_lanza_user_not_found() -> None:
    use_case = GetMe(users=InMemoryUserRepo(), gmail=_FixedGmailStatus())

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
    use_case = GetMe(users=users, gmail=_FixedGmailStatus())

    result = await use_case.execute(user.id)

    assert result.connections["notifications"] == "granted"


@pytest.mark.unit
async def test_conexion_gmail_sale_del_puerto_de_ingestion() -> None:
    users = InMemoryUserRepo()
    user = _user()
    await users.add(user)
    gmail = _FixedGmailStatus("revoked")

    result = await GetMe(users=users, gmail=gmail).execute(user.id)

    assert result.connections["gmail"] == "revoked"
    assert gmail.asked == [user.id]
