"""Fixtures locales de los tests de integracion de parsing."""

import pytest


@pytest.fixture(autouse=True)
def _tablas_y_redis_limpias(db_clean: None, redis_clean: None) -> None:
    """Cada test de parsing arranca con tablas de usuario y Redis (db 1) vacias."""
    del db_clean, redis_clean
