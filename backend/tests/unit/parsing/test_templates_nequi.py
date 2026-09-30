"""Tests unitarios de las plantillas de Nequi contra fixtures reales
anonimizados (spec 006 §4.1, F2.7), con el `TemplateRegistry` realmente
cargado desde `parsing/config/templates/nequi.yaml`.
"""

from datetime import timedelta
from decimal import Decimal

import pytest
from support.email_fixtures import nequi_fixtures

from luka.modules.parsing.domain.errors import TemplateExtractionInvalid
from luka.modules.parsing.domain.excerpt import extract_excerpt
from luka.modules.parsing.domain.templates import TemplateRegistry
from luka.modules.parsing.infrastructure.config_loader import load_parsing_config

TEMPLATE_ID_BY_FIXTURE = {"breb_recibida.txt": "breb_recibida"}


@pytest.fixture
def registry() -> TemplateRegistry:
    return load_parsing_config().templates


def _excerpt(registry: TemplateRegistry, body: str) -> str:
    config = registry.bank_config("nequi")
    assert config is not None
    return extract_excerpt(body, config.relevant_line_prefix)


@pytest.mark.unit
class TestTemplateRegistryNequi:
    @pytest.mark.parametrize("fixture", nequi_fixtures(), ids=lambda f: f.name)
    def test_extrae_lo_esperado_por_fixture(self, registry: TemplateRegistry, fixture) -> None:
        match = registry.match("nequi", _excerpt(registry, fixture.body))
        assert match is not None, f"{fixture.name}: no matcheo ninguna plantilla"

        parsed = match.to_parsed(fixture.received_at)
        expected = fixture.expected

        assert parsed.bank == "nequi"
        assert parsed.amount == Decimal(expected["amount"])
        assert parsed.direction.value == expected["direction"]
        assert parsed.merchant == expected["merchant"]
        assert parsed.last4 == expected.get("last4")
        assert parsed.occurred_at == expected["occurred_at"]
        assert parsed.parsed_by == f"rule:nequi:{TEMPLATE_ID_BY_FIXTURE[fixture.name]}:v1"
        assert parsed.merchant_is_person is True

    def test_parsed_by_de_las_plantillas_entre_personas(self, registry: TemplateRegistry) -> None:
        assert registry.person_parsed_by() == {
            "rule:bancolombia:transferencia_llave:v1",
            "rule:bancolombia:transferencia_llave_recibida:v1",
            "rule:nequi:breb_recibida:v1",
        }

    def test_todos_los_fixtures_tienen_plantilla_asignada(self) -> None:
        assert {f.name for f in nequi_fixtures()} == set(TEMPLATE_ID_BY_FIXTURE)

    def test_el_titulo_sin_monto_no_matchea(self, registry: TemplateRegistry) -> None:
        assert registry.match("nequi", "Recibiste plata por Bre-B! Hola, ANA PEREZ!") is None

    def test_fecha_fuera_de_ventana_lanza_extraction_invalid(
        self, registry: TemplateRegistry
    ) -> None:
        fixture = nequi_fixtures()[0]
        match = registry.match("nequi", _excerpt(registry, fixture.body))
        assert match is not None
        with pytest.raises(TemplateExtractionInvalid):
            match.to_parsed(fixture.received_at + timedelta(days=8))
