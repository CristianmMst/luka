"""Tests de la plantilla generica de Apple Pay (F4.3b, spec 006 §3.3).

El texto no es de un banco: lo arma la app de iPhone con los datos que la
automatizacion "Transaccion" de Atajos le pasa (tarjeta, comercio, monto y
fecha), asi que el contrato vive aqui y en el test de la app
(`app/test/features/capture/domain/wallet_payment_test.dart`). La plantilla
no tiene banco propio: el banco sale del nombre de la tarjeta (`capture.yaml`,
`bank_from_title`) y, si no se reconoce, queda `other`.
"""

from datetime import UTC, datetime, timedelta, timezone
from decimal import Decimal
from uuid import uuid4

import pytest
from support.email_fixtures import bancolombia_fixtures

from finanzia.modules.ledger.domain.dedupe import candidate_keys
from finanzia.modules.ledger.domain.enums import Direction
from finanzia.modules.parsing.domain.excerpt import extract_excerpt
from finanzia.modules.parsing.domain.templates import TemplateMatch, TemplateRegistry
from finanzia.modules.parsing.infrastructure.config_loader import load_parsing_config

BOGOTA = timezone(timedelta(hours=-5))
RECEIVED_AT = datetime(2026, 9, 29, 19, 6, tzinfo=UTC)
TITLE = "Mastercard Bancolombia 1234"
TEXT = (
    "Apple Pay: Compraste $12.500,00 con Mastercard Bancolombia 1234 "
    "en JUAN VALDEZ CAFE el 29/09/2026 a las 14:05"
)


@pytest.fixture
def registry() -> TemplateRegistry:
    return load_parsing_config().templates


def _body(title: str, text: str) -> str:
    return f"{title}\n\n{text}"


def _excerpt(registry: TemplateRegistry, bank: str | None, body: str) -> str:
    config = registry.bank_config(bank) if bank else None
    return extract_excerpt(body, config.relevant_line_prefix if config else None)


@pytest.mark.unit
class TestAppleWalletTemplate:
    def test_toma_el_banco_de_la_notificacion(self, registry: TemplateRegistry) -> None:
        body = _body(TITLE, TEXT)
        match = registry.match("bancolombia", _excerpt(registry, "bancolombia", body))
        assert match is not None

        parsed = match.to_parsed(RECEIVED_AT)

        assert parsed.bank == "bancolombia"
        assert parsed.amount == Decimal("12500.00")
        assert parsed.direction.value == "debit"
        assert parsed.merchant == "JUAN VALDEZ CAFE"
        assert parsed.last4 == "1234"
        assert parsed.occurred_at == datetime(2026, 9, 29, 14, 5, tzinfo=BOGOTA)
        assert parsed.parsed_by == "rule:apple_wallet:compra:v1"
        assert parsed.merchant_is_person is False

    def test_sin_banco_queda_other_y_sin_last4(self, registry: TemplateRegistry) -> None:
        text = "Apple Pay: Compraste $8.000,00 con Visa Oro en Tienda D1 el 29/09/2026 a las 09:30"
        match = registry.match(None, _excerpt(registry, None, _body("Visa Oro", text)))
        assert match is not None

        parsed = match.to_parsed(RECEIVED_AT)

        assert parsed.bank == "other"
        assert parsed.last4 is None
        assert parsed.merchant == "Tienda D1"
        assert parsed.amount == Decimal("8000.00")

    def test_un_comercio_con_la_palabra_con(self, registry: TemplateRegistry) -> None:
        text = (
            "Apple Pay: Compraste $9.900,00 con Visa Nequi 0042 en PAN CON QUESO "
            "el 29/09/2026 a las 07:45"
        )
        match = registry.match("nequi", _excerpt(registry, "nequi", _body("Visa Nequi 0042", text)))
        assert match is not None

        parsed = match.to_parsed(RECEIVED_AT)

        assert parsed.merchant == "PAN CON QUESO"
        assert parsed.last4 == "0042"
        assert parsed.bank == "nequi"

    def test_misma_huella_de_dedupe_que_el_correo_del_banco(
        self, registry: TemplateRegistry
    ) -> None:
        """Con banco y last4 en el nombre de la tarjeta, el pago de Apple Pay y
        el correo de la misma compra caen en la misma transaccion (spec 004 §3)."""
        fixture = next(f for f in bancolombia_fixtures() if f.name == "compra_tdeb_2.txt")
        email = registry.match("bancolombia", _excerpt(registry, "bancolombia", fixture.body))
        text = (
            "Apple Pay: Compraste $53.900,00 con Bancolombia 1234 en OXXO CALLE 59 "
            "el 19/09/2026 a las 21:52"
        )
        wallet = registry.match(
            "bancolombia", _excerpt(registry, "bancolombia", _body("Bancolombia 1234", text))
        )
        assert email is not None
        assert wallet is not None

        user_id = uuid4()

        def keys(match: TemplateMatch) -> tuple[str, str, str]:
            parsed = match.to_parsed(fixture.received_at)
            return candidate_keys(
                user_id=user_id,
                bank=parsed.bank,
                amount=parsed.amount,
                direction=Direction(parsed.direction.value),
                occurred_at=parsed.occurred_at,
                last4=parsed.last4,
            )

        assert keys(email)[1] == keys(wallet)[1]

    def test_las_plantillas_del_banco_van_primero(self, registry: TemplateRegistry) -> None:
        match = registry.match("bancolombia", "Apple Pay: hola")
        assert match is None

    def test_no_es_un_banco_con_plantillas(self, registry: TemplateRegistry) -> None:
        assert "apple_wallet" not in registry.known_banks()
