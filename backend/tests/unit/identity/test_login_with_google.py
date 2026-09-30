"""Tests unitarios de `LoginWithGoogle` (spec 009 SS2.1, AC-1.1)."""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from identity.fakes import (
    FakeAccessTokenIssuer,
    FakeGoogleVerifier,
    FixedClock,
    InMemoryRefreshTokenRepo,
    InMemoryUserRepo,
    NoopUoW,
    RecordingAudit,
    SequenceTokenGenerator,
)
from luka.modules.identity.application.use_cases.login_with_google import LoginWithGoogle
from luka.modules.identity.domain.entities import GoogleIdentity, User, UserStatus
from luka.modules.identity.domain.errors import EmailNotVerified, InvalidGoogleToken
from luka.modules.identity.domain.sessions import hash_refresh_token

NOW = datetime(2024, 1, 1, 12, 0, 0, tzinfo=UTC)


def _build(identities: dict[str, GoogleIdentity]) -> tuple[LoginWithGoogle, dict[str, object]]:
    users = InMemoryUserRepo()
    tokens = InMemoryRefreshTokenRepo()
    audit = RecordingAudit()
    uow = NoopUoW()
    use_case = LoginWithGoogle(
        verifier=FakeGoogleVerifier(identities),
        users=users,
        tokens=tokens,
        clock=FixedClock(NOW),
        token_generator=SequenceTokenGenerator(),
        issuer=FakeAccessTokenIssuer(),
        audit=audit,
        uow=uow,
    )
    return use_case, {"users": users, "tokens": tokens, "audit": audit, "uow": uow}


@pytest.mark.unit
async def test_usuario_nuevo_se_crea_y_se_audita_login_sin_email() -> None:
    identity = GoogleIdentity(
        sub="google-sub-1",
        email="ana@example.com",
        email_verified=True,
        name="Ana",
        picture="https://example.com/ana.png",
    )
    use_case, doubles = _build({"tok-1": identity})

    result = await use_case.execute("tok-1", device_info="pixel-8")

    assert result.user.google_sub == "google-sub-1"
    assert result.user.email == "ana@example.com"
    assert result.user.display_name == "Ana"
    assert result.user.photo_url == "https://example.com/ana.png"
    assert result.user.status is UserStatus.ACTIVE

    audit = doubles["audit"]
    assert isinstance(audit, RecordingAudit)
    [(event, user_id, attrs)] = audit.events
    assert event == "login"
    assert user_id == result.user.id
    assert "email" not in attrs
    assert all("ana@example.com" not in str(v) for v in attrs.values())


@pytest.mark.unit
async def test_usuario_existente_se_encuentra_por_google_sub_y_actualiza_email() -> None:
    hace_un_dia = NOW - timedelta(days=1)
    existing = User(
        id=uuid4(),
        google_sub="google-sub-2",
        email="viejo@example.com",
        display_name="Bea",
        photo_url=None,
        status=UserStatus.ACTIVE,
        consents={},
        created_at=hace_un_dia,
        updated_at=hace_un_dia,
    )
    use_case, doubles = _build(
        {
            "tok-2": GoogleIdentity(
                sub="google-sub-2",
                email="nuevo@example.com",
                email_verified=True,
                name="Bea",
                picture=None,
            )
        }
    )
    users = doubles["users"]
    assert isinstance(users, InMemoryUserRepo)
    await users.add(existing)

    result = await use_case.execute("tok-2", device_info=None)

    assert result.user.id == existing.id
    assert result.user.email == "nuevo@example.com"
    assert result.user.updated_at > existing.updated_at


@pytest.mark.unit
async def test_usuario_existente_sin_cambios_no_actualiza_perfil() -> None:
    hace_un_dia = NOW - timedelta(days=1)
    existing = User(
        id=uuid4(),
        google_sub="google-sub-sin-cambios",
        email="sin-cambios@example.com",
        display_name="Gigi",
        photo_url="https://example.com/gigi.png",
        status=UserStatus.ACTIVE,
        consents={},
        created_at=hace_un_dia,
        updated_at=hace_un_dia,
    )
    use_case, doubles = _build(
        {
            "tok-sin-cambios": GoogleIdentity(
                sub="google-sub-sin-cambios",
                email="sin-cambios@example.com",
                email_verified=True,
                name="Gigi",
                picture="https://example.com/gigi.png",
            )
        }
    )
    users = doubles["users"]
    assert isinstance(users, InMemoryUserRepo)
    await users.add(existing)

    result = await use_case.execute("tok-sin-cambios", device_info=None)

    assert result.user.updated_at == hace_un_dia


@pytest.mark.unit
async def test_email_no_verificado_lanza_y_no_persiste_ni_confirma() -> None:
    use_case, doubles = _build(
        {
            "tok-3": GoogleIdentity(
                sub="google-sub-3",
                email="sin-verificar@example.com",
                email_verified=False,
                name=None,
                picture=None,
            )
        }
    )

    with pytest.raises(EmailNotVerified):
        await use_case.execute("tok-3", device_info=None)

    users = doubles["users"]
    tokens = doubles["tokens"]
    uow = doubles["uow"]
    assert isinstance(users, InMemoryUserRepo)
    assert isinstance(tokens, InMemoryRefreshTokenRepo)
    assert isinstance(uow, NoopUoW)
    assert await users.get_by_google_sub("google-sub-3") is None
    assert uow.commits == 0


@pytest.mark.unit
async def test_verificador_falla_propaga_invalid_google_token() -> None:
    use_case, _doubles = _build({})

    with pytest.raises(InvalidGoogleToken):
        await use_case.execute("tok-desconocido", device_info=None)


@pytest.mark.unit
async def test_refresh_token_se_guarda_solo_como_hash() -> None:
    identity = GoogleIdentity(
        sub="google-sub-4",
        email="cami@example.com",
        email_verified=True,
        name="Cami",
        picture=None,
    )
    use_case, doubles = _build({"tok-4": identity})

    result = await use_case.execute("tok-4", device_info="iphone-15")

    tokens = doubles["tokens"]
    assert isinstance(tokens, InMemoryRefreshTokenRepo)
    stored = await tokens.get_by_hash_for_update(hash_refresh_token(result.refresh_token))
    assert stored is not None
    assert stored.token_hash == hash_refresh_token(result.refresh_token)
    assert stored.token_hash != result.refresh_token
