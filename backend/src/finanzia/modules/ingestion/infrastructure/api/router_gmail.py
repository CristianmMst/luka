"""Router HTTP de ingestion: conexion Gmail (spec 005 §3, F3.3; AC-1.2, AC-11.1).

Cada ruta opera solo sobre la conexion del usuario del Bearer. Los logs de
auditoria (spec 009 §5) llevan el `user_id` de los contextvars y el estado,
nunca el email, el codigo ni tokens.
"""

from __future__ import annotations

from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, status

from finanzia.modules.ingestion.application.use_cases.gmail_connection import (
    ConnectGmail,
    DisconnectGmail,
    GetGmailStatus,
)
from finanzia.modules.ingestion.infrastructure.api.deps import (
    get_connect_gmail,
    get_current_user_id,
    get_disconnect_gmail,
    get_gmail_status,
)
from finanzia.modules.ingestion.infrastructure.api.schemas import (
    GmailConnectRequest,
    GmailConnectResponse,
    GmailStatusResponse,
)

_audit = structlog.get_logger("audit")

router = APIRouter(prefix="/gmail", tags=["ingestion"], dependencies=[Depends(get_current_user_id)])


@router.post("/connect", status_code=status.HTTP_200_OK)
async def connect_gmail(
    body: GmailConnectRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: ConnectGmail = Depends(get_connect_gmail),
) -> GmailConnectResponse:
    """Canjea el `server_auth_code`, guarda el refresh token cifrado y crea el watch.

    Si el watch falla, la conexion queda guardada con `status=error` (200 igual).
    """
    view = await use_case.execute(user_id, body.server_auth_code)
    _audit.info("gmail_connected", connection_status=view.status)
    return GmailConnectResponse.model_validate(view, from_attributes=True)


@router.delete("/connect", status_code=status.HTTP_204_NO_CONTENT)
async def disconnect_gmail(
    user_id: UUID = Depends(get_current_user_id),
    use_case: DisconnectGmail = Depends(get_disconnect_gmail),
) -> None:
    """Detiene el watch, revoca el token (best effort) y borra la conexion; siempre 204."""
    result = await use_case.execute(user_id)
    if result.existed:
        _audit.info("gmail_disconnected", remote_cleanup=result.remote_cleanup)


@router.get("/status", status_code=status.HTTP_200_OK)
async def gmail_status(
    user_id: UUID = Depends(get_current_user_id),
    use_case: GetGmailStatus = Depends(get_gmail_status),
) -> GmailStatusResponse:
    """Estado de la conexion (`disconnected` si no hay); nunca devuelve el token."""
    view = await use_case.execute(user_id)
    return GmailStatusResponse.model_validate(view, from_attributes=True)


__all__ = ["router"]
