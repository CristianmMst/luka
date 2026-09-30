"""Tests unitarios de `AesGcmTokenCipher` (spec 009 §3, F3.3)."""

import os
from uuid import uuid4

import pytest

from luka.modules.ingestion.domain.errors import GmailTokenUndecryptable
from luka.modules.ingestion.infrastructure.token_cipher import AesGcmTokenCipher

pytestmark = pytest.mark.unit

_CIPHER = AesGcmTokenCipher(os.urandom(32))
USER = uuid4()


def test_ida_y_vuelta_con_el_mismo_usuario() -> None:
    blob = _CIPHER.encrypt(USER, "1//refresh")

    assert b"1//refresh" not in blob
    assert _CIPHER.decrypt(USER, blob) == "1//refresh"


def test_descifrar_con_otro_user_id_falla() -> None:
    blob = _CIPHER.encrypt(USER, "1//refresh")

    with pytest.raises(GmailTokenUndecryptable):
        _CIPHER.decrypt(uuid4(), blob)


def test_descifrar_con_otra_llave_falla() -> None:
    blob = _CIPHER.encrypt(USER, "1//refresh")

    with pytest.raises(GmailTokenUndecryptable):
        AesGcmTokenCipher(os.urandom(32)).decrypt(USER, blob)
