"""Transferencias propias por nombre del titular (spec 004 §4.1)."""

import pytest

from finanzia.modules.ledger.domain.self_transfer import is_same_person, normalize_person_name


@pytest.mark.unit
class TestNormalizePersonName:
    def test_sin_tildes_mayusculas_y_espacios_colapsados(self) -> None:
        assert normalize_person_name("  María   José  Pérez ") == ("MARIA", "JOSE", "PEREZ")

    def test_quita_puntuacion(self) -> None:
        assert normalize_person_name("Ana-María P., Gómez.") == ("ANA", "MARIA", "P", "GOMEZ")

    def test_vacio(self) -> None:
        assert normalize_person_name("  ") == ()


@pytest.mark.unit
class TestIsSamePerson:
    @pytest.mark.parametrize(
        ("counterparty", "owner"),
        [
            # Bancolombia recorta el nombre; Nequi lo trae completo.
            ("CRISTIAN MORA", "Cristian Mora"),
            ("Cristian Steve Mora Moreno", "Cristian Mora"),
            ("CRISTIAN MORA", "Cristian Steve Mora Moreno"),
            ("María José", "MARIA JOSE PEREZ"),
            ("ANA PEREZ", "Ana María Pérez Gómez"),
        ],
    )
    def test_mismo_titular(self, counterparty: str, owner: str) -> None:
        assert is_same_person(counterparty, owner)

    @pytest.mark.parametrize(
        ("counterparty", "owner"),
        [
            # Otra persona.
            ("JUAN SOSA", "Cristian Mora"),
            ("Alejandro Herrera Feria", "Cristian Mora"),
            # Una sola palabra en comun no alcanza (homonimos de nombre).
            ("CRISTIAN", "Cristian Mora"),
            ("CRISTIAN LOPEZ", "Cristian Mora"),
            # Palabras de mas en el corto que no estan en el largo.
            ("CRISTIAN MORA RUIZ", "Cristian Steve Mora Moreno"),
        ],
    )
    def test_otra_persona(self, counterparty: str, owner: str) -> None:
        assert not is_same_person(counterparty, owner)

    @pytest.mark.parametrize(
        ("counterparty", "owner"),
        [(None, "Cristian Mora"), ("CRISTIAN MORA", None), ("", "Cristian Mora"), ("", "")],
    )
    def test_sin_nombre_nunca_coincide(self, counterparty: str | None, owner: str | None) -> None:
        assert not is_same_person(counterparty, owner)
