"""Tests unitarios de `shared/crypto/aesgcm.py` (spec 009 §3, F3.2)."""

import os

import pytest

from finanzia.shared.crypto.aesgcm import DecryptionError, decrypt, encrypt

_KEY = os.urandom(32)
_OTRA_KEY = os.urandom(32)


@pytest.mark.unit
def test_ida_y_vuelta_recupera_el_texto_original() -> None:
    plaintext = b"refresh-token-de-prueba"

    blob = encrypt(_KEY, plaintext)

    assert decrypt(_KEY, blob) == plaintext


@pytest.mark.unit
def test_nonce_es_distinto_en_cada_llamada() -> None:
    plaintext = b"mismo-texto-plano"

    blob_1 = encrypt(_KEY, plaintext)
    blob_2 = encrypt(_KEY, plaintext)

    assert blob_1[:12] != blob_2[:12]
    # Ciphertexts distintos aunque el texto plano sea el mismo (nonce distinto).
    assert blob_1 != blob_2


@pytest.mark.unit
def test_alteracion_del_ciphertext_lanza_decryption_error() -> None:
    blob = bytearray(encrypt(_KEY, b"dato-sensible"))
    blob[-1] ^= 0xFF  # altera el ultimo byte (dentro del tag de autenticacion)

    with pytest.raises(DecryptionError):
        decrypt(_KEY, bytes(blob))


@pytest.mark.unit
def test_llave_incorrecta_lanza_decryption_error() -> None:
    blob = encrypt(_KEY, b"dato-sensible")

    with pytest.raises(DecryptionError):
        decrypt(_OTRA_KEY, blob)
