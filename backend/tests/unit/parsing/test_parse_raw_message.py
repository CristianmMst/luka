"""Tests unitarios de `ParseRawMessage` (spec 006 SS4/SS4.2, F2.2, D8/D11/D12).

Cubre el pipeline completo (plantilla -> LLM -> revision) contra fakes puros:
sin Docker, sin red, sin DB. Los fixtures reales de Bancolombia se corren
contra el `TemplateRegistry` cargado del YAML empaquetado (via
`parsing.fakes.make_use_case`), igual que `test_templates_bancolombia.py`.
"""

from __future__ import annotations

from dataclasses import replace
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import uuid4

import pytest
from support.email_fixtures import FIXTURES_DIR, bancolombia_fixtures, load_email_fixtures

from luka.modules.parsing.application.dto import (
    Discarded,
    Failed,
    LlmInvalidOutput,
    LlmOutput,
    Parsed,
    RawMessageView,
    Skipped,
)
from luka.modules.parsing.domain.enums import Direction, ParseFailureReason
from luka.modules.parsing.domain.errors import LlmUnavailable
from luka.modules.parsing.domain.llm_validation import LlmExtraction
from luka.modules.parsing.events import ParseFailed, TransactionParsed, deterministic_event_id
from parsing.fakes import (
    FakeGateway,
    FakeLlmParser,
    FixedClock,
    InMemoryBudget,
    MetricCall,
    NoopUoW,
    RecordingMetrics,
    RecordingPublisher,
    make_use_case,
    view_from_fixture,
)

pytestmark = pytest.mark.unit

NOW = datetime(2026, 9, 21, 12, 0, tzinfo=UTC)
USER_ID = uuid4()
SENDER = "alertasynotificaciones@an.notificacionesbancolombia.com"

TEMPLATE_ID_BY_FIXTURE = {
    "compra_tdeb.txt": "compra_tdeb",
    "compra_tdeb_2.txt": "compra_tdeb",
    "nomina.txt": "nomina",
    "pago_producto.txt": "pago_producto",
    "pago_producto_2.txt": "pago_producto",
    "pago_qr.txt": "pago_qr",
    "pago_qr_wrap.txt": "pago_qr",
    "transferencia_cuenta_wrap.txt": "transferencia_cuenta",
    "transferencia_llave.txt": "transferencia_llave",
    "transferencia_llave_wrap.txt": "transferencia_llave",
    "transferencia_llave_recibida_wrap.txt": "transferencia_llave_recibida",
}

# Extracto de Bancolombia que no matchea ninguna de las 7 plantillas conocidas
# (retiro de cajero: variante especulativa explicitamente NO incluida, spec 006
# SS4.1) pero contiene un monto -> cae al LLM.
_UNRECOGNIZED_BODY = "Bancolombia: Retiraste $50.000 en el cajero de la Calle 10 con tu tarjeta."

# Sin ningun marcador monetario -> ni plantilla ni LLM (`no_template`).
_NO_MONEY_BODY = "Bancolombia: Tu clave dinamica se actualizo correctamente."

_VALID_EXTRACTION = LlmExtraction(
    is_transaction=True,
    amount=Decimal("50000.00"),
    currency="COP",
    direction=Direction.DEBIT,
    merchant="CAJERO CALLE 10",
    occurred_at=NOW - timedelta(hours=1),
    bank="bancolombia",
    last4="1234",
    suggested_category=None,
    confidence=0.93,
)


def _view(
    *,
    body: str | None = _UNRECOGNIZED_BODY,
    bank: str | None = "bancolombia",
    status: str = "pending",
) -> RawMessageView:
    return RawMessageView(
        id=uuid4(),
        user_id=USER_ID,
        channel="email",
        bank=bank,
        sender=SENDER,
        body=body,
        status=status,
        received_at=NOW,
    )


# --- Plantilla (fixtures reales) -----------------------------------------------------


