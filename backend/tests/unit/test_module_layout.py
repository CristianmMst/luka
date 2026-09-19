"""Verifica que cada modulo tenga la estructura hexagonal esperada (spec 003 S2.2)."""

from pathlib import Path

import pytest

MODULOS = ["identity", "ingestion", "parsing", "ledger", "fiscal", "insights"]

ARCHIVOS_ESPERADOS = [
    "__init__.py",
    "domain/__init__.py",
    "application/__init__.py",
    "application/ports.py",
    "infrastructure/__init__.py",
    "infrastructure/api/__init__.py",
    "events.py",
    "public.py",
]

RAIZ_MODULOS = Path(__file__).resolve().parents[2] / "src" / "finanzia" / "modules"


@pytest.mark.unit
@pytest.mark.parametrize("nombre_modulo", MODULOS)
def test_modulo_tiene_estructura_hexagonal(nombre_modulo: str) -> None:
    directorio_modulo = RAIZ_MODULOS / nombre_modulo
    faltantes = [
        ruta_relativa
        for ruta_relativa in ARCHIVOS_ESPERADOS
        if not (directorio_modulo / ruta_relativa).is_file()
    ]
    assert not faltantes, f"faltan en {nombre_modulo}: {faltantes}"
