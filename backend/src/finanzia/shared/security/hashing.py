"""Hashing generico basado en SHA-256 (spec 009 SS2.2)."""

import hashlib


def sha256_hex(value: str) -> str:
    """Devuelve el digest SHA-256 de `value` (UTF-8) como hex minusculas de 64 caracteres."""
    return hashlib.sha256(value.encode("utf-8")).hexdigest()
