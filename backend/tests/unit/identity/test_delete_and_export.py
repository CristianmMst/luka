"""Tests unitarios de `DeleteAccount` y `ExportUserData` (RF-11.2/11.3)."""

from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest

from identity.fakes import (
    FakeGmailCleanup,
    FixedClock,
    InMemoryRefreshTokenRepo,
    InMemoryUserRepo,
    NoopUoW,
    RecordingAudit,
    RecordingPublisher,
    SequenceTokenGenerator,
)
from luka.modules.identity.application.use_cases.delete_account import DeleteAccount
from luka.modules.identity.application.use_cases.export_data import ExportUserData
from luka.modules.identity.domain.entities import User, UserStatus
from luka.modules.identity.domain.errors import UserNotFound
from luka.modules.identity.domain.sessions import hash_refresh_token, new_family
from luka.modules.identity.events import UserDeleted

NOW = datetime(2026, 9, 29, 12, 0, tzinfo=UTC)


def _user() -> User:
    return User(
        id=uuid4(),
        google_sub="google-sub-9",
        email="ana@example.com",
        display_name="Ana Pérez",
        photo_url=None,
        status=UserStatus.ACTIVE,
        consents={},
        created_at=NOW - timedelta(days=30),
        updated_at=NOW,
    )


class _FakeExport:
    def __init__(self) -> None:
        self.asked: list[UUID] = []

    async def export(self, user_id: UUID) -> dict[str, object]:
        self.asked.append(user_id)
        return {"transactions": [{"amount": "45900.00"}], "gmail": {"status": "active"}}


@pytest.mark.unit
class TestDeleteAccount:
    async def test_desconecta_gmail_revoca_tokens_y_borra_al_usuario(self) -> None:
        users, tokens = InMemoryUserRepo(), InMemoryRefreshTokenRepo()
        gmail, events, audit, uow = (
            FakeGmailCleanup(),
            RecordingPublisher(),
            RecordingAudit(),
            NoopUoW(),
        )
        user = _user()
        await users.add(user)
        raw = "raw-refresh"
        await tokens.add(
            new_family(
                id=uuid4(),
                user_id=user.id,
                token_hash=hash_refresh_token(raw),
                family_id=uuid4(),
                now=NOW,
                ttl=timedelta(days=60),
                device_info=None,
            )
        )
        use_case = DeleteAccount(
            users=users,
            tokens=tokens,
            gmail=gmail,
            events=events,
            audit=audit,
            clock=FixedClock(NOW),
            ids=SequenceTokenGenerator(),
            uow=uow,
        )

        await use_case.execute(user.id)

        assert gmail.disconnected == [user.id]
        assert await users.get_by_id(user.id) is None
        token = await tokens.get_by_hash_for_update(hash_refresh_token(raw))
        assert token is not None
        assert token.revoked_at == NOW
        assert uow.commits == 1
        assert [e for e, _, _ in audit.events] == ["account_deleted"]
        (event,) = events.events
        assert isinstance(event, UserDeleted)
        assert event.user_id == user.id

    async def test_usuario_inexistente_lanza_user_not_found(self) -> None:
        gmail = FakeGmailCleanup()
        use_case = DeleteAccount(
            users=InMemoryUserRepo(),
            tokens=InMemoryRefreshTokenRepo(),
            gmail=gmail,
            events=RecordingPublisher(),
            audit=RecordingAudit(),
            clock=FixedClock(NOW),
            ids=SequenceTokenGenerator(),
            uow=NoopUoW(),
        )

        with pytest.raises(UserNotFound):
            await use_case.execute(uuid4())
        assert gmail.disconnected == []


@pytest.mark.unit
class TestExportUserData:
    async def test_arma_el_documento_con_perfil_y_datos_de_otros_modulos(self) -> None:
        users, audit, data = InMemoryUserRepo(), RecordingAudit(), _FakeExport()
        user = _user()
        await users.add(user)

        document = await ExportUserData(
            users=users, data=data, audit=audit, clock=FixedClock(NOW)
        ).execute(user.id)

        assert document["format_version"] == 1
        assert document["exported_at"] == NOW.isoformat()
        assert document["profile"] == {
            "email": "ana@example.com",
            "display_name": "Ana Pérez",
            "created_at": (NOW - timedelta(days=30)).isoformat(),
        }
        assert document["transactions"] == [{"amount": "45900.00"}]
        assert data.asked == [user.id]
        assert [e for e, _, _ in audit.events] == ["data_exported"]

    async def test_usuario_inexistente_lanza_user_not_found(self) -> None:
        with pytest.raises(UserNotFound):
            await ExportUserData(
                users=InMemoryUserRepo(),
                data=_FakeExport(),
                audit=RecordingAudit(),
                clock=FixedClock(NOW),
            ).execute(uuid4())
