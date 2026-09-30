"""Tests unitarios de hashing SHA-256 (spec 009 SS2.2)."""

import pytest

from luka.shared.security.hashing import sha256_hex


@pytest.mark.unit
def test_sha256_hex_vector_conocido() -> None:
    assert sha256_hex("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"


@pytest.mark.unit
def test_sha256_hex_es_determinista() -> None:
    assert sha256_hex("hola-mundo") == sha256_hex("hola-mundo")


@pytest.mark.unit
def test_sha256_hex_tiene_64_caracteres_hex_minusculas() -> None:
    digest = sha256_hex("cualquier-valor")

    assert len(digest) == 64
    assert digest == digest.lower()
    assert all(c in "0123456789abcdef" for c in digest)
