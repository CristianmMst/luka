"""Adapter AES-256-GCM de `TokenCipherPort` (spec 009 §3, F3.3).

Cada refresh token se cifra con `str(user_id)` como datos asociados (AAD): un
blob copiado a la fila de otro usuario no descifra. La llave nunca sale de aqui.
"""

import base64
from uuid import UUID

from luka.modules.ingestion.domain.errors import GmailTokenUndecryptable
from luka.shared.crypto.aesgcm import DecryptionError, decrypt, encrypt
from luka.shared.settings import Settings


class AesGcmTokenCipher:
    """`TokenCipherPort` sobre `shared.crypto.aesgcm` con una llave de 32 bytes."""

    def __init__(self, key: bytes) -> None:
        self._key = key

    @classmethod
    def from_settings(cls, settings: Settings) -> "AesGcmTokenCipher":
        """Llave desde `LUKA_GMAIL_TOKEN_KEY` (base64; `Settings` ya valido los 32 B)."""
        return cls(base64.b64decode(settings.gmail_token_key.get_secret_value()))

    def encrypt(self, user_id: UUID, plaintext: str) -> bytes:
        return encrypt(self._key, plaintext.encode(), associated_data=_aad(user_id))

    def decrypt(self, user_id: UUID, blob: bytes) -> str:
        try:
            return decrypt(self._key, blob, associated_data=_aad(user_id)).decode()
        except (DecryptionError, UnicodeDecodeError) as exc:
            raise GmailTokenUndecryptable from exc


def _aad(user_id: UUID) -> bytes:
    return str(user_id).encode()


__all__ = ["AesGcmTokenCipher"]
