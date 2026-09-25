"""Tests unitarios del motor de plantillas contra los fixtures reales de
Bancolombia (spec 006 §4.1, F2.3).

La extraccion (`TestTemplateRegistryBancolombia`) corre contra el
`TemplateRegistry` **realmente cargado** desde
`parsing/config/templates/bancolombia.yaml` (via `load_parsing_config()`), no
contra una copia literal del YAML: asi un cambio de regex en el archivo que
rompa un fixture se detecta aqui (regla de oro, spec 006 §4.1). Los tests de
config invalida (`TestTemplateRegistryConfigErrors`) si usan dicts literales
a proposito: ejercitan validaciones de `TemplateRegistry.from_dicts` que no
tienen forma de disparar con el YAML real (ya valido por definicion).
"""

from datetime import timedelta
from decimal import Decimal

import pytest
from support.email_fixtures import bancolombia_fixtures

from finanzia.modules.parsing.domain.errors import TemplateConfigError, TemplateExtractionInvalid
from finanzia.modules.parsing.domain.excerpt import extract_excerpt
from finanzia.modules.parsing.domain.templates import TemplateRegistry
from finanzia.modules.parsing.infrastructure.config_loader import load_parsing_config

TEMPLATE_ID_BY_FIXTURE = {
    "compra_tdeb.txt": "compra_tdeb",
    "compra_tdeb_2.txt": "compra_tdeb",
    "nomina.txt": "nomina",
    "transferencia_llave.txt": "transferencia_llave",
    "transferencia_llave_wrap.txt": "transferencia_llave",
    "transferencia_llave_recibida_wrap.txt": "transferencia_llave_recibida",
}


@pytest.fixture
def registry() -> TemplateRegistry:
    """El `TemplateRegistry` real, cargado desde el YAML empaquetado."""
    return load_parsing_config().templates


@pytest.mark.unit
class TestTemplateRegistryBancolombia:
    @pytest.mark.parametrize("fixture", bancolombia_fixtures(), ids=lambda f: f.name)
    def test_extrae_lo_esperado_por_fixture(self, registry: TemplateRegistry, fixture) -> None:
        excerpt = extract_excerpt(fixture.body, "Bancolombia:")
        match = registry.match("bancolombia", excerpt)
        assert match is not None, f"{fixture.name}: no matcheo ninguna plantilla"

        parsed = match.to_parsed(fixture.received_at)
        expected = fixture.expected

        assert parsed.amount == Decimal(expected["amount"])
        assert parsed.direction.value == expected["direction"]
        assert parsed.merchant == expected["merchant"]
        assert parsed.last4 == expected.get("last4")
        assert parsed.occurred_at == expected["occurred_at"]
        assert parsed.parsed_by == f"rule:bancolombia:{TEMPLATE_ID_BY_FIXTURE[fixture.name]}:v1"

        if fixture.name == "nomina.txt":
            assert parsed.suggested_category == "nomina"
        else:
            assert parsed.suggested_category is None

    def test_match_con_bank_none_prueba_todos_los_bancos(self, registry: TemplateRegistry) -> None:
        fixture = next(f for f in bancolombia_fixtures() if f.name == "compra_tdeb.txt")
        excerpt = extract_excerpt(fixture.body, "Bancolombia:")
        match = registry.match(None, excerpt)
        assert match is not None
        assert match.bank == "bancolombia"

    def test_extracto_alterado_no_matchea(self, registry: TemplateRegistry) -> None:
        excerpt = "Bancolombia: Compraste en CARBON Y XILVESTRE T con tu T.Deb *1234"
        assert registry.match("bancolombia", excerpt) is None

    def test_fecha_fuera_de_ventana_lanza_extraction_invalid(
        self, registry: TemplateRegistry
    ) -> None:
        fixture = next(f for f in bancolombia_fixtures() if f.name == "compra_tdeb.txt")
        excerpt = extract_excerpt(fixture.body, "Bancolombia:")
        match = registry.match("bancolombia", excerpt)
        assert match is not None
        far_received_at = fixture.received_at + timedelta(days=30)
        with pytest.raises(TemplateExtractionInvalid):
            match.to_parsed(far_received_at)

    def test_bank_config_y_known_banks(self, registry: TemplateRegistry) -> None:
        assert registry.known_banks() == frozenset({"bancolombia"})
        bank_config = registry.bank_config("bancolombia")
        assert bank_config is not None
        assert bank_config.version == 1
        assert len(bank_config.templates) == 4
        assert registry.bank_config("nequi") is None

    def test_config_real_tiene_exactamente_las_4_plantillas_esperadas(
        self, registry: TemplateRegistry
    ) -> None:
        """Guarda que `templates/bancolombia.yaml` siga declarando los 4 template
        ids esperados en version 1 (si alguien borra/renombra uno, este test lo
        detecta sin depender de que un fixture tambien deje de matchear).
        """
        bank_config = registry.bank_config("bancolombia")
        assert bank_config is not None
        assert bank_config.version == 1
        assert {t.id for t in bank_config.templates} == {
            "compra_tdeb",
            "transferencia_llave",
            "transferencia_llave_recibida",
            "nomina",
        }


@pytest.mark.unit
class TestTemplateRegistryConfigErrors:
    """Validaciones de `TemplateRegistry.from_dicts` que no se pueden disparar
    con el YAML real (que ya es valido por definicion): usan dicts literales
    a proposito.
    """

    def test_regex_invalida_en_config_lanza_template_config_error(self) -> None:
        bad_config = {
            "bank": "bancolombia",
            "version": 1,
            "relevant_line_prefix": "Bancolombia:",
            "templates": [
                {
                    "id": "roto",
                    "direction": "debit",
                    "pattern": r"Bancolombia: Compraste \$(?P<amount>[\d.,]+",  # sin cerrar
                    "date_format": "%d/%m/%Y",
                }
            ],
        }
        with pytest.raises(TemplateConfigError):
            TemplateRegistry.from_dicts([bad_config])

    def test_direction_invalida_en_config_lanza_template_config_error(self) -> None:
        bad_config = {
            "bank": "bancolombia",
            "version": 1,
            "relevant_line_prefix": "Bancolombia:",
            "templates": [
                {
                    "id": "roto",
                    "direction": "sideways",
                    "pattern": r"Bancolombia: (?P<amount>\d+) (?P<date>\S+) (?P<time>\S+)",
                    "date_format": "%d/%m/%Y",
                }
            ],
        }
        with pytest.raises(TemplateConfigError):
            TemplateRegistry.from_dicts([bad_config])

    def test_plantilla_sin_campo_obligatorio_lanza_template_config_error(self) -> None:
        bad_config = {
            "bank": "bancolombia",
            "version": 1,
            "templates": [{"id": "roto", "direction": "debit", "pattern": r"x"}],
        }
        with pytest.raises(TemplateConfigError):
            TemplateRegistry.from_dicts([bad_config])

    def test_plantilla_sin_grupos_requeridos_lanza_template_config_error(self) -> None:
        bad_config = {
            "bank": "bancolombia",
            "version": 1,
            "templates": [
                {
                    "id": "roto",
                    "direction": "debit",
                    "pattern": r"Bancolombia: Compraste \$(?P<amount>[\d.,]+)",
                    "date_format": "%d/%m/%Y",
                }
            ],
        }
        with pytest.raises(TemplateConfigError):
            TemplateRegistry.from_dicts([bad_config])

    def test_config_sin_campo_obligatorio_de_banco_lanza_template_config_error(self) -> None:
        with pytest.raises(TemplateConfigError):
            TemplateRegistry.from_dicts([{"bank": "bancolombia", "version": 1}])
