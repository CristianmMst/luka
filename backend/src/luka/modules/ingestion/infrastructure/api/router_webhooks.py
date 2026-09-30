"""Webhook publico de Pub/Sub para los avisos push de Gmail (spec 005 §4, F3.4).

Sin Bearer de la app, sin rate limit por usuario y sin idempotencia: lo
autentica el token OIDC de Google que Pub/Sub manda en `Authorization`. El
token se verifica **antes** de leer el cuerpo.

Respuestas: 204 si se encolo el sync o si no hay nada que hacer (cuenta
desconocida, conexion inactiva o envelope ilegible), 403 si el token no
verifica y 503 si no se pudo encolar (Pub/Sub reintenta).

Un envelope malformado responde 204 y no 400 a proposito: el token ya probo que
el mensaje viene de nuestra suscripcion, y cualquier respuesta distinta de 2xx
hace que Pub/Sub lo reintente con backoff hasta que venza la retencion (7 dias
por defecto). Reintentar no arregla un cuerpo ilegible; se loguea y se descarta.

Nunca se loguea el `emailAddress` del aviso ni el token.
"""

from __future__ import annotations

import structlog
from fastapi import APIRouter, Depends, Request, Response, status

from luka.modules.ingestion.application.ports import PushTokenVerifierPort
from luka.modules.ingestion.application.use_cases.gmail_sync import HandleGmailPush
from luka.modules.ingestion.domain.errors import InvalidPushEnvelope, InvalidPushToken
from luka.modules.ingestion.domain.gmail_push import decode_push_envelope
from luka.modules.ingestion.infrastructure.api.deps import (
    get_handle_gmail_push,
    get_push_verifier,
)

_logger = structlog.get_logger()

router = APIRouter(prefix="/webhooks", tags=["ingestion"])


def _push_token(authorization: str | None) -> str:
    scheme, _, token = (authorization or "").partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise InvalidPushToken("sin token")
    return token.strip()


@router.post("/gmail", status_code=status.HTTP_204_NO_CONTENT)
async def gmail_push(
    request: Request,
    verifier: PushTokenVerifierPort = Depends(get_push_verifier),
    use_case: HandleGmailPush = Depends(get_handle_gmail_push),
) -> Response:
    """Verifica el OIDC, decodifica el aviso y encola `sync_gmail`; nunca parsea aqui."""
    await verifier.verify(_push_token(request.headers.get("authorization")))
    try:
        notification = decode_push_envelope(await request.body())
    except InvalidPushEnvelope:
        _logger.warning("gmail_push_ignored", reason="malformed_envelope")
        return Response(status_code=status.HTTP_204_NO_CONTENT)
    jobs = await use_case.execute(notification)
    _logger.info("gmail_push_received", jobs_enqueued=jobs)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


__all__ = ["router"]
