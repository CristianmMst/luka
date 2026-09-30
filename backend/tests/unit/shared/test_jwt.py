"""Tests unitarios de JWT de acceso HS256 (spec 009 SS2.2)."""

import base64
import json
import uuid
from datetime import UTC, datetime, timedelta

import jwt as pyjwt
import pytest

from luka.shared.errors import TokenExpiredError, UnauthorizedError
from luka.shared.security.jwt import (
    AccessClaims,
    decode_access_token,
    encode_access_token,
)

SECRET = "un-secreto-de-pruebas-con-longitud-suficiente-32b"
OTHER_SECRET = "otro-secreto-de-pruebas-con-longitud-suficiente"
HS512_SECRET = "un-secreto-de-pruebas-con-longitud-suficiente-para-hs512-64bytes"
TTL = timedelta(minutes=15)


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


@pytest.mark.unit
def test_roundtrip_devuelve_los_claims_esperados() -> None:
    user_id = uuid.uuid4()
    jti = uuid.uuid4()
    now = datetime.now(UTC)

    token = encode_access_token(user_id=user_id, now=now, ttl=TTL, secret=SECRET, jti=jti)
    claims = decode_access_token(token, SECRET)

    assert isinstance(claims, AccessClaims)
    assert claims.sub == user_id
    assert claims.jti == jti
    assert claims.exp == datetime.fromtimestamp(int((now + TTL).timestamp()), tz=UTC)


@pytest.mark.unit
def test_token_expirado_lanza_token_expired_error() -> None:
    user_id = uuid.uuid4()
    now = datetime.now(UTC) - timedelta(minutes=16)

    token = encode_access_token(user_id=user_id, now=now, ttl=TTL, secret=SECRET)

    with pytest.raises(TokenExpiredError):
        decode_access_token(token, SECRET)


@pytest.mark.unit
def test_firmado_con_otro_secreto_lanza_unauthorized_error() -> None:
    user_id = uuid.uuid4()
    now = datetime.now(UTC)

    token = encode_access_token(user_id=user_id, now=now, ttl=TTL, secret=SECRET)

    with pytest.raises(UnauthorizedError):
        decode_access_token(token, OTHER_SECRET)


@pytest.mark.unit
def test_token_alg_none_lanza_unauthorized_error() -> None:
    user_id = uuid.uuid4()
    now = datetime.now(UTC)
    payload = {
        "sub": str(user_id),
        "iat": int(now.timestamp()),
        "exp": int((now + TTL).timestamp()),
        "jti": str(uuid.uuid4()),
    }
    header = _b64url(json.dumps({"alg": "none", "typ": "JWT"}).encode("utf-8"))
    body = _b64url(json.dumps(payload).encode("utf-8"))
    token = f"{header}.{body}."

    with pytest.raises(UnauthorizedError):
        decode_access_token(token, SECRET)


@pytest.mark.unit
def test_token_hs512_lanza_unauthorized_error() -> None:
    user_id = uuid.uuid4()
    now = datetime.now(UTC)
    payload = {
        "sub": str(user_id),
        "iat": int(now.timestamp()),
        "exp": int((now + TTL).timestamp()),
        "jti": str(uuid.uuid4()),
    }
    token = pyjwt.encode(payload, HS512_SECRET, algorithm="HS512")

    with pytest.raises(UnauthorizedError):
        decode_access_token(token, HS512_SECRET)


@pytest.mark.unit
def test_token_sin_jti_lanza_unauthorized_error() -> None:
    user_id = uuid.uuid4()
    now = datetime.now(UTC)
    payload = {
        "sub": str(user_id),
        "iat": int(now.timestamp()),
        "exp": int((now + TTL).timestamp()),
    }
    token = pyjwt.encode(payload, SECRET, algorithm="HS256")

    with pytest.raises(UnauthorizedError):
        decode_access_token(token, SECRET)


@pytest.mark.unit
def test_sub_no_uuid_lanza_unauthorized_error() -> None:
    now = datetime.now(UTC)
    payload = {
        "sub": "no-es-un-uuid",
        "iat": int(now.timestamp()),
        "exp": int((now + TTL).timestamp()),
        "jti": str(uuid.uuid4()),
    }
    token = pyjwt.encode(payload, SECRET, algorithm="HS256")

    with pytest.raises(UnauthorizedError):
        decode_access_token(token, SECRET)


@pytest.mark.unit
def test_payload_no_contiene_pii() -> None:
    user_id = uuid.uuid4()
    now = datetime.now(UTC)

    token = encode_access_token(user_id=user_id, now=now, ttl=TTL, secret=SECRET)
    decoded = pyjwt.decode(token, options={"verify_signature": False})

    assert set(decoded.keys()) == {"sub", "iat", "exp", "jti"}
    assert "email" not in decoded
    assert "name" not in decoded


@pytest.mark.unit
def test_token_con_texto_arbitrario_lanza_unauthorized_error() -> None:
    with pytest.raises(UnauthorizedError):
        decode_access_token("not-a-jwt", SECRET)


@pytest.mark.unit
def test_now_naive_lanza_value_error() -> None:
    user_id = uuid.uuid4()
    now_naive = datetime.now()

    with pytest.raises(ValueError, match="aware"):
        encode_access_token(user_id=user_id, now=now_naive, ttl=TTL, secret=SECRET)
