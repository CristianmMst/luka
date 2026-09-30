"""Router HTTP de ingestion: `GET /config/capture` (spec 006 §3.1, D6)."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Response

from luka.modules.ingestion.infrastructure.api.deps import (
    get_capture_config,
    get_current_user_id,
)
from luka.modules.ingestion.infrastructure.api.schemas import CaptureConfigResponse

router = APIRouter(
    prefix="/config", tags=["ingestion"], dependencies=[Depends(get_current_user_id)]
)


@router.get("/capture")
async def get_config_capture(
    response: Response,
    config: CaptureConfigResponse = Depends(get_capture_config),
) -> CaptureConfigResponse:
    """Config remota de captura para el cliente Android (spec 006 §3.1).

    Cacheable un rato en el cliente (`Cache-Control: private, max-age=3600`):
    excepcion documentada a `no-store` porque el payload no contiene datos de
    usuario (controller ruling 3; `SecurityHeadersMiddleware` no pisa esta
    cabecera si la ruta ya la establecio).
    """
    response.headers["Cache-Control"] = "private, max-age=3600"
    return config


__all__ = ["router"]
