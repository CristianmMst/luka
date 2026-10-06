"""API publica de parsing: unico punto de entrada para otros modulos.

Facha para que `ingestion` consuma los allowlists/config de captura de
parsing (D6) y para que el worker (composition root) arme el consumer de
`ingestion.RawMessageReceived` (D7, Task 7) sin importar internals de
parsing (R4).
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from luka.modules.parsing.domain.allowlist import NotificationDecision
from luka.modules.parsing.domain.errors import ParsingError, TemplateExtractionInvalid
from luka.modules.parsing.domain.excerpt import extract_excerpt
from luka.modules.parsing.events import ParseFailed, TransactionParsed, deterministic_event_id
from luka.modules.parsing.infrastructure.config_loader import load_parsing_config
from luka.modules.parsing.infrastructure.consumers import make_raw_message_received_handler
from luka.modules.parsing.infrastructure.llm import build_llm_parser
from luka.modules.parsing.infrastructure.llm.budget_redis import RedisLlmBudget
from luka.modules.parsing.infrastructure.metrics import StructlogMetrics

if TYPE_CHECKING:
    from datetime import datetime
    from uuid import UUID

__all__ = [
    "NotificationDecision",
    "ParseFailed",
    "ParsingError",
    "RedisLlmBudget",
    "StructlogMetrics",
    "TransactionParsed",
    "bank_for_email_sender",
    "bank_for_notification",
    "build_llm_parser",
    "capture_config",
    "load_parsing_config",
    "make_raw_message_received_handler",
    "parse_with_templates",
    "person_transfer_parsed_by",
]


def person_transfer_parsed_by() -> frozenset[str]:
    """`parsed_by` de las plantillas de envio/recibo entre personas (spec 004 §4.1)."""
    return load_parsing_config().templates.person_parsed_by()


def bank_for_email_sender(sender: str) -> str | None:
    """Banco cuyo remitente/dominio matchea `sender`, o `None` si ninguno (AC-2.4)."""
    return load_parsing_config().senders.bank_for_email_sender(sender)


def bank_for_notification(package: str, channel: str, title: str | None) -> NotificationDecision:
    """Decide si una notificacion/SMS Android se acepta y con que banco (spec 006 §3.2)."""
    return load_parsing_config().capture.bank_for_notification(package, channel, title)


def capture_config() -> dict[str, Any]:
    """Config cruda de captura (`capture.yaml`) + mapa de remitentes por banco.

    Es el cuerpo de `GET /v1/config/capture` (ingestion, spec 006 §3.1): la
    config YAML tal cual, mas `email_senders` (bancos -> patrones de
    remitente) para que el cliente Android pueda validar remitentes de
    correo sin duplicar la lista.
    """
    config = load_parsing_config()
    return {
        **config.capture_raw,
        "email_senders": {bank: list(patterns) for bank, patterns in config.senders.banks.items()},
    }


def parse_with_templates(  # noqa: PLR0913 - un parametro por campo del mensaje crudo
    *,
    raw_message_id: UUID,
    user_id: UUID,
    channel: str,
    bank: str | None,
    body: str,
    received_at: datetime,
    now: datetime,
) -> TransactionParsed | None:
    """Re-parsea un mensaje ya capturado solo con plantillas (sin LLM ni bus): el
    mismo `TransactionParsed` que publicaria el pipeline, o `None` si ninguna
    plantilla lo extrae. Lo usa `luka.tools.split_merged_captures` (spec 004 SS3).
    """
    registry = load_parsing_config().templates
    cfg = registry.bank_config(bank) if bank else None
    excerpt = extract_excerpt(body, cfg.relevant_line_prefix if cfg is not None else None)
    match = registry.match(bank, excerpt)
    if match is None:
        return None
    try:
        parsed = match.to_parsed(received_at)
    except TemplateExtractionInvalid:
        return None
    return TransactionParsed(
        event_id=deterministic_event_id("parsed", raw_message_id),
        occurred_at=now,
        raw_message_id=raw_message_id,
        user_id=user_id,
        channel=channel,
        bank=parsed.bank,
        amount=parsed.amount,
        direction=parsed.direction,
        transaction_occurred_at=parsed.occurred_at,
        last4=parsed.last4,
        merchant=parsed.merchant,
        suggested_category=parsed.suggested_category,
        parsed_by=parsed.parsed_by,
        confidence=parsed.confidence,
        received_at=received_at,
        merchant_is_person=parsed.merchant_is_person,
    )
