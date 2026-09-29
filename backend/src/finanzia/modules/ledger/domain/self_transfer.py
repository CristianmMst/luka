"""Transferencias propias por nombre del titular (spec 004 §4.1). Puro.

Un envio o recibo entre personas (plantilla con `counterparty: true`) cuya
contraparte es el propio usuario es plata que pasa entre sus cuentas
(Bancolombia -> Nequi, Nubank -> Nequi): no es gasto ni ingreso, aunque el
otro lado nunca llegue por correo.
"""

from __future__ import annotations

import re
import unicodedata

_NON_LETTER_RE = re.compile(r"[^A-Z\s]")
_MIN_SHARED_WORDS = 2


def normalize_person_name(name: str) -> tuple[str, ...]:
    """Palabras del nombre sin tildes, en mayusculas y sin puntuacion."""
    decomposed = unicodedata.normalize("NFKD", name)
    ascii_only = "".join(c for c in decomposed if not unicodedata.combining(c))
    return tuple(_NON_LETTER_RE.sub(" ", ascii_only.upper()).split())


def is_same_person(counterparty: str | None, owner: str | None) -> bool:
    """`True` si los dos nombres son de la misma persona.

    Los bancos recortan el nombre de formas distintas ("CRISTIAN MORA" frente a
    "Cristian Steve Mora Moreno"), asi que basta con que todas las palabras del
    nombre mas corto esten en el mas largo, con al menos 2 en comun: un solo
    nombre de pila ("CRISTIAN") no alcanza.
    """
    if not counterparty or not owner:
        return False
    a = set(normalize_person_name(counterparty))
    b = set(normalize_person_name(owner))
    shorter, longer = (a, b) if len(a) <= len(b) else (b, a)
    return len(shorter) >= _MIN_SHARED_WORDS and shorter <= longer


__all__ = ["is_same_person", "normalize_person_name"]
