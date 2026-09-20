"""Fixtures locales de los tests de integracion de identity."""

import pytest


@pytest.fixture(autouse=True)
def _tablas_limpias(db_clean: None) -> None:
    """Cada test de identity arranca con `users`/`refresh_tokens` vacias."""
    del db_clean
