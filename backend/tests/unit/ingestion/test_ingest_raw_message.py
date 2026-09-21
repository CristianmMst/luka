"""Tests unitarios de `IngestRawMessage` (spec 006 §2.2-2.3, AC-2.4, §4.4, D9)."""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from finanzia.modules.ingestion.application.dto import (
    Accepted,
    BankDecision,
    Discarded,
    Duplicate,
    RawMessageInput,
)
from finanzia.modules.ingestion.application.use_cases.ingest_raw_message import IngestRawMessage
from finanzia.modules.ingestion.domain.enums import Channel, RawMessageStatus
from finanzia.modules.ingestion.domain.errors import IngestionError, InvalidExternalId
from finanzia.modules.ingestion.events import RawMessageReceived
from ingestion.fakes import (
    FakeSenderPolicy,
    FixedClock,
    InMemoryRawMessageRepo,
    NoopUoW,
    RecordingPublisher,
    SequenceIdGenerator,
)

NOW = datetime(2026, 5, 1, 12, 0, tzinfo=UTC)
USER = uuid4()
BANCOLOMBIA_SENDER = "alertasynotificaciones@an.notificacionesbancolombia.com"


def _use_case(
    *,
    policy: FakeSenderPolicy | None = None,
    repo: InMemoryRawMessageRepo | None = None,
    events: RecordingPublisher | None = None,
    uow: NoopUoW | None = None,
    body_max_bytes: int = 8192,
) -> tuple[IngestRawMessage, InMemoryRawMessageRepo, RecordingPublisher, NoopUoW]:
    repo = repo if repo is not None else InMemoryRawMessageRepo()
    events = events if events is not None else RecordingPublisher()
    uow = uow if uow is not None else NoopUoW()
    use_case = IngestRawMessage(
        repo=repo,
        policy=policy or FakeSenderPolicy(),
        events=events,
        clock=FixedClock(NOW),
        ids=SequenceIdGenerator(),
        uow=uow,
        retention_days=90,
        body_max_bytes=body_max_bytes,
    )
    return use_case, repo, events, uow


def _email_input(
    *,
    external_id: str = "msg-1",
    sender: str = "nu@nu.com.co",
    title: str | None = None,
    text: str = "Compraste $100",
    received_at: datetime = NOW,
) -> RawMessageInput:
    return RawMessageInput(
        user_id=USER,
        channel=Channel.EMAIL,
        external_id=external_id,
        sender=sender,
        title=title,
        text=text,
        received_at=received_at,
    )


@pytest.mark.unit
async def test_remitente_no_soportado_descarta_sin_tocar_repo_ni_publisher() -> None:
    use_case, repo, events, uow = _use_case(policy=FakeSenderPolicy())

    outcome = await use_case.execute(_email_input())

    assert outcome == Discarded("unsupported_sender")
    assert repo.by_id == {}
    assert events.events == []
    assert uow.commits == 0


@pytest.mark.unit
async def test_email_aceptado_inserta_fila_pending_con_purge_after_90d_y_evento_sin_body() -> None:
    policy = FakeSenderPolicy(email_map={BANCOLOMBIA_SENDER: "bancolombia"})
    use_case, repo, events, uow = _use_case(policy=policy)
    input_ = _email_input(sender=BANCOLOMBIA_SENDER, external_id="msg-2")

    outcome = await use_case.execute(input_)

    assert isinstance(outcome, Accepted)
    assert outcome.bank == "bancolombia"
    stored = repo.by_id[outcome.raw_message_id]
    assert stored.status == RawMessageStatus.PENDING
    assert stored.bank == "bancolombia"
    assert stored.purge_after == NOW + timedelta(days=90)
    assert uow.commits == 1

    assert len(events.events) == 1
    event = events.events[0]
    assert isinstance(event, RawMessageReceived)
    assert event.raw_message_id == outcome.raw_message_id
    assert event.user_id == USER
    assert event.channel == "email"
    assert event.bank == "bancolombia"
    assert event.received_at == NOW
    assert not hasattr(event, "body")


@pytest.mark.unit
async def test_body_se_trunca_a_8192_bytes_en_frontera_de_caracter() -> None:
    policy = FakeSenderPolicy(email_map={BANCOLOMBIA_SENDER: "bancolombia"})
    use_case, repo, _, _ = _use_case(policy=policy, body_max_bytes=8192)
    input_ = _email_input(sender=BANCOLOMBIA_SENDER, external_id="msg-3", text="é" * 20000)

    outcome = await use_case.execute(input_)

    assert isinstance(outcome, Accepted)
    stored = repo.by_id[outcome.raw_message_id]
    assert stored.body is not None
    assert len(stored.body.encode("utf-8")) <= 8192


