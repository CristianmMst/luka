"""Wiring de dependencias FastAPI de ingestion: unico lugar que ensambla adapters.

Los routers quedan deliberadamente "delgados" (controller ruling 2). `get_session`
es una copia local (no una importacion) de la de ledger/identity: cada modulo es
independiente salvo `public.py`/`events.py` (import-linter R4).
"""

from __future__ import annotations

from collections.abc import AsyncIterator, Sequence
from typing import TYPE_CHECKING
from uuid import UUID

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from finanzia.modules.identity.public import get_current_user_id
from finanzia.modules.ingestion import public as ingestion_public
from finanzia.modules.ingestion.infrastructure.api.schemas import CaptureConfigResponse
from finanzia.modules.ingestion.infrastructure.sender_policy import ParsingSenderPolicy
from finanzia.shared.clock import SystemClock

if TYPE_CHECKING:
    from finanzia.modules.ingestion.application.dto import BatchResult, NotificationItemInput

__all__ = ["get_current_user_id"]


async def get_session(request: Request) -> AsyncIterator[AsyncSession]:
    """Sesion por request desde `app.state.session_factory`; rollback si queda abierta."""
    async with request.app.state.session_factory() as session:
        try:
            yield session
        finally:
            if session.in_transaction():
                await session.rollback()


class IngestBatchRunner:
    """Ejecuta `ingestion.public.ingest_notifications_batch` con la config del proceso.

    Envuelve la sesion/event bus/reloj/settings ya resueltos por FastAPI para que
    el router solo llame `runner.run(user_id, items)` (controller ruling 2).
    """

    def __init__(self, session: AsyncSession, request: Request) -> None:
        self._session = session
        self._request = request

    async def run(self, user_id: UUID, items: Sequence[NotificationItemInput]) -> BatchResult:
        settings = self._request.app.state.settings
        return await ingestion_public.ingest_notifications_batch(
            self._session,
            self._request.app.state.event_bus,
            SystemClock(),
            user_id,
            items,
            retention_days=settings.raw_message_retention_days,
            body_max_bytes=settings.raw_message_body_max_bytes,
        )


def get_ingest_batch_runner(
    request: Request, session: AsyncSession = Depends(get_session)
) -> IngestBatchRunner:
    return IngestBatchRunner(session, request)


def get_capture_config() -> CaptureConfigResponse:
    """Config remota de captura (spec 006 §3.1) adaptada a la forma plana de la API."""
    raw = ParsingSenderPolicy().capture_config()
    return CaptureConfigResponse(
        version=raw["version"],
        banking_apps=[str(app["package"]) for app in raw["banking_apps"]],
        messages_apps=[str(app) for app in raw["messages_apps"]],
        sms_sender_patterns=[str(entry["pattern"]) for entry in raw["sms_sender_patterns"]],
        email_senders={bank: list(patterns) for bank, patterns in raw["email_senders"].items()},
    )
