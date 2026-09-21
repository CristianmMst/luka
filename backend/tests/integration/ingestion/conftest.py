"""Fixtures locales de los tests de integracion de ingestion."""

import pytest


@pytest.fixture(autouse=True)
def _tablas_limpias(db_clean: None) -> None:
    """Cada test de ingestion arranca con las tablas de usuario vacias."""
    del db_clean