@pytest.mark.parametrize("fixture", bancolombia_fixtures(), ids=lambda f: f.name)
async def test_fixture_bancolombia_matchea_por_plantilla(fixture) -> None:
    raw_message_id = uuid4()
    view = view_from_fixture(fixture, USER_ID, raw_message_id=raw_message_id)
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([])
    metrics = RecordingMetrics()
    events = RecordingPublisher()
    uow = NoopUoW()
    use_case = make_use_case(
        gateway=gateway, llm=llm, metrics=metrics, events=events, uow=uow, clock=FixedClock(NOW)
    )

    outcome = await use_case.execute(raw_message_id)

    template_id = TEMPLATE_ID_BY_FIXTURE[fixture.name]
    assert isinstance(outcome, Parsed)
    assert outcome.parsed_by == f"rule:bancolombia:{template_id}:v1"

    assert len(events.events) == 1
    event = events.events[0]
    assert isinstance(event, TransactionParsed)
    expected = fixture.expected
    assert event.event_id == outcome.transaction_event_id
    assert event.raw_message_id == raw_message_id
    assert event.user_id == USER_ID
    assert event.channel == "email"
    assert event.bank == "bancolombia"
    assert event.amount == Decimal(expected["amount"])
    assert event.direction.value == expected["direction"]
    assert event.merchant == expected.get("merchant")
    assert event.last4 == expected.get("last4")
    assert event.transaction_occurred_at == expected["occurred_at"]
    assert event.parsed_by == outcome.parsed_by
    assert event.confidence is None
    assert event.suggested_category == expected.get("suggested_category")

    assert gateway.marks == [(raw_message_id, "parsed")]
    assert uow.commits == 1
    assert llm.calls == []
    assert metrics.calls == [
        MetricCall(
            "parsed_by_rule",
            bank="bancolombia",
            channel="email",
            template_id=template_id,
            reason=None,
            llm_tokens=None,
        )
    ]


# --- Extracto cortado a mitad de linea (spec 006 §4.1) ------------------------------


_WRAPPED_CREDIT_BODY = (
    "Encabezado de plantilla del correo, con imagenes y textos alternativos.\n"
    "¡Listo! Todo salió bien con tus movimientos Bancolombia: ANA, recibiste\n"
    "una transferencia de PEDRO GOMEZ por $650,000.00 en tu cuenta *7788\n"
    "conectada a la llave @pgomez99 el 21/09/26 a las 10:15. Con llaves es de\n"
    "una y gratis. Dudas al 018000912345.\n"
)

_WRAPPED_DEBIT_BODY = (
    "Encabezado de plantilla del correo, con imagenes y textos alternativos.\n"
    "¡Listo! Todo salió bien con tus movimientos Bancolombia: ANA, transferiste\n"
    "$650,000.00 a la llave 3009988776 desde tu cuenta *7788 a PEDRO GOMEZ el\n"
    "21/09/26 a las 10:15. Con Bre-b es de una y gratis. Dudas al 018000912345.\n"
)


