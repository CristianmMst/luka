"""Smoke tests: shared y los 6 modulos se pueden importar sin errores."""

import importlib

import pytest

MODULOS = [
    "finanzia.shared",
    "finanzia.modules.identity",
    "finanzia.modules.ingestion",
    "finanzia.modules.parsing",
    "finanzia.modules.ledger",
    "finanzia.modules.fiscal",
    "finanzia.modules.insights",
]


@pytest.mark.unit
@pytest.mark.parametrize("nombre_modulo", MODULOS)
def test_importa_modulo(nombre_modulo: str) -> None:
    importlib.import_module(nombre_modulo)
