"""API publica de notifications: unico punto de entrada para otros modulos (spec 011)."""

from __future__ import annotations

import base64
import binascii
import json
from typing import TYPE_CHECKING, Any

from luka.modules.notifications.application.use_cases.push_tokens import PurgeStaleTokens
from luka.modules.notifications.infrastructure.consumers import make_payment_due_soon_handler
from luka.modules.notifications.infrastructure.fcm_sender import (
    FcmPushSender,
    ServiceAccountTokenProvider,
)
from luka.modules.notifications.infrastructure.repositories import SqlAlchemyDeviceTokenRepository
from luka.modules.notifications.infrastructure.uow import SqlAlchemyUnitOfWork

if TYPE_CHECKING:
    from uuid import UUID

    import httpx
    from sqlalchemy.ext.asyncio import AsyncSession

    from luka.modules.notifications.application.ports import ClockPort
    from luka.shared.settings import Settings

__all__ = [
    "build_push_sender",
    "decode_service_account",
    "export_user_data",
    "make_payment_due_soon_handler",
    "purge_stale_tokens",
]

_REQUIRED_KEYS = ("project_id", "client_email", "private_key")


def decode_service_account(encoded: str) -> dict[str, Any]:
    """JSON de la cuenta de servicio en base64 -> dict; `ValueError` si no sirve."""
    try:
        info = json.loads(base64.b64decode(encoded, validate=True))
    except (binascii.Error, ValueError) as exc:
        msg = "fcm_credentials_json debe ser el JSON de la cuenta de servicio en base64"
        raise ValueError(msg) from exc
    if not isinstance(info, dict) or any(not info.get(key) for key in _REQUIRED_KEYS):
        msg = "fcm_credentials_json no trae project_id, client_email y private_key"
        raise ValueError(msg)
    return info


def build_push_sender(settings: Settings, client: httpx.AsyncClient) -> FcmPushSender | None:
    """Adapter FCM si `LUKA_FCM_CREDENTIALS_JSON` esta definida; si no, `None` (sin push)."""
    if settings.fcm_credentials_json is None:
        return None
    info = decode_service_account(settings.fcm_credentials_json.get_secret_value())
    return FcmPushSender(
        client, ServiceAccountTokenProvider(info), project_id=str(info["project_id"])
    )


async def purge_stale_tokens(session: AsyncSession, clock: ClockPort) -> int:
    """Cron diario: borra los tokens sin registrarse en 270 dias (spec 004 SS6)."""
    use_case = PurgeStaleTokens(
        tokens=SqlAlchemyDeviceTokenRepository(session),
        clock=clock,
        uow=SqlAlchemyUnitOfWork(session),
    )
    return await use_case.execute()


async def export_user_data(session: AsyncSession, user_id: UUID) -> dict[str, object]:
    """Dispositivos con push para `GET /v1/me/export`: plataforma y fechas, nunca el token."""
    tokens = await SqlAlchemyDeviceTokenRepository(session).list_for_user(user_id)
    return {
        "push_devices": [
            {
                "platform": t.platform.value,
                "created_at": t.created_at.isoformat(),
                "last_seen_at": t.last_seen_at.isoformat(),
            }
            for t in tokens
        ]
    }
