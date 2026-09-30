"""Router HTTP de notifications: `/devices/push-token` (spec 005 SS10)."""

from collections.abc import AsyncIterator
from uuid import UUID

from fastapi import APIRouter, Depends, Request, status
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.ext.asyncio import AsyncSession

from luka.modules.identity.public import get_current_user_id
from luka.modules.notifications.application.use_cases.push_tokens import (
    RegisterPushToken,
    UnregisterPushToken,
)
from luka.modules.notifications.domain.entities import TOKEN_MAX, Platform
from luka.modules.notifications.infrastructure.id_generator import UuidGenerator
from luka.modules.notifications.infrastructure.repositories import SqlAlchemyDeviceTokenRepository
from luka.modules.notifications.infrastructure.uow import SqlAlchemyUnitOfWork
from luka.shared.clock import SystemClock

router = APIRouter(tags=["notifications"], dependencies=[Depends(get_current_user_id)])


class PushTokenRequest(BaseModel):
    """Body de `PUT /devices/push-token`."""

    model_config = ConfigDict(extra="forbid")

    token: str = Field(min_length=1, max_length=TOKEN_MAX)
    platform: Platform


class DeletePushTokenRequest(BaseModel):
    """Body de `DELETE /devices/push-token`."""

    model_config = ConfigDict(extra="forbid")

    token: str = Field(min_length=1, max_length=TOKEN_MAX)


async def get_session(request: Request) -> AsyncIterator[AsyncSession]:
    """Sesion por request (copia local, R4)."""
    async with request.app.state.session_factory() as session:
        try:
            yield session
        finally:
            if session.in_transaction():
                await session.rollback()


def get_register_use_case(session: AsyncSession = Depends(get_session)) -> RegisterPushToken:
    return RegisterPushToken(
        tokens=SqlAlchemyDeviceTokenRepository(session),
        clock=SystemClock(),
        ids=UuidGenerator(),
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_unregister_use_case(session: AsyncSession = Depends(get_session)) -> UnregisterPushToken:
    return UnregisterPushToken(
        tokens=SqlAlchemyDeviceTokenRepository(session), uow=SqlAlchemyUnitOfWork(session)
    )


@router.put("/devices/push-token", status_code=status.HTTP_204_NO_CONTENT)
async def register_push_token(
    body: PushTokenRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: RegisterPushToken = Depends(get_register_use_case),
) -> None:
    """Registra (o reasigna) el token de FCM de este dispositivo al usuario."""
    await use_case.execute(user_id, body.token, body.platform)


@router.delete("/devices/push-token", status_code=status.HTTP_204_NO_CONTENT)
async def unregister_push_token(
    body: DeletePushTokenRequest,
    user_id: UUID = Depends(get_current_user_id),
    use_case: UnregisterPushToken = Depends(get_unregister_use_case),
) -> None:
    """Borra el token si es del usuario; si no existe, igual 204 (idempotente)."""
    await use_case.execute(user_id, body.token)
