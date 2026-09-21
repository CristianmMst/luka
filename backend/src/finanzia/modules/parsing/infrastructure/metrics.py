"""Metricas de negocio de parsing via structlog (spec 006 §6).

`application` no puede importar `structlog` (R2): `StructlogMetrics` satisface
`MetricsPort` y es el unico lugar que traduce un resultado a un log.
"""

from __future__ import annotations

import structlog

_logger = structlog.get_logger("parsing")


class StructlogMetrics:
    """Implementa `MetricsPort`: un log `parsing_metric` por resultado."""

    def record(  # noqa: PLR0913 - un kwarg por dimension de la metrica (spec 006 §6)
        self,
        outcome: str,
        *,
        bank: str | None,
        channel: str,
        template_id: str | None = None,
        reason: str | None = None,
        llm_tokens: int | None = None,
    ) -> None:
        _logger.info(
            "parsing_metric",
            outcome=outcome,
            bank=bank,
            channel=channel,
            template_id=template_id,
            reason=reason,
            llm_tokens=llm_tokens,
        )


__all__ = ["StructlogMetrics"]
