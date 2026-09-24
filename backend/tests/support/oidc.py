"""Tokens OIDC de prueba para el webhook push (F3.4): firmados con una llave propia.

`GoogleOidcPushVerifier` corre tal cual (firma, `exp`, `aud`, `iss`, email); solo
cambia el transporte que baja los certificados, que aqui sirve el de la llave de
prueba en vez de ir a `googleapis.com`. Nada de esto vive en `src/`.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID
from google.auth import crypt
from google.auth import jwt as google_jwt
from google.auth.transport import Request, Response

from finanzia.modules.ingestion.infrastructure.push_verifier import GoogleOidcPushVerifier

PUSH_AUDIENCE = "finanzia-gmail-push"
PUSH_SERVICE_ACCOUNT = "gmail-push-invoker@finanzia-509500.iam.gserviceaccount.com"
_KEY_ID = "clave-de-prueba"


def _make_key_and_cert() -> tuple[bytes, bytes]:
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "finanzia-test")])
    now = datetime.now(UTC)
    cert = (
        x509.CertificateBuilder()
        .subject_name(name)
        .issuer_name(name)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now - timedelta(days=1))
        .not_valid_after(now + timedelta(days=1))
        .sign(key, hashes.SHA256())
    )
    key_pem = key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    )
    return key_pem, cert.public_bytes(serialization.Encoding.PEM)


_KEY_PEM, _CERT_PEM = _make_key_and_cert()


class _CertsResponse(Response):
    @property
    def status(self) -> int:
        return 200

    @property
    def headers(self) -> dict[str, str]:
        return {"content-type": "application/json"}

    @property
    def data(self) -> bytes:
        return json.dumps({_KEY_ID: _CERT_PEM.decode()}).encode()


class FakeCertsRequest(Request):
    """Transporte de `google.auth` que responde siempre los certificados de prueba."""

    def __call__(self, url: str, method: str = "GET", *args: Any, **kwargs: Any) -> Response:
        del url, method, args, kwargs
        return _CertsResponse()


@dataclass(frozen=True)
class PushClaims:
    """Claims del token; cada test cambia solo lo que quiere romper."""

    aud: str = PUSH_AUDIENCE
    email: str = PUSH_SERVICE_ACCOUNT
    email_verified: bool = True
    iss: str = "https://accounts.google.com"
    expires_in: timedelta = timedelta(minutes=30)


def sign_push_token(claims: PushClaims | None = None) -> str:
    """id_token RS256 como el que Pub/Sub manda en `Authorization: Bearer`."""
    c = claims or PushClaims()
    now = datetime.now(UTC)
    payload = {
        "aud": c.aud,
        "azp": "1234567890",
        "email": c.email,
        "email_verified": c.email_verified,
        "iss": c.iss,
        "sub": "1234567890",
        "iat": int((now - timedelta(minutes=1)).timestamp()),
        "exp": int((now + c.expires_in).timestamp()),
    }
    signer = crypt.RSASigner.from_string(_KEY_PEM, key_id=_KEY_ID)
    return google_jwt.encode(signer, payload).decode()


def build_test_push_verifier() -> GoogleOidcPushVerifier:
    """El verificador real, con el transporte de certificados de prueba."""
    return GoogleOidcPushVerifier(
        audience=PUSH_AUDIENCE,
        service_account=PUSH_SERVICE_ACCOUNT,
        request=FakeCertsRequest(),
    )


__all__ = [
    "PUSH_AUDIENCE",
    "PUSH_SERVICE_ACCOUNT",
    "FakeCertsRequest",
    "PushClaims",
    "build_test_push_verifier",
    "sign_push_token",
]
