"""Tests unitarios del motor de plantillas contra los fixtures reales de
Bancolombia (spec 006 §4.1, F2.3). El contenido de `BANCOLOMBIA_CONFIG` debe
coincidir con `parsing/config/templates/bancolombia.yaml` (verificado tambien
por `test_config_loader.py`, que carga el YAML real).
"""

from datetime import timedelta
from decimal import Decimal

import pytest
from support.email_fixtures import bancolombia_fixtures

from finanzia.modules.parsing.domain.errors import TemplateConfigError, TemplateExtractionInvalid
from finanzia.modules.parsing.domain.excerpt import extract_excerpt
from finanzia.modules.parsing.domain.templates import TemplateRegistry

BANCOLOMBIA_CONFIG = {
    "bank": "bancolombia",
    "version": 1,
    "relevant_line_prefix": "Bancolombia:",
    "templates": [
        {
            "id": "compra_tdeb",
            "direction": "debit",
            "pattern": (
                r"Bancolombia: Compraste \$(?P<amount>[\d.,]+) en (?P<merchant>.+?) "
                r"con tu T\.Deb \*(?P<last4>\d{4}), el (?P<date>\d{2}/\d{2}/\d{4}) "
                r"a las (?P<time>\d{2}:\d{2})"
            ),
            "date_format": "%d/%m/%Y",
        },
        {
            "id": "transferencia_llave",
            "direction": "debit",
            "pattern": (
                r"Bancolombia: (?:(?P<holder>[^,]{1,80}), )?transferiste "
                r"\$(?P<amount>[\d.,]+) a la llave (?P<key>\S+) desde tu cuenta "
                r"\*(?P<last4>\d{4}) a (?P<merchant>.+?) el (?P<date>\d{2}/\d{2}/\d{2}) "
                r"a las (?P<time>\d{2}:\d{2})"
            ),
            "date_format": "%d/%m/%y",
        },
        {
            "id": "nomina",
            "direction": "credit",
            "pattern": (
                r"Bancolombia: Recibiste un pago de Nomina de (?P<merchant>.+?) "
                r"por \$(?P<amount>[\d.,]+) en tu cuenta de (?P<account_kind>Ahorros|Corriente) "
                r"el (?P<date>\d{2}/\d{2}/\d{4}) a las (?P<time>\d{2}:\d{2})"
            ),
            "date_format": "%d/%m/%Y",
            "suggested_category": "nomina",
        },
    ],
}

TEMPLATE_ID_BY_FIXTURE = {
    "compra_tdeb.txt": "compra_tdeb",
    "compra_tdeb_2.txt": "compra_tdeb",
    "nomina.txt": "nomina",
    "transferencia_llave.txt": "transferencia_llave",
}


@pytest.fixture
def registry() -> TemplateRegistry:
    return TemplateRegistry.from_dicts([BANCOLOMBIA_CONFIG])


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

    def test_bank_config_y_known_banks(self, registry: TemplateRegistry) -> None:
        assert registry.known_banks() == frozenset({"bancolombia"})
        bank_config = registry.bank_config("bancolombia")
        assert bank_config is not None
        assert bank_config.version == 1
        assert len(bank_config.templates) == 3
        assert registry.bank_config("nequi") is None
