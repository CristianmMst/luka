"""Router HTTP de identity: `/auth/*` (publico) y `/me` (autenticado) (spec 005 SS2)."""

from uuid import UUID

from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse

from finanzia.modules.identity.application.use_cases.delete_account import DeleteAccount
from finanzia.modules.identity.application.use_cases.export_data import ExportUserData
from finanzia.modules.identity.application.use_cases.get_me import GetMe
from finanzia.modules.identity.application.use_cases.login_with_google import LoginWithGoogle
from finanzia.modules.identity.application.use_cases.logout import Logout
from finanzia.modules.identity.application.use_cases.refresh_session import RefreshSession
from finanzia.modules.identity.infrastructure.api.deps import (
    get_current_user_id,
    get_delete_account_use_case,
    get_export_use_case,
    get_login_use_case,
    get_logout_use_case,
    get_me_use_case,
    get_refresh_use_case,
)
from finanzia.modules.identity.infrastructure.api.schemas import (
    GoogleLoginRequest,
    LogoutRequest,
    MeResponse,
    RefreshRequest,
    SessionResponse,
    UserResponse,
)

router = APIRouter(tags=["identity"])


@router.post("/auth/google", status_code=status.HTTP_200_OK)
async def login_with_google(
    body: GoogleLoginRequest,
    use_case: LoginWithGoogle = Depends(get_login_use_case),
) -> SessionResponse:
    """Verifica el `id_token` de Google y abre (o continua) la sesion del usuario."""
    result = await use_case.execute(body.id_token, body.device_info)
    return SessionResponse(
        access_token=result.access_token,
        refresh_token=result.refresh_token,
        expires_in=result.expires_in,
        user=UserResponse.from_user(result.user),
    )


@router.post("/auth/refresh", status_code=status.HTTP_200_OK)
async def refresh_session(
    body: RefreshRequest,
    use_case: RefreshSession = Depends(get_refresh_use_case),
) -> SessionResponse:
    """Rota el refresh token presentado y emite un nuevo par de tokens."""
    result = await use_case.execute(body.refresh_token, body.device_info)
    return SessionResponse(
        access_token=result.access_token,
        refresh_token=result.refresh_token,
        expires_in=result.expires_in,
        user=UserResponse.from_user(result.user),
    )


@router.post("/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    body: LogoutRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: Logout = Depends(get_logout_use_case),
) -> None:
    """Revoca el refresh token presentado; siempre responde 204."""
    await use_case.execute(user_id, body.refresh_token)


@router.get("/me", status_code=status.HTTP_200_OK)
async def get_me(
    user_id: UUID = Depends(get_current_user_id),
    use_case: GetMe = Depends(get_me_use_case),
) -> MeResponse:
    """Perfil del usuario autenticado y el estado de sus conexiones externas."""
    result = await use_case.execute(user_id)
    return MeResponse.build(result.user, result.connections)


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_me(
    user_id: UUID = Depends(get_current_user_id),
    use_case: DeleteAccount = Depends(get_delete_account_use_case),
) -> None:
    """Borra la cuenta y todos sus datos al instante; irreversible (RF-11.3)."""
    await use_case.execute(user_id)


@router.get("/me/export", status_code=status.HTTP_200_OK)
async def export_me(
    user_id: UUID = Depends(get_current_user_id),
    use_case: ExportUserData = Depends(get_export_use_case),
) -> JSONResponse:
    """Todos los datos del usuario en JSON, como archivo descargable (RF-11.2)."""
    document = await use_case.execute(user_id)
    return JSONResponse(
        document,
        headers={"Content-Disposition": 'attachment; filename="finanzia-export.json"'},
    )
