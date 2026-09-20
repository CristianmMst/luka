"""Fixtures locales de los tests de integracion de ledger."""

import pytest


@pytest.fixture(autouse=True)
def _tablas_limpias(db_clean: None) -> None:
    """Cada test de ledger arranca con las tablas de usuario vacias.

    `categories` nunca se limpia por completo (ver `conftest.py` raiz): el seed
    de las 24 categorias del sistema persiste entre tests.
    """
    del db_clean
