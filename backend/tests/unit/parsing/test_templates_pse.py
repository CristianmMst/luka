"""Tests de la plantilla generica de PSE (spec 006 SS4.1).

PSE (ACH Colombia) no es un banco: el remitente `serviciopse@achcolombia.com.co`
queda en `senders.yaml` como `other` y su plantilla es generica, asi que el
movimiento se guarda con `bank=other`. El correo trae "Valor", "Empresa" (el
comercio), "Descripcion", "Fecha de la transaccion" (sin hora) y "CUS"; la hora
del movimiento es la de llegada del correo (`time_from_received`).
"""

from datetime import UTC, datetime, timedelta
from decimal import Decimal

import pytest
from support.email_fixtures import pse_fixtures

from luka.modules.parsing.domain.errors import TemplateConfigError, TemplateExtractionInvalid
from luka.modules.parsing.domain.excerpt import extract_excerpt
from luka.modules.parsing.domain.templates import TemplateRegistry
from luka.modules.parsing.infrastructure.config_loader import load_parsing_config

SENDER = "serviciopse <serviciopse@achcolombia.com.co>"


@pytest.fixture
def registry() -> TemplateRegistry:
    return load_parsing_config().templates


def _excerpt(body: str) -> str:
    """Sin banco propio no hay `relevant_line_prefix`: el extracto de respaldo."""
    return extract_excerpt(body, None)


@pytest.mark.unit
class TestPseTemplate:
    @pytest.mark.parametrize("fixture", pse_fixtures(), ids=lambda f: f.name)
    def test_extrae_lo_esperado_por_fixture(self, registry: TemplateRegistry, fixture) -> None:
        match = registry.match("other", _excerpt(fixture.body))
        assert match is not None, f"{fixture.name}: no matcheo ninguna plantilla"

        parsed = match.to_parsed(fixture.received_at)
        expected = fixture.expected

        assert parsed.bank == "other"
        assert parsed.amount == Decimal(expected["amount"])
        assert parsed.direction.value == expected["direction"]
        assert parsed.merchant == expected["merchant"]
        assert parsed.last4 is None
        assert parsed.occurred_at == expected["occurred_at"]
        assert parsed.parsed_by == "rule:pse:pago:v1"
        assert parsed.merchant_is_person is False

    def test_el_remitente_de_pse_entra_como_other(self) -> None:
        senders = load_parsing_config().senders
        assert senders.bank_for_email_sender(SENDER) == "other"
        assert senders.bank_for_email_sender("x@achcolombia.com.co.evil.com") is None

    def test_la_hora_es_la_de_llegada_aunque_el_correo_llegue_otro_dia(
        self, registry: TemplateRegistry
    ) -> None:
        """Pago del 3 que avisan el 4 a las 00:20: la fecha del correo y la hora de
        llegada, nunca la fecha de llegada."""
        body = (
            "Valor: $ 10.000,00\nEmpresa: TIENDA\n"
            "Fecha de la transacción: 03/10/2026\nCUS: 700000001"
        )
        received_at = datetime(2026, 10, 4, 5, 20, tzinfo=UTC)  # 00:20 en Bogota
        match = registry.match("other", _excerpt(body))
        assert match is not None

        parsed = match.to_parsed(received_at)

        assert parsed.occurred_at == datetime(2026, 10, 3, 5, 20, tzinfo=UTC)

    def test_sin_empresa_queda_sin_comercio(self, registry: TemplateRegistry) -> None:
        body = "Valor: $ 10.000,00\nFecha de la transacción: 03/10/2026\nCUS: 700000001"
        match = registry.match("other", _excerpt(body))
        assert match is not None
        assert match.to_parsed(datetime(2026, 10, 3, 20, 0, tzinfo=UTC)).merchant is None

    def test_sin_fecha_de_la_transaccion_no_matchea(self, registry: TemplateRegistry) -> None:
        body = "Valor: $ 10.000,00\nEmpresa: TIENDA\nCUS: 700000001"
        assert registry.match("other", _excerpt(body)) is None

    def test_no_atrapa_correos_de_un_banco_sin_cus_ni_empresa(
        self, registry: TemplateRegistry
    ) -> None:
        """La plantilla generica se prueba despues de las de cada banco: exigir
        CUS o Empresa evita que se quede con otros avisos."""
        body = "Valor: $ 10.000,00\nFecha de la transacción: 03/10/2026\nReferencia: 123"
        assert registry.match("nequi", _excerpt(body)) is None

    def test_fecha_fuera_de_ventana_no_se_acepta(self, registry: TemplateRegistry) -> None:
        fixture = pse_fixtures()[0]
        match = registry.match("other", _excerpt(fixture.body))
        assert match is not None
        with pytest.raises(TemplateExtractionInvalid):
            match.to_parsed(fixture.received_at + timedelta(days=30))


@pytest.mark.unit
class TestTimeFromReceivedConfig:
    def _config(self, **template: object) -> dict[str, object]:
        return {
            "bank": "x",
            "generic": True,
            "version": 1,
            "templates": [
                {
                    "id": "t",
                    "direction": "debit",
                    "date_format": "%d/%m/%Y",
                    **template,
                }
            ],
        }

    def test_sin_grupo_time_y_sin_time_from_received_es_error(self) -> None:
        with pytest.raises(TemplateConfigError):
            TemplateRegistry.from_dicts([self._config(pattern=r"(?P<amount>\d+) (?P<date>\S+)")])

    def test_time_from_received_no_booleano_es_error(self) -> None:
        with pytest.raises(TemplateConfigError):
            TemplateRegistry.from_dicts(
                [self._config(pattern=r"(?P<amount>\d+) (?P<date>\S+)", time_from_received="si")]
            )
