"""Dobles de prueba del caso de uso de parsing (sin infraestructura)."""

from __future__ import annotations

import uuid
from dataclasses import dataclass, replace
from datetime import UTC, date, datetime
from uuid import UUID

from support.clock import FixedClock
from support.email_fixtures import EmailFixture

from finanzia.modules.parsing.application.dto import (
    LlmResult,
    RawMessageView,
)
from finanzia.modules.parsing.application.ports import (
    ClockPort,
    EventPublisherPort,
    LlmBudgetPort,
    LlmParserPort,
    MetricsPort,
    RawMessageGatewayPort,
    TemplateRegistryPort,
    UnitOfWorkPort,
)
from finanzia.modules.parsing.application.use_cases.parse_raw_message import ParseRawMessage
from finanzia.modules.parsing.infrastructure.config_loader import load_parsing_config

__all__ = [
    "FakeGateway",
    "FakeLlmParser",
    "FixedClock",
    "InMemoryBudget",
    "MetricCall",
    "NoopUoW",
    "RecordingMetrics",
    "RecordingPublisher",
    "make_use_case",
    "view_from_fixture",
]

_EMAIL_FIXTURE_ID_NAMESPACE = "https://finanzia.app/test-raw-messages/"


class FakeGateway:
    """Doble de `RawMessageGatewayPort`: vistas en memoria + registro de `mark`.

    `log`, si se pasa, es una lista compartida entre varios fakes (gateway,
    publisher, uow) para poder aserturar el orden relativo publish -> mark ->
    commit (D8) desde el test.
    """

    def __init__(self, views: dict[UUID, RawMessageView], *, log: list[str] | None = None) -> None:
        self._views = dict(views)
        self.marks: list[tuple[UUID, str]] = []
        self._log = log

    async def get_for_parsing(self, raw_message_id: UUID) -> RawMessageView | None:
        return self._views.get(raw_message_id)

    async def mark(self, raw_message_id: UUID, status: str, now: datetime) -> bool:
        del now
        self.marks.append((raw_message_id, status))
        current = self._views.get(raw_message_id)
        if current is not None:
            self._views[raw_message_id] = replace(current, status=status)
        if self._log is not None:
            self._log.append(f"mark:{status}")
        return True


class FakeLlmParser:
    """Doble de `LlmParserPort`: reproduce un guion de resultados/excepciones.

    `calls` guarda `(excerpt, received_on)` de cada invocacion, para aserturar
    que nunca viaja mas que el extracto y la fecha (P1).
    """

    def __init__(self, script: list[LlmResult | Exception], *, enabled: bool = True) -> None:
        self._script = list(script)
        self.enabled = enabled
        self.calls: list[tuple[str, date]] = []

    async def parse(self, excerpt: str, received_on: date) -> LlmResult:
        self.calls.append((excerpt, received_on))
        item = self._script.pop(0)
        if isinstance(item, Exception):
            raise item
        return item


class InMemoryBudget:
    """Doble de `LlmBudgetPort`: tokens usados por `(user_id, month_key)`."""

    def __init__(self, initial: dict[tuple[UUID, str], int] | None = None) -> None:
        self._used: dict[tuple[UUID, str], int] = dict(initial or {})
        self.adds: list[tuple[UUID, str, int]] = []

    async def used(self, user_id: UUID, month_key: str) -> int:
        return self._used.get((user_id, month_key), 0)

    async def add(self, user_id: UUID, month_key: str, tokens: int) -> None:
        self.adds.append((user_id, month_key, tokens))
        key = (user_id, month_key)
        self._used[key] = self._used.get(key, 0) + tokens


@dataclass(frozen=True, slots=True)
class MetricCall:
    """Una llamada a `MetricsPort.record`, capturada para aserciones."""

    outcome: str
    bank: str | None
    channel: str
    template_id: str | None
    reason: str | None
    llm_tokens: int | None


class RecordingMetrics:
    """Doble de `MetricsPort`: guarda cada `record(...)`."""

    def __init__(self) -> None:
        self.calls: list[MetricCall] = []

    def record(  # noqa: PLR0913 - un kwarg por dimension de la metrica (spec 006 SS6)
        self,
        outcome: str,
        *,
        bank: str | None,
        channel: str,
        template_id: str | None = None,
        reason: str | None = None,
        llm_tokens: int | None = None,
    ) -> None:
        self.calls.append(MetricCall(outcome, bank, channel, template_id, reason, llm_tokens))


class RecordingPublisher:
    """Doble de `EventPublisherPort`: guarda cada evento publicado (ver `FakeGateway`)."""

    def __init__(self, *, log: list[str] | None = None) -> None:
        self.events: list[object] = []
        self._log = log

    async def publish(self, event: object) -> None:
        self.events.append(event)
        if self._log is not None:
            self._log.append(f"publish:{type(event).__name__}")


class NoopUoW:
    """Doble de `UnitOfWorkPort`: no persiste nada, solo cuenta los commits."""

    def __init__(self, *, log: list[str] | None = None) -> None:
        self.commits = 0
        self._log = log

    async def commit(self) -> None:
        self.commits += 1
        if self._log is not None:
            self._log.append("commit")


def view_from_fixture(  # noqa: PLR0913 - builder de vista con un default por campo
    fixture: EmailFixture,
    user_id: UUID,
    *,
    status: str = "pending",
    bank: str | None = "bancolombia",
    channel: str = "email",
    raw_message_id: UUID | None = None,
) -> RawMessageView:
    """`RawMessageView` a partir de un `EmailFixture` (`support.email_fixtures`)."""
    id_ = raw_message_id or uuid.uuid5(
        uuid.NAMESPACE_URL, f"{_EMAIL_FIXTURE_ID_NAMESPACE}{fixture.name}"
    )
    return RawMessageView(
        id=id_,
        user_id=user_id,
        channel=channel,
        bank=bank,
        sender=fixture.sender,
        body=fixture.body,
        status=status,
        received_at=fixture.received_at,
    )


def make_use_case(  # noqa: PLR0913 - un override por dependencia del caso de uso
    *,
    gateway: RawMessageGatewayPort | None = None,
    llm: LlmParserPort | None = None,
    budget: LlmBudgetPort | None = None,
    registry: TemplateRegistryPort | None = None,
    known_banks: frozenset[str] | None = None,
    metrics: MetricsPort | None = None,
    events: EventPublisherPort | None = None,
    clock: ClockPort | None = None,
    uow: UnitOfWorkPort | None = None,
    llm_budget_limit: int = 100_000,
    confidence_threshold: float = 0.8,
    max_excerpt_chars: int = 1500,
) -> ParseRawMessage:
    """`ParseRawMessage` con la plantilla real y fakes por defecto para lo que
    no se sobreescriba explicitamente.
    """
    return ParseRawMessage(
        gateway=gateway if gateway is not None else FakeGateway({}),
        llm=llm if llm is not None else FakeLlmParser([]),
        budget=budget if budget is not None else InMemoryBudget(),
        registry=registry if registry is not None else load_parsing_config().templates,
        known_banks=(
            known_banks if known_banks is not None else load_parsing_config().senders.known_banks()
        ),
        metrics=metrics if metrics is not None else RecordingMetrics(),
        events=events if events is not None else RecordingPublisher(),
        clock=clock if clock is not None else FixedClock(datetime(2026, 9, 21, 12, 0, tzinfo=UTC)),
        uow=uow if uow is not None else NoopUoW(),
        llm_budget_limit=llm_budget_limit,
        confidence_threshold=confidence_threshold,
        max_excerpt_chars=max_excerpt_chars,
    )
