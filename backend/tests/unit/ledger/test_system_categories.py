"""Tests unitarios del catalogo de categorias del sistema (spec 004 SS2.8.1, review final)."""

import uuid

import pytest

from finanzia.modules.ledger.domain.system_categories import (
    SYSTEM_CATEGORIES,
    system_category_by_slug,
    system_category_id,
)

_EXPECTED_COUNT = 24


@pytest.mark.unit
def test_hay_veinticuatro_categorias_del_sistema() -> None:
    assert len(SYSTEM_CATEGORIES) == _EXPECTED_COUNT


@pytest.mark.unit
def test_system_category_by_slug_con_slug_conocido_devuelve_la_categoria() -> None:
    category = system_category_by_slug("sin_categoria")

    assert category is not None
    assert category.slug == "sin_categoria"
    assert category.id == system_category_id("sin_categoria")


@pytest.mark.unit
def test_system_category_by_slug_con_slug_desconocido_devuelve_none() -> None:
    assert system_category_by_slug("no-existe-este-slug") is None


@pytest.mark.unit
def test_todos_los_ids_son_unicos() -> None:
    ids = [category.id for category in SYSTEM_CATEGORIES]
    assert len(ids) == len(set(ids))


@pytest.mark.unit
def test_todos_los_ids_son_uuid5_deterministas() -> None:
    for category in SYSTEM_CATEGORIES:
        assert isinstance(category.id, uuid.UUID)
        assert category.id.version == 5
        assert category.id == system_category_id(category.slug)