@pytest.mark.unit
async def test_duplicado_con_fila_pending_republica_el_evento() -> None:
    policy = FakeSenderPolicy(email_map={BANCOLOMBIA_SENDER: "bancolombia"})
    use_case, _, events, _ = _use_case(policy=policy)
    input_ = _email_input(sender=BANCOLOMBIA_SENDER, external_id="msg-4")

    first = await use_case.execute(input_)
    second = await use_case.execute(input_)

    assert isinstance(first, Accepted)
    assert second == Duplicate(first.raw_message_id, republished=True, bank="bancolombia")
    assert isinstance(second, Duplicate)
    assert second.bank == first.bank == "bancolombia"
    assert len(events.events) == 2


@pytest.mark.unit
async def test_duplicado_con_fila_parsed_no_republica_el_evento() -> None:
    policy = FakeSenderPolicy(email_map={BANCOLOMBIA_SENDER: "bancolombia"})
    use_case, repo, events, _ = _use_case(policy=policy)
    input_ = _email_input(sender=BANCOLOMBIA_SENDER, external_id="msg-5")

    first = await use_case.execute(input_)
    assert isinstance(first, Accepted)
    await repo.set_status(first.raw_message_id, RawMessageStatus.PARSED, NOW)
    events.events.clear()

    second = await use_case.execute(input_)

    assert second == Duplicate(first.raw_message_id, republished=False, bank="bancolombia")
    assert events.events == []


@pytest.mark.unit
async def test_client_hash_no_hex_lanza_invalid_external_id() -> None:
    use_case, _, _, _ = _use_case()
    input_ = RawMessageInput(
        user_id=USER,
        channel=Channel.NOTIFICATION,
        external_id="not-a-hash",
        sender="com.bancolombia.app",
        title=None,
        text="texto",
        received_at=NOW,
    )

    with pytest.raises(InvalidExternalId):
        await use_case.execute(input_)


@pytest.mark.unit
async def test_email_external_id_vacio_lanza_invalid_external_id() -> None:
    use_case, _, _, _ = _use_case()
    input_ = _email_input(external_id="")

    with pytest.raises(InvalidExternalId):
        await use_case.execute(input_)


@pytest.mark.unit
async def test_notificacion_de_paquete_desconocido_descarta() -> None:
    use_case, repo, events, _ = _use_case(policy=FakeSenderPolicy())
    input_ = RawMessageInput(
        user_id=USER,
        channel=Channel.NOTIFICATION,
        external_id="a" * 64,
        sender="com.whatsapp",
        title=None,
        text="texto",
        received_at=NOW,
    )

    outcome = await use_case.execute(input_)

    assert outcome == Discarded("unsupported_package")
    assert repo.by_id == {}
    assert events.events == []


@pytest.mark.unit
async def test_sms_de_app_de_mensajes_con_titulo_de_banco_se_acepta_con_banco() -> None:
    policy = FakeSenderPolicy(
        notification_map={
            ("com.google.android.apps.messaging", "sms_notification"): BankDecision(
                accepted=True, bank="bancolombia"
            )
        }
    )
    use_case, repo, _, _ = _use_case(policy=policy)
    input_ = RawMessageInput(
        user_id=USER,
        channel=Channel.SMS_NOTIFICATION,
        external_id="b" * 64,
        sender="com.google.android.apps.messaging",
        title="Bancolombia",
        text="Compraste $100",
        received_at=NOW,
    )

    outcome = await use_case.execute(input_)

    assert isinstance(outcome, Accepted)
    assert outcome.bank == "bancolombia"
    stored = repo.by_id[outcome.raw_message_id]
    assert stored.bank == "bancolombia"
    assert stored.body == "Bancolombia\n\nCompraste $100"


class _RaceRepo(InMemoryRawMessageRepo):
    """Simula el conflicto de `insert_if_absent` sin que exista una fila resultante
    (carrera improbable: borrado concurrente entre el INSERT y el SELECT)."""

    async def insert_if_absent(self, msg):  # type: ignore[override]
        del msg

    async def get_by_external_id(self, user_id, channel, external_id):  # type: ignore[override]
        del user_id, channel, external_id


@pytest.mark.unit
async def test_conflicto_sin_fila_resultante_lanza_ingestion_error() -> None:
    policy = FakeSenderPolicy(email_map={BANCOLOMBIA_SENDER: "bancolombia"})
    use_case, _, _, _ = _use_case(policy=policy, repo=_RaceRepo())
    input_ = _email_input(sender=BANCOLOMBIA_SENDER, external_id="msg-race")

    with pytest.raises(IngestionError):
        await use_case.execute(input_)
