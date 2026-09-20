"""Test unitario de `NAMING_CONVENTION` sobre una tabla de prueba (spec 003 F0.4)."""

import pytest
from sqlalchemy import (
    CheckConstraint,
    Column,
    ForeignKey,
    ForeignKeyConstraint,
    Integer,
    MetaData,
    String,
    Table,
    UniqueConstraint,
)

from finanzia.shared.db.base import NAMING_CONVENTION


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
        UniqueConstraint("email"),
        CheckConstraint("edad >= 0", name="edad_no_negativa"),
    )

    assert padres.primary_key.name == "pk_padres"
    assert hijos.primary_key.name == "pk_hijos"

    [fk] = [c for c in hijos.constraints if isinstance(c, ForeignKeyConstraint)]
    assert fk.name == "fk_hijos_padre_id_padres"

    [uq] = [c for c in hijos.constraints if isinstance(c, UniqueConstraint)]
    assert uq.name == "uq_hijos_email"

    [ck] = [c for c in hijos.constraints if isinstance(c, CheckConstraint)]
    assert ck.name == "ck_hijos_edad_no_negativa"

    [ix] = list(hijos.indexes)
    assert ix.name == "ix_hijos_codigo"
