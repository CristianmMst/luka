"""Configuracion de logging estructurado (structlog) y redaccion de PII (spec 009 SS5).

`FORBIDDEN_LOG_KEYS` es la unica fuente de verdad de claves prohibidas: la usan tanto
el procesador `redact_forbidden_keys` en runtime como `tests/ci/test_log_hygiene.py`
en tiempo de CI (analisis estatico de llamadas de log).
"""

import logging
from typing import Any

import structlog

from luka.shared.settings import Settings

FORBIDDEN_LOG_KEYS: frozenset[str] = frozenset(
    {
        "email",
        # Gmail (F3.3/F3.4): la cuenta del aviso push, el remitente/asunto del
        # correo y el codigo de autorizacion nunca se loguean (spec 009 §5).
        "email_address",
        "sender",
        "subject",
        "server_auth_code",
        "amount",
        "merchant",
        "description",
        "notes",
        "body",
        "text",
        "title",
        "token",
        "id_token",
        "access_token",
        "refresh_token",
        "token_hash",
        "payload",
        "q",
        "authorization",
    }
)

_CONFIGURED_ATTR = "_luka_logging_configured"


def redact_forbidden_keys(
    logger: object, method_name: str, event_dict: dict[str, Any]
) -> dict[str, Any]:
    """Reemplaza el valor de claves prohibidas por `"[redacted]"` (spec 009 SS5)."""
    del logger, method_name
    redacted_keys = [key for key in event_dict if key in FORBIDDEN_LOG_KEYS]
    for key in redacted_keys:
        event_dict[key] = "[redacted]"
    if redacted_keys:
        event_dict["redacted_keys"] = redacted_keys
    return event_dict


def configure_logging(settings: Settings) -> None:
    """Configura structlog + `logging` estandar; idempotente (no duplica handlers)."""
    root_logger = logging.getLogger()
    if getattr(root_logger, _CONFIGURED_ATTR, False):
        return

    shared_processors: list[Any] = [
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        redact_forbidden_keys,
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
    ]
    renderer = (
        structlog.processors.JSONRenderer()
        if settings.log_json
        else structlog.dev.ConsoleRenderer()
    )

    structlog.configure(
        processors=[*shared_processors, structlog.stdlib.ProcessorFormatter.wrap_for_formatter],
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )

    formatter = structlog.stdlib.ProcessorFormatter(
        foreign_pre_chain=shared_processors,
        processors=[
            structlog.stdlib.ProcessorFormatter.remove_processors_meta,
            renderer,
        ],
    )
    handler = logging.StreamHandler()
    handler.setFormatter(formatter)

    root_logger.handlers = [handler]
    root_logger.setLevel(settings.log_level)

    access_logger = logging.getLogger("uvicorn.access")
    access_logger.handlers = []
    access_logger.propagate = False
    access_logger.setLevel(logging.CRITICAL)

    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    # httpx/httpcore loguean la URL cruda en INFO (`HTTP Request: GET <url>`): lleva ids
    # de mensaje de Gmail, `startHistoryId`, `pageToken` y `q` (spec 009 §5).
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)

    setattr(root_logger, _CONFIGURED_ATTR, True)
