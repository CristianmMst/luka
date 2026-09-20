"""Normalizacion de comercios y resolucion de reglas de usuario (spec 006 SS4.3)."""

from __future__ import annotations

import re
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Iterable

    from finanzia.modules.ledger.domain.entities import MerchantRule

_TRAILING_CODE = re.compile(r"^[A-Z]*\d{3,}$")


def normalize_merchant(raw: str | None) -> str:
    """Normaliza el nombre crudo de un comercio (spec 006 SS4.3).

    Uppercase, corta en el primer `*` (se queda con la parte izquierda), quita sufijos
    de codigo de pasarela al final (numericos o `LETRAS999`, repitiendo mientras el
    ultimo token coincida) y colapsa espacios.
    """
    if raw is None or not raw.strip():
        return ""
    value = raw.upper().split("*", 1)[0]
    tokens = value.split()
    while tokens and _TRAILING_CODE.match(tokens[-1]):
        tokens.pop()
    return " ".join(tokens)


def match_rule(normalized: str, rules: Iterable[MerchantRule]) -> MerchantRule | None:
    """Resuelve la regla aplicable: exacta primero, si no la de prefijo mas largo."""
    best: MerchantRule | None = None
    for rule in rules:
        if rule.merchant_pattern == normalized:
            return rule
        if normalized.startswith(rule.merchant_pattern) and (
            best is None or len(rule.merchant_pattern) > len(best.merchant_pattern)
        ):
            best = rule
    return best
