"""Caso de uso: parsear un `raw_message` (plantilla -> LLM -> revision).

Orquestacion pura (spec 006 SS4/SS4.2): sin infraestructura, sin logging (la
application no puede importar `structlog`, R2). Toda observabilidad pasa por
`MetricsPort`.
"""

from __future__ import annotations

from uuid import UUID

from finanzia.modules.parsing.application.dto import (
    Discarded,
    Failed,
    LlmInvalidOutput,
    Parsed,
    ParseOutcome,
    RawMessageView,
    Skipped,
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
from finanzia.modules.parsing.domain.enums import ParseFailureReason
from finanzia.modules.parsing.domain.errors import LlmUnavailable, TemplateExtractionInvalid
from finanzia.modules.parsing.domain.excerpt import extract_excerpt, looks_monetary
from finanzia.modules.parsing.domain.llm_validation import Rejected, validate_extraction
from finanzia.modules.parsing.domain.parsed import ParsedTransaction
from finanzia.modules.parsing.events import ParseFailed, TransactionParsed, deterministic_event_id

_PENDING = "pending"


class ParseRawMessage:
    """Convierte un `raw_message` en `TransactionParsed`/`ParseFailed`/descarte.

    Idempotente (P2): un `raw_message` que ya no este `pending` produce `Skipped`
    sin publicar nada. El `event_id` de salida es determinista por `(outcome,
    raw_message_id)` (D8), asi que reprocesar el mismo mensaje con el mismo
    resultado no crea eventos duplicados aguas abajo.
    """

    def __init__(  # noqa: PLR0913 - un puerto por dependencia externa
        self,
        *,
        gateway: RawMessageGatewayPort,
        llm: LlmParserPort,
        budget: LlmBudgetPort,
        registry: TemplateRegistryPort,
        metrics: MetricsPort,
        events: EventPublisherPort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
        known_banks: frozenset[str],
        llm_budget_limit: int,
        confidence_threshold: float,
        max_excerpt_chars: int = 1500,
    ) -> None:
        """`known_banks` son los bancos ACEPTABLES en la salida del LLM: el
        allowlist de remitentes (`SenderAllowlist.known_banks()`, 6 bancos), no
        los bancos con plantilla (`TemplateRegistryPort.known_banks()`, hoy solo
        `bancolombia`). El prompt le pide al modelo esos 6 slugs y el CHECK de
        `raw_messages.bank`/`transactions.bank` los acepta; validar contra las
        plantillas rechazaria como `llm_invalid_output` todo lo que no sea
        Bancolombia. Lo inyecta el composition root (`infrastructure/consumers.py`)
        para no acoplar la application al loader de config (R2).
        """
        self._gateway = gateway
        self._llm = llm
        self._budget = budget
        self._registry = registry
        self._metrics = metrics
        self._events = events
        self._clock = clock
        self._uow = uow
        self._known_banks = known_banks
        self._llm_budget_limit = llm_budget_limit
        self._confidence_threshold = confidence_threshold
        self._max_excerpt_chars = max_excerpt_chars

    async def execute(self, raw_message_id: UUID) -> ParseOutcome:
        view = await self._gateway.get_for_parsing(raw_message_id)
        if view is None:
            return Skipped("not_found")
        if view.status != _PENDING:
            return Skipped("not_pending")

        if view.body is None:
            return await self._emit_failed(view, ParseFailureReason.BODY_PURGED, {})

        cfg = self._registry.bank_config(view.bank) if view.bank else None
        excerpt = extract_excerpt(
            view.body,
            cfg.relevant_line_prefix if cfg is not None else None,
            self._max_excerpt_chars,
        )

        match = self._registry.match(view.bank, excerpt)
        template_id: str | None = None
        parsed: ParsedTransaction | None = None
        if match is not None:
            try:
                parsed = match.to_parsed(view.received_at)
                template_id = match.template.id
            except TemplateExtractionInvalid:
                parsed = None

        if parsed is not None:
            return await self._emit_parsed(view, parsed, template_id=template_id, llm_tokens=None)

        return await self._parse_with_llm(view, excerpt)

    async def _parse_with_llm(  # noqa: PLR0911 - un return por rama del pipeline (spec 006 SS4.2)
        self, view: RawMessageView, excerpt: str
    ) -> ParseOutcome:
        if not looks_monetary(excerpt):
            return await self._emit_failed(view, ParseFailureReason.NO_TEMPLATE, {})
        if not self._llm.enabled:
            return await self._emit_failed(view, ParseFailureReason.LLM_DISABLED, {})

        now = self._clock.now()
        month_key = now.strftime("%Y%m")
        used = await self._budget.used(view.user_id, month_key)
        if used >= self._llm_budget_limit:
            return await self._emit_failed(view, ParseFailureReason.LLM_BUDGET_EXCEEDED, {})

        received_on = view.received_at.date()
        try:
            result = await self._llm.parse(excerpt, received_on)
        except LlmUnavailable:
            return await self._emit_failed(view, ParseFailureReason.LLM_ERROR, {})

        total_tokens = result.tokens
        if isinstance(result, LlmInvalidOutput):
            try:
                result = await self._llm.parse(excerpt, received_on)
            except LlmUnavailable:
                await self._budget.add(view.user_id, month_key, total_tokens)
                return await self._emit_failed(view, ParseFailureReason.LLM_ERROR, {})
            total_tokens += result.tokens
            if isinstance(result, LlmInvalidOutput):
                await self._budget.add(view.user_id, month_key, total_tokens)
                return await self._emit_failed(view, ParseFailureReason.LLM_INVALID_JSON, {})

        await self._budget.add(view.user_id, month_key, total_tokens)

        validated = validate_extraction(
            result.extraction,
            view.received_at,
            self._known_banks,
            self._confidence_threshold,
        )
        if isinstance(validated, Rejected):
            if validated.reason == "not_transaction":
                return await self._discard(view)
            reason = validated.reason
            assert isinstance(reason, ParseFailureReason)  # noqa: S101 - narrowing pyright
            return await self._emit_failed(view, reason, validated.partial)

        return await self._emit_parsed(view, validated, template_id=None, llm_tokens=total_tokens)

    async def _discard(self, view: RawMessageView) -> Discarded:
        now = self._clock.now()
        await self._gateway.mark(view.id, "discarded", now)
        await self._uow.commit()
        self._metrics.record("discarded", bank=view.bank, channel=view.channel)
        return Discarded()

    async def _emit_parsed(
        self,
        view: RawMessageView,
        parsed: ParsedTransaction,
        *,
        template_id: str | None,
        llm_tokens: int | None,
    ) -> Parsed:
        now = self._clock.now()
        event_id = deterministic_event_id("parsed", view.id)
        await self._events.publish(
            TransactionParsed(
                event_id=event_id,
                occurred_at=now,
                raw_message_id=view.id,
                user_id=view.user_id,
                channel=view.channel,
                bank=parsed.bank,
                amount=parsed.amount,
                direction=parsed.direction,
                transaction_occurred_at=parsed.occurred_at,
                last4=parsed.last4,
                merchant=parsed.merchant,
                suggested_category=parsed.suggested_category,
                parsed_by=parsed.parsed_by,
                confidence=parsed.confidence,
                received_at=view.received_at,
            )
        )
        await self._gateway.mark(view.id, "parsed", now)
        await self._uow.commit()
        outcome = "parsed_by_rule" if template_id is not None else "parsed_by_llm"
        self._metrics.record(
            outcome,
            bank=parsed.bank,
            channel=view.channel,
            template_id=template_id,
            llm_tokens=llm_tokens,
        )
        return Parsed(parsed_by=parsed.parsed_by, transaction_event_id=event_id)

    async def _emit_failed(
        self,
        view: RawMessageView,
        reason: ParseFailureReason,
        partial_extract: dict[str, str],
    ) -> Failed:
        now = self._clock.now()
        await self._events.publish(
            ParseFailed(
                event_id=deterministic_event_id("failed", view.id),
                occurred_at=now,
                raw_message_id=view.id,
                user_id=view.user_id,
                channel=view.channel,
                bank=view.bank,
                reason=reason,
                partial_extract=partial_extract,
                received_at=view.received_at,
            )
        )
        await self._gateway.mark(view.id, "failed", now)
        await self._uow.commit()
        self._metrics.record(
            "sent_to_review", bank=view.bank, channel=view.channel, reason=reason.value
        )
        return Failed(reason)


__all__ = ["ParseRawMessage"]
