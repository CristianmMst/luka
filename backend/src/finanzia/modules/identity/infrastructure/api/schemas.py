"""Schemas Pydantic de la API de identity (spec 005 SS2, controller ruling 4)."""

from collections.abc import Mapping
from datetime import datetime
from typing import Literal, Self
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from finanzia.modules.identity.domain.entities import User


class GoogleLoginRequest(BaseModel):
    """Body de `POST /auth/google`."""

    model_config = ConfigDict(extra="forbid")

    id_token: str = Field(min_length=20, max_length=4096)
    device_info: str | None = Field(default=None, max_length=200)


class RefreshRequest(BaseModel):
    """Body de `POST /auth/refresh`."""

    model_config = ConfigDict(extra="forbid")

    refresh_token: str = Field(min_length=20, max_length=512)
    device_info: str | None = Field(default=None, max_length=200)


class LogoutRequest(BaseModel):
    """Body de `POST /auth/logout`."""

    model_config = ConfigDict(extra="forbid")

    refresh_token: str = Field(min_length=1, max_length=512)


class UserResponse(BaseModel):
    """Representacion publica de un usuario."""

    id: UUID
    email: str
    display_name: str | None
    photo_url: str | None
    status: str
    created_at: datetime

    @classmethod
    def from_user(cls, user: User) -> Self:
        return cls(
            id=user.id,
            email=user.email,
            display_name=user.display_name,
            photo_url=user.photo_url,
            status=user.status.value,
            created_at=user.created_at,
        )


class SessionResponse(BaseModel):
    """Respuesta de `POST /auth/google` y `POST /auth/refresh`."""

    access_token: str
    refresh_token: str
    token_type: Literal["Bearer"] = "Bearer"  # noqa: S105 - esquema HTTP fijo, no un secreto
    expires_in: int
    user: UserResponse


class MeResponse(BaseModel):
    """Respuesta de `GET /me`: perfil + consentimientos + estado de conexiones."""

    id: UUID
    email: str
    display_name: str | None
    photo_url: str | None
    status: str
    created_at: datetime
    consents: dict[str, datetime]
    connections: dict[str, str]

    @classmethod
    def build(cls, user: User, connections: Mapping[str, str]) -> Self:
        return cls(
            id=user.id,
            email=user.email,
            display_name=user.display_name,
            photo_url=user.photo_url,
            status=user.status.value,
            created_at=user.created_at,
            consents=dict(user.consents),
            connections=dict(connections),
        )
