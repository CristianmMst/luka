"""Metricas de ingesta via structlog (P1/P6: nunca sender/title/text/body).

`application` no puede importar `structlog` (R2); este helper vive en
`infrastructure` y traduce un `IngestOutcome` ya resuelto a una linea de log,
sin volver a tocar ningun dato crudo del mensaje. `bank` se incluye para
`accepted`/`duplicate` (spec 006 §5, contadores por banco/canal); `Discarded`
nunca lo tiene porque el mensaje se descarto antes de resolver un banco.
"""

from __future__ import annotations

import structlog

from luka.modules.ingestion.application.dto import Accepted, Discarded, Duplicate, IngestOutcome

_logger = structlog.get_logger()


def log_ingest_outcome(outcome: IngestOutcome, channel: str) -> None:
    """Emite `parsing_metric` con el resultado de una ingesta (spec 006 §4.4, §6)."""
    if isinstance(outcome, Accepted):
        _logger.info("parsing_metric", outcome="accepted", channel=channel, bank=outcome.bank)
    elif isinstance(outcome, Duplicate):
        _logger.info(
            "parsing_metric",
            outcome="duplicate",
            channel=channel,
            bank=outcome.bank,
            republished=outcome.republished,
        )
    elif isinstance(outcome, Discarded):
        _logger.info("parsing_metric", outcome="discarded", channel=channel, reason=outcome.reason)


__all__ = ["log_ingest_outcome"]
