"""API publica de parsing: unico punto de entrada para otros modulos.

Facha para que `ingestion` consuma los allowlists/config de captura de
parsing (D6) y para que el worker (composition root) arme el consumer de
`ingestion.RawMessageReceived` (D7, Task 7) sin importar internals de
parsing (R4).
"""

from __future__ import annotations

from typing import Any

from finanzia.modules.parsing.domain.allowlist import NotificationDecision
from finanzia.modules.parsing.domain.errors import ParsingError
from finanzia.modules.parsing.events import ParseFailed, TransactionParsed
from finanzia.modules.parsing.infrastructure.config_loader import load_parsing_config
from finanzia.modules.parsing.infrastructure.consumers import make_raw_message_received_handler
from finanzia.modules.parsing.infrastructure.llm import build_llm_parser
from finanzia.modules.parsing.infrastructure.llm.budget_redis import RedisLlmBudget
from finanzia.modules.parsing.infrastructure.metrics import StructlogMetrics

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
]


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
