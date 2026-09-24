"""Cifrado en reposo de datos sensibles con AES-256-GCM (spec 009 §3).

Usado por `ingestion` para cifrar `gmail_connections.refresh_token_enc` (F3.2).
El blob guardado en DB es `nonce (12 bytes) || ciphertext+tag`: el nonce viaja
junto al ciphertext (no es secreto) y GCM ya incluye el tag de autenticacion al
final del ciphertext que produce `cryptography`.
"""

import os

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

_NONCE_LENGTH_BYTES = 12


class DecryptionError(Exception):
    """La autenticacion del blob cifrado fallo: llave incorrecta o dato alterado."""


def encrypt(key: bytes, plaintext: bytes) -> bytes:
    """Cifra `plaintext` con AES-256-GCM bajo `key` (32 bytes).

    Genera un nonce aleatorio de 12 bytes distinto en cada llamada y lo antepone
    al ciphertext devuelto: `nonce || ciphertext_con_tag`.
    """
    nonce = os.urandom(_NONCE_LENGTH_BYTES)
    ciphertext = AESGCM(key).encrypt(nonce, plaintext, None)
    return nonce + ciphertext


def decrypt(key: bytes, blob: bytes) -> bytes:
    """Descifra un `blob` producido por `encrypt` bajo la misma `key`.

    Lanza `DecryptionError` si la autenticacion falla (llave incorrecta o
    ciphertext/tag alterado); nunca deja pasar un dato manipulado en silencio.
    """
    nonce, ciphertext = blob[:_NONCE_LENGTH_BYTES], blob[_NONCE_LENGTH_BYTES:]
    try:
        return AESGCM(key).decrypt(nonce, ciphertext, None)
    except InvalidTag as exc:
        msg = "no se pudo descifrar: llave incorrecta o dato alterado"
        raise DecryptionError(msg) from exc


__all__ = ["DecryptionError", "decrypt", "encrypt"]
