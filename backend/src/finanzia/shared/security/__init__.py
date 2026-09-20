"""Seguridad compartida: JWT de acceso, hashing y parser de `Authorization: Bearer`."""

from finanzia.shared.errors import UnauthorizedError
from finanzia.shared.security.hashing import sha256_hex
from finanzia.shared.security.jwt import (
    AccessClaims,
    decode_access_token,
    encode_access_token,
)

__all__ = [
    "AccessClaims",
    "bearer_token",
    "decode_access_token",
    "encode_access_token",
    "sha256_hex",
]


def bearer_token(authorization: str | None) -> str:
    """Extrae el token de un header `Authorization: Bearer <token>` estricto.

    Exige esquema `Bearer` (sensible a mayusculas), un unico espacio separador
    y un token no vacio sin espacios internos. Cualquier otra forma lanza
    `UnauthorizedError`.
    """
    if not authorization:
        raise UnauthorizedError

    scheme, sep, token = authorization.partition(" ")
    if not sep or scheme != "Bearer" or not token or " " in token:
        raise UnauthorizedError

    return token
