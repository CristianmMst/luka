"""Test unitario de `NAMING_CONVENTION` sobre una tabla de prueba (spec 003 F0.4)."""

import pytest
from sqlalchemy import (
    CheckConstraint,
    Column,
    ForeignKey,
    ForeignKeyConstraint,
    Index,
    Integer,
    MetaData,
    String,
    Table,
    UniqueConstraint,
)

from luka.shared.db.base import NAMING_CONVENTION


@pytest.mark.unit
def test_convencion_de_nombres_se_aplica_a_constraints_e_indices() -> None:
    metadata = MetaData(naming_convention=NAMING_CONVENTION)

    padres = Table(
        "padres",
        metadata,
        Column("id", Integer, primary_key=True),
    )

    hijos = Table(
        "hijos",
        metadata,
        Column("id", Integer, primary_key=True),
        Column("padre_id", Integer, ForeignKey("padres.id")),
        Column("codigo", String, index=True),
        Column("email", String),
        Column("edad", Integer),
        Column("user_id", Integer),
        Column("name", String),
        Column("created_at", String),
        UniqueConstraint("email"),
        UniqueConstraint("user_id", "name"),
        CheckConstraint("edad >= 0", name="edad_no_negativa"),
        Index(None, "user_id", "created_at"),
    )

    assert padres.primary_key.name == "pk_padres"
    assert hijos.primary_key.name == "pk_hijos"

    [fk] = [c for c in hijos.constraints if isinstance(c, ForeignKeyConstraint)]
    assert fk.name == "fk_hijos_padre_id_padres"

    unique_constraints = {
        frozenset(col.name for col in c.columns): c.name
        for c in hijos.constraints
        if isinstance(c, UniqueConstraint)
    }
    assert unique_constraints[frozenset({"email"})] == "uq_hijos_email"
    assert unique_constraints[frozenset({"user_id", "name"})] == "uq_hijos_user_id_name"

    [ck] = [c for c in hijos.constraints if isinstance(c, CheckConstraint)]
    assert ck.name == "ck_hijos_edad_no_negativa"

    indexes = {frozenset(col.name for col in ix.columns): ix.name for ix in hijos.indexes}
    assert indexes[frozenset({"codigo"})] == "ix_hijos_codigo"
    assert indexes[frozenset({"user_id", "created_at"})] == "ix_hijos_user_id_created_at"
