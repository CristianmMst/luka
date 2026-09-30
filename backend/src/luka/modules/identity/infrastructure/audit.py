"""Auditoria de eventos sensibles de identity (spec 009 SS5): nunca email ni tokens."""

from uuid import UUID

import structlog


class StructlogAudit:
    """Implementacion de `AuditLogPort` sobre el logger `"audit"` de structlog."""

    def __init__(self) -> None:
        self._logger = structlog.get_logger("audit")

    def record(self, event: str, *, user_id: UUID | None = None, **attrs: str) -> None:
        # `event` es el primer parametro posicional de `BoundLogger.info` (el mensaje
        # del log): no puede repetirse como kwarg, asi que el nombre del evento de
        # auditoria *es* el mensaje (el logger ya se distingue por nombre: "audit").
        self._logger.info(
            event,
            user_id=str(user_id) if user_id else None,
            **attrs,
        )
