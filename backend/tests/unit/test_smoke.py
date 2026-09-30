"""Smoke tests: shared y los 6 modulos se pueden importar sin errores."""

import importlib

import pytest

MODULOS = [
    "luka.shared",
    "luka.modules.identity",
    "luka.modules.ingestion",
    "luka.modules.parsing",
    "luka.modules.ledger",
    "luka.modules.fiscal",
    "luka.modules.insights",
]


@pytest.mark.unit
@pytest.mark.parametrize("nombre_modulo", MODULOS)
def test_importa_modulo(nombre_modulo: str) -> None:
    importlib.import_module(nombre_modulo)