@pytest.mark.parametrize(
    ("body", "template_id", "direction", "merchant", "last4"),
    [
        (
            _WRAPPED_CREDIT_BODY,
            "transferencia_llave_recibida",
            Direction.CREDIT,
            "PEDRO GOMEZ",
            "7788",
        ),
        (
            _WRAPPED_DEBIT_BODY,
            "transferencia_llave",
            Direction.DEBIT,
            "PEDRO GOMEZ",
            "7788",
        ),
    ],
)
async def test_correo_cortado_a_mitad_de_linea_matchea_por_plantilla(
    body: str, template_id: str, direction: Direction, merchant: str, last4: str
) -> None:
    """El correo llega cortado a ~76 caracteres y la frase util empieza a
    mitad de la primera linea (tras el saludo): `extract_excerpt` debe seguir
    encontrando la plantilla en ambas direcciones (credit/debit), no caer al
    LLM (spec 006 §4.1).
    """
    view = _view(body=body)
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([])
    events = RecordingPublisher()
    use_case = make_use_case(gateway=gateway, llm=llm, events=events, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert isinstance(outcome, Parsed)
    assert outcome.parsed_by == f"rule:bancolombia:{template_id}:v1"
    assert llm.calls == []
    event = events.events[0]
    assert isinstance(event, TransactionParsed)
    assert event.direction == direction
    assert event.merchant == merchant
    assert event.last4 == last4


async def test_plantilla_matchea_pero_extraccion_invalida_cae_a_llm() -> None:
    """El regex matchea pero `to_parsed` lanza `TemplateExtractionInvalid` (fecha
    fuera de ventana respecto al `received_at` real del mensaje): se trata como
    "sin plantilla" y sigue al LLM, no como un fallo duro.
    """
    fixture = next(f for f in bancolombia_fixtures() if f.name == "compra_tdeb.txt")
    far_received_at = fixture.received_at + timedelta(days=30)
    view = RawMessageView(
        id=uuid4(),
        user_id=USER_ID,
        channel="email",
        bank="bancolombia",
        sender=fixture.sender,
        body=fixture.body,
        status="pending",
        received_at=far_received_at,
    )
    extraction = replace(_VALID_EXTRACTION, occurred_at=far_received_at - timedelta(hours=1))
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([LlmOutput(extraction=extraction, tokens=90)])
    use_case = make_use_case(gateway=gateway, llm=llm, clock=FixedClock(far_received_at))

    outcome = await use_case.execute(view.id)

    assert isinstance(outcome, Parsed)
    assert outcome.parsed_by == "llm"
    assert len(llm.calls) == 1
    assert gateway.marks == [(view.id, "parsed")]


async def test_publica_el_evento_antes_de_marcar_y_commitear() -> None:
    """D8: el orden es publish -> mark -> commit, nunca al reves."""
    fixture = next(f for f in bancolombia_fixtures() if f.name == "compra_tdeb.txt")
    raw_message_id = uuid4()
    view = view_from_fixture(fixture, USER_ID, raw_message_id=raw_message_id)
    log: list[str] = []
    gateway = FakeGateway({view.id: view}, log=log)
    events = RecordingPublisher(log=log)
    uow = NoopUoW(log=log)
    use_case = make_use_case(gateway=gateway, events=events, uow=uow, clock=FixedClock(NOW))

    outcome = await use_case.execute(raw_message_id)

    assert isinstance(outcome, Parsed)
    assert log == ["publish:TransactionParsed", "mark:parsed", "commit"]


async def test_publica_el_evento_fallido_antes_de_marcar_y_commitear() -> None:
    """D8 tambien en el camino de fallo: publish -> mark("failed") -> commit."""
    view = _view(body=None)
    log: list[str] = []
    gateway = FakeGateway({view.id: view}, log=log)
    events = RecordingPublisher(log=log)
    uow = NoopUoW(log=log)
    use_case = make_use_case(gateway=gateway, events=events, uow=uow, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert outcome == Failed(ParseFailureReason.BODY_PURGED)
    assert log == ["publish:ParseFailed", "mark:failed", "commit"]


# --- Idempotencia / reentrega ---------------------------------------------------------


async def test_estado_no_pending_es_skipped_sin_efectos() -> None:
    view = _view(status="parsed")
    gateway = FakeGateway({view.id: view})
    events = RecordingPublisher()
    metrics = RecordingMetrics()
    uow = NoopUoW()
    use_case = make_use_case(gateway=gateway, events=events, metrics=metrics, uow=uow)

    outcome = await use_case.execute(view.id)

    assert outcome == Skipped("not_pending")
    assert events.events == []
    assert gateway.marks == []
    assert metrics.calls == []
    assert uow.commits == 0


async def test_segunda_ejecucion_tras_cambio_de_estado_es_skipped() -> None:
    """Reentrega tras un exito: la primera ejecucion parsea y marca `parsed`; la
    segunda, sobre el MISMO gateway/vista (ya mutada por `mark`), no debe repetir
    ningun efecto (idempotencia, P2).
    """
    fixture = next(f for f in bancolombia_fixtures() if f.name == "compra_tdeb.txt")
    raw_message_id = uuid4()
    view = view_from_fixture(fixture, USER_ID, raw_message_id=raw_message_id)
    gateway = FakeGateway({view.id: view})
    events = RecordingPublisher()
    metrics = RecordingMetrics()
    uow = NoopUoW()
    use_case = make_use_case(
        gateway=gateway, events=events, metrics=metrics, uow=uow, clock=FixedClock(NOW)
    )

    first_outcome = await use_case.execute(raw_message_id)
    assert isinstance(first_outcome, Parsed)
    marks_after_first = list(gateway.marks)
    events_after_first = list(events.events)
    metrics_after_first = list(metrics.calls)
    commits_after_first = uow.commits

    second_outcome = await use_case.execute(raw_message_id)

    assert second_outcome == Skipped("not_pending")
    assert gateway.marks == marks_after_first
    assert events.events == events_after_first
    assert metrics.calls == metrics_after_first
    assert uow.commits == commits_after_first


async def test_id_desconocido_es_skipped_not_found() -> None:
    use_case = make_use_case()

    outcome = await use_case.execute(uuid4())

    assert outcome == Skipped("not_found")


async def test_event_id_determinista_entre_dos_ejecuciones() -> None:
    fixture = next(f for f in bancolombia_fixtures() if f.name == "compra_tdeb.txt")
    raw_message_id = uuid4()
    view = view_from_fixture(fixture, USER_ID, raw_message_id=raw_message_id)

    use_case_1 = make_use_case(gateway=FakeGateway({view.id: view}), clock=FixedClock(NOW))
    outcome_1 = await use_case_1.execute(raw_message_id)

    use_case_2 = make_use_case(gateway=FakeGateway({view.id: view}), clock=FixedClock(NOW))
    outcome_2 = await use_case_2.execute(raw_message_id)

    assert isinstance(outcome_1, Parsed)
    assert isinstance(outcome_2, Parsed)
    assert outcome_1.transaction_event_id == outcome_2.transaction_event_id
    assert outcome_1.transaction_event_id == deterministic_event_id("parsed", raw_message_id)


# --- Cuerpo purgado --------------------------------------------------------------------


async def test_body_none_falla_body_purged() -> None:
    view = _view(body=None)
    gateway = FakeGateway({view.id: view})
    events = RecordingPublisher()
    metrics = RecordingMetrics()
    uow = NoopUoW()
    use_case = make_use_case(
        gateway=gateway, events=events, metrics=metrics, uow=uow, clock=FixedClock(NOW)
    )

    outcome = await use_case.execute(view.id)

    assert outcome == Failed(ParseFailureReason.BODY_PURGED)
    assert len(events.events) == 1
    event = events.events[0]
    assert isinstance(event, ParseFailed)
    assert event.reason == ParseFailureReason.BODY_PURGED
    assert event.partial_extract == {}
    assert gateway.marks == [(view.id, "failed")]
    assert uow.commits == 1
    assert metrics.calls == [
        MetricCall(
            "sent_to_review",
            bank="bancolombia",
            channel="email",
            template_id=None,
            reason="body_purged",
            llm_tokens=None,
        )
    ]


# --- Sin plantilla, sin monto: ni LLM -------------------------------------------------


async def test_texto_sin_monto_falla_no_template_sin_llamar_llm() -> None:
    view = _view(body=_NO_MONEY_BODY)
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([])
    use_case = make_use_case(gateway=gateway, llm=llm, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert outcome == Failed(ParseFailureReason.NO_TEMPLATE)
    assert llm.calls == []


# --- LLM: extracto/fecha son lo unico que viaja (P1) ----------------------------------


async def test_llm_recibe_solo_extracto_y_fecha() -> None:
    view = _view()
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([LlmOutput(extraction=_VALID_EXTRACTION, tokens=120)])
    use_case = make_use_case(gateway=gateway, llm=llm, clock=FixedClock(NOW))

    await use_case.execute(view.id)

    assert len(llm.calls) == 1
    prompt, received_on = llm.calls[0]
    assert received_on == view.received_at.date()
    assert "Retiraste" in prompt
    assert str(USER_ID) not in prompt
    assert SENDER not in prompt
    assert str(view.id) not in prompt


# --- LLM: exito ------------------------------------------------------------------------


async def test_llm_confianza_alta_produce_parsed_por_llm() -> None:
    view = _view()
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([LlmOutput(extraction=_VALID_EXTRACTION, tokens=120)])
    budget = InMemoryBudget()
    metrics = RecordingMetrics()
    events = RecordingPublisher()
    uow = NoopUoW()
    use_case = make_use_case(
        gateway=gateway,
        llm=llm,
        budget=budget,
        metrics=metrics,
        events=events,
        uow=uow,
        clock=FixedClock(NOW),
    )

    outcome = await use_case.execute(view.id)

    assert isinstance(outcome, Parsed)
    assert outcome.parsed_by == "llm"
    assert len(events.events) == 1
    event = events.events[0]
    assert isinstance(event, TransactionParsed)
    assert event.parsed_by == "llm"
    assert event.confidence == pytest.approx(0.93)
    assert budget.adds == [(USER_ID, "202609", 120)]
    assert metrics.calls == [
        MetricCall(
            "parsed_by_llm",
            bank="bancolombia",
            channel="email",
            template_id=None,
            reason=None,
            llm_tokens=120,
        )
    ]


async def test_nu_bank_other_via_llm() -> None:
    """D5: el cuerpo de Nu (descartado por remitente en ingestion) se reutiliza
    aqui solo para probar el mapeo LLM -> `ParsedTransaction` con `bank="other"`,
    incluyendo que el 4xmil no contamine el monto de la compra.
    """
    fixture = next(
        f for f in load_email_fixtures(FIXTURES_DIR / "other") if f.name == "nu_pago.txt"
    )
    view = RawMessageView(
        id=uuid4(),
        user_id=USER_ID,
        channel="email",
        bank=None,
        sender=fixture.sender,
        body=fixture.body,
        status="pending",
        received_at=fixture.received_at,
    )
    extraction = LlmExtraction(
        is_transaction=True,
        amount=Decimal("16285200.00"),
        currency="COP",
        direction=Direction.DEBIT,
        merchant="CORREDORES DAVIVIENDA S A COMISIONISTA DE BOLSA",
        occurred_at=fixture.received_at,
        bank="other",
        last4=None,
        suggested_category=None,
        confidence=0.95,
    )
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([LlmOutput(extraction=extraction, tokens=200)])
    events = RecordingPublisher()
    use_case = make_use_case(gateway=gateway, llm=llm, events=events, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert isinstance(outcome, Parsed)
    assert outcome.parsed_by == "llm"
    assert gateway.marks == [(view.id, "parsed")]
    assert len(llm.calls) == 1
    assert len(events.events) == 1
    event = events.events[0]
    assert isinstance(event, TransactionParsed)
    assert event.bank == "other"
    assert event.amount == Decimal("16285200.00")


# --- LLM: rechazos semanticos ------------------------------------------------------------


async def test_llm_confianza_baja_falla_low_confidence_con_partial_sin_ids() -> None:
    view = _view()
    gateway = FakeGateway({view.id: view})
    low_conf = replace(_VALID_EXTRACTION, confidence=0.5)
    llm = FakeLlmParser([LlmOutput(extraction=low_conf, tokens=80)])
    events = RecordingPublisher()
    use_case = make_use_case(gateway=gateway, llm=llm, events=events, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert outcome == Failed(ParseFailureReason.LLM_LOW_CONFIDENCE)
    event = events.events[0]
    assert isinstance(event, ParseFailed)
    assert event.reason == ParseFailureReason.LLM_LOW_CONFIDENCE
    assert event.partial_extract
    assert all(isinstance(v, str) for v in event.partial_extract.values())
    assert str(USER_ID) not in event.partial_extract.values()
    assert str(view.id) not in event.partial_extract.values()


async def test_llm_fecha_30_dias_falla_invalid_output() -> None:
    view = _view()
    gateway = FakeGateway({view.id: view})
    far = replace(_VALID_EXTRACTION, occurred_at=NOW - timedelta(days=30))
    llm = FakeLlmParser([LlmOutput(extraction=far, tokens=80)])
    use_case = make_use_case(gateway=gateway, llm=llm, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert outcome == Failed(ParseFailureReason.LLM_INVALID_OUTPUT)


async def test_llm_banco_desconocido_falla_invalid_output() -> None:
    view = _view()
    gateway = FakeGateway({view.id: view})
    unknown_bank = replace(_VALID_EXTRACTION, bank="banco_inventado")
    llm = FakeLlmParser([LlmOutput(extraction=unknown_bank, tokens=80)])
    use_case = make_use_case(gateway=gateway, llm=llm, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert outcome == Failed(ParseFailureReason.LLM_INVALID_OUTPUT)


async def test_llm_banco_del_allowlist_sin_plantilla_se_acepta() -> None:
    """Los 6 bancos del allowlist de remitentes son validos en la salida del LLM.

    Solo `bancolombia` tiene plantilla (F2.7 diferido), pero el prompt le pide al
    modelo justamente esos slugs y el CHECK de la tabla los acepta: validar contra
    los bancos CON PLANTILLA rechazaria como `llm_invalid_output` toda extraccion
    de Nequi/Davivienda/DaviPlata/BBVA/Banco de Bogota.
    """
    view = _view(bank="nequi")
    gateway = FakeGateway({view.id: view})
    extraction = replace(_VALID_EXTRACTION, bank="nequi")
    llm = FakeLlmParser([LlmOutput(extraction=extraction, tokens=80)])
    events = RecordingPublisher()
    use_case = make_use_case(gateway=gateway, llm=llm, events=events, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert isinstance(outcome, Parsed)
    assert outcome.parsed_by == "llm"
    published = events.events[0]
    assert isinstance(published, TransactionParsed)
    assert published.bank == "nequi"


async def test_llm_is_transaction_false_descarta_sin_eventos() -> None:
    view = _view()
    gateway = FakeGateway({view.id: view})
    not_tx = LlmExtraction(
        is_transaction=False,
        amount=None,
        currency=None,
        direction=None,
        merchant=None,
        occurred_at=None,
        bank=None,
        last4=None,
        suggested_category=None,
        confidence=0.99,
    )
    llm = FakeLlmParser([LlmOutput(extraction=not_tx, tokens=15)])
    events = RecordingPublisher()
    metrics = RecordingMetrics()
    uow = NoopUoW()
    use_case = make_use_case(
        gateway=gateway, llm=llm, events=events, metrics=metrics, uow=uow, clock=FixedClock(NOW)
    )

    outcome = await use_case.execute(view.id)

    assert outcome == Discarded()
    assert gateway.marks == [(view.id, "discarded")]
    assert events.events == []
    assert uow.commits == 1
    assert metrics.calls == [
        MetricCall(
            "discarded",
            bank="bancolombia",
            channel="email",
            template_id=None,
            reason=None,
            llm_tokens=None,
        )
    ]


# --- LLM: JSON/esquema invalido, reintento unico ----------------------------------------


async def test_llm_invalido_dos_veces_falla_invalid_json_con_2_llamadas() -> None:
    view = _view()
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([LlmInvalidOutput(tokens=30), LlmInvalidOutput(tokens=40)])
    budget = InMemoryBudget()
    use_case = make_use_case(gateway=gateway, llm=llm, budget=budget, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert outcome == Failed(ParseFailureReason.LLM_INVALID_JSON)
    assert len(llm.calls) == 2
    assert budget.adds == [(USER_ID, "202609", 70)]


async def test_llm_invalido_luego_valido_produce_parsed() -> None:
    view = _view()
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser(
        [LlmInvalidOutput(tokens=30), LlmOutput(extraction=_VALID_EXTRACTION, tokens=90)]
    )
    budget = InMemoryBudget()
    use_case = make_use_case(gateway=gateway, llm=llm, budget=budget, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert isinstance(outcome, Parsed)
    assert len(llm.calls) == 2
    assert budget.adds == [(USER_ID, "202609", 120)]


# --- Presupuesto / disponibilidad del LLM -----------------------------------------------


async def test_presupuesto_agotado_falla_budget_exceeded_sin_llamar_llm() -> None:
    view = _view()
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([])
    budget = InMemoryBudget({(USER_ID, "202609"): 100_000})
    use_case = make_use_case(
        gateway=gateway, llm=llm, budget=budget, llm_budget_limit=100_000, clock=FixedClock(NOW)
    )

    outcome = await use_case.execute(view.id)

    assert outcome == Failed(ParseFailureReason.LLM_BUDGET_EXCEEDED)
    assert llm.calls == []


async def test_llm_deshabilitado_falla_llm_disabled() -> None:
    view = _view()
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([], enabled=False)
    use_case = make_use_case(gateway=gateway, llm=llm, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert outcome == Failed(ParseFailureReason.LLM_DISABLED)


async def test_llm_no_disponible_falla_llm_error() -> None:
    view = _view()
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([LlmUnavailable("timeout")])
    use_case = make_use_case(gateway=gateway, llm=llm, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert outcome == Failed(ParseFailureReason.LLM_ERROR)


async def test_llm_invalido_luego_no_disponible_suma_tokens_del_primero() -> None:
    """El reintento (unico) tambien puede fallar por indisponibilidad; los
    tokens de la primera llamada (invalida) igual se suman al presupuesto (D11).
    """
    view = _view()
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([LlmInvalidOutput(tokens=30), LlmUnavailable("timeout")])
    budget = InMemoryBudget()
    use_case = make_use_case(gateway=gateway, llm=llm, budget=budget, clock=FixedClock(NOW))

    outcome = await use_case.execute(view.id)

    assert outcome == Failed(ParseFailureReason.LLM_ERROR)
    assert len(llm.calls) == 2
    assert budget.adds == [(USER_ID, "202609", 30)]


# --- bank=None (mensajes tipo Nu, fuera del allowlist de plantillas) -------------------


async def test_falla_con_bank_none_propaga_bank_none_al_evento_y_a_la_metrica() -> None:
    """Un `raw_message` sin banco resuelto (p. ej. Nu, D5) que falla debe seguir
    llevando `bank=None` en `ParseFailed` y en la metrica `sent_to_review`, nunca
    inventar un banco.
    """
    view = _view(bank=None)
    gateway = FakeGateway({view.id: view})
    llm = FakeLlmParser([], enabled=False)
    events = RecordingPublisher()
    metrics = RecordingMetrics()
    use_case = make_use_case(
        gateway=gateway, llm=llm, events=events, metrics=metrics, clock=FixedClock(NOW)
    )

    outcome = await use_case.execute(view.id)

    assert outcome == Failed(ParseFailureReason.LLM_DISABLED)
    assert len(events.events) == 1
    event = events.events[0]
    assert isinstance(event, ParseFailed)
    assert event.bank is None
    assert metrics.calls == [
        MetricCall(
            "sent_to_review",
            bank=None,
            channel="email",
            template_id=None,
            reason="llm_disabled",
            llm_tokens=None,
        )
    ]
