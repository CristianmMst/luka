"""Cifrado compartido (spec 009 §3)."""

from finanzia.shared.crypto.aesgcm import DecryptionError, decrypt, encrypt

__all__ = ["DecryptionError", "decrypt", "encrypt"]
