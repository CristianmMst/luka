"""Tests unitarios de la logica pura de sesiones (spec 009 SS2.2, AC-1.4)."""

from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest

from luka.modules.identity.domain.entities import RefreshToken
from luka.modules.identity.domain.sessions import (
    RefreshDecision,
    evaluate_refresh,
    hash_refresh_token,
    new_family,
    rotate,
)

NOW = datetime(2024, 1, 1, 12, 0, 0, tzinfo=UTC)


def _token(
    *,
    revoked_at: datetime | None = None,
    expires_at: datetime = NOW + timedelta(days=1),
    family_id: UUID | None = None,
    user_id: UUID | None = None,
    device_info: str | None = "pixel-8",
) -> RefreshToken:
    return RefreshToken(
        id=uuid4(),
        user_id=user_id or uuid4(),
        token_hash=hash_refresh_token("raw-token"),
        family_id=family_id or uuid4(),
        expires_at=expires_at,
        revoked_at=revoked_at,
        device_info=device_info,
        created_at=NOW - timedelta(days=1),
    )


@pytest.mark.unit
class TestEvaluateRefresh:
    def test_token_ausente_es_unknown(self) -> None:
        assert evaluate_refresh(None, NOW) is RefreshDecision.UNKNOWN

    def test_token_revocado_es_reused(self) -> None:
        token = _token(revoked_at=NOW - timedelta(minutes=1))
        assert evaluate_refresh(token, NOW) is RefreshDecision.REUSED

    def test_token_vencido_es_expired(self) -> None:
        token = _token(expires_at=NOW)
        assert evaluate_refresh(token, NOW) is RefreshDecision.EXPIRED

    def test_token_vigente_es_ok(self) -> None:
        token = _token(expires_at=NOW + timedelta(days=1))
        assert evaluate_refresh(token, NOW) is RefreshDecision.OK

    def test_revocado_y_vencido_prioriza_reused(self) -> None:
        token = _token(revoked_at=NOW - timedelta(minutes=1), expires_at=NOW)
        assert evaluate_refresh(token, NOW) is RefreshDecision.REUSED

    def test_now_naive_lanza_value_error(self) -> None:
        naive_now = datetime(2024, 1, 1, 12, 0, 0)
        with pytest.raises(ValueError, match="aware"):
            evaluate_refresh(None, naive_now)


@pytest.mark.unit
class TestRotate:
    def test_conserva_family_user_y_device(self) -> None:
        token = _token()
        ttl = timedelta(days=60)
        _old, new_token = rotate(
            token, now=NOW, new_id=uuid4(), new_hash=hash_refresh_token("nuevo"), ttl=ttl
        )
        assert new_token.family_id == token.family_id
        assert new_token.user_id == token.user_id
        assert new_token.device_info == token.device_info

    def test_revoca_el_anterior_en_now(self) -> None:
        token = _token()
        old_revoked, _new = rotate(
            token,
            now=NOW,
            new_id=uuid4(),
            new_hash=hash_refresh_token("nuevo"),
            ttl=timedelta(days=60),
        )
        assert old_revoked.id == token.id
        assert old_revoked.revoked_at == NOW

    def test_nuevo_expires_at_es_now_mas_ttl(self) -> None:
        token = _token()
        ttl = timedelta(days=60)
        _old, new_token = rotate(
            token, now=NOW, new_id=uuid4(), new_hash=hash_refresh_token("nuevo"), ttl=ttl
        )
        assert new_token.expires_at == NOW + ttl

    def test_nuevo_token_no_esta_revocado(self) -> None:
        token = _token()
        _old, new_token = rotate(
            token,
            now=NOW,
            new_id=uuid4(),
            new_hash=hash_refresh_token("nuevo"),
            ttl=timedelta(days=60),
        )
        assert new_token.revoked_at is None

    def test_now_naive_lanza_value_error(self) -> None:
        token = _token()
        naive_now = datetime(2024, 1, 1, 12, 0, 0)
        with pytest.raises(ValueError, match="aware"):
            rotate(
                token,
                now=naive_now,
                new_id=uuid4(),
                new_hash="hash",
                ttl=timedelta(days=60),
            )


@pytest.mark.unit
class TestNewFamily:
    def test_crea_token_con_expires_at_now_mas_ttl(self) -> None:
        user_id = uuid4()
        family_id = uuid4()
        token = new_family(
            id=uuid4(),
            user_id=user_id,
            token_hash=hash_refresh_token("raw"),
            family_id=family_id,
            now=NOW,
            ttl=timedelta(days=60),
            device_info="pixel-8",
        )
        assert token.user_id == user_id
        assert token.family_id == family_id
        assert token.expires_at == NOW + timedelta(days=60)
        assert token.revoked_at is None
        assert token.created_at == NOW


@pytest.mark.unit
class TestHashRefreshToken:
    def test_es_deterministico(self) -> None:
        assert hash_refresh_token("mismo-valor") == hash_refresh_token("mismo-valor")

    def test_devuelve_64_hex_minusculas(self) -> None:
        digest = hash_refresh_token("cualquier-valor")
        assert len(digest) == 64
        assert digest == digest.lower()
        assert all(c in "0123456789abcdef" for c in digest)

    def test_difiere_por_entrada(self) -> None:
        assert hash_refresh_token("a") != hash_refresh_token("b")
