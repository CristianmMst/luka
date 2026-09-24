"""Ports (interfaces) que la capa application de identity expone a infrastructure."""

from datetime import datetime
from typing import Protocol
from uuid import UUID

from finanzia.modules.identity.domain.entities import GoogleIdentity, RefreshToken, User


class UserRepositoryPort(Protocol):
    """Persistencia de usuarios."""

    async def get_by_google_sub(self, sub: str) -> User | None: ...

    async def get_by_id(self, id: UUID) -> User | None: ...

    async def add(self, user: User) -> None: ...

    async def update_profile(self, user: User) -> None: ...


class RefreshTokenRepositoryPort(Protocol):
    """Persistencia de refresh tokens: siempre por hash, nunca por valor en claro."""

    async def get_by_hash_for_update(self, token_hash: str) -> RefreshToken | None: ...

    async def add(self, token: RefreshToken) -> None: ...

    async def revoke(self, token_id: UUID, now: datetime) -> None: ...

    async def revoke_family(self, family_id: UUID, now: datetime) -> None: ...

    async def revoke_all_for_user(self, user_id: UUID, now: datetime) -> None: ...


class GoogleIdTokenVerifierPort(Protocol):
    """Verifica un `id_token` de Google contra sus claves publicas."""

    async def verify(self, id_token: str) -> GoogleIdentity: ...


class ClockPort(Protocol):
    """Fuente de tiempo inyectable (siempre aware, UTC)."""

    def now(self) -> datetime: ...


class TokenGeneratorPort(Protocol):
    """Generacion de identificadores y refresh tokens opacos."""

    def new_refresh_token(self) -> str: ...

    def new_id(self) -> UUID: ...


class AccessTokenIssuerPort(Protocol):
    """Emision del access JWT de corta duracion."""

    def issue(self, user_id: UUID, now: datetime) -> tuple[str, int]: ...


class AuditLogPort(Protocol):
    """Registro de auditoria. Los llamadores nunca deben pasar email ni tokens."""

    def record(self, event: str, *, user_id: UUID | None = None, **attrs: str) -> None: ...


class GmailConnectionStatusPort(Protocol):
    """Estado de la conexion Gmail del usuario, que vive en ingestion (spec 005 §2)."""

    async def gmail_status(self, user_id: UUID) -> str:
        """`active` / `revoked` / `error`, o `none` si el usuario no conecto Gmail."""
        ...


class UnitOfWorkPort(Protocol):
    """Confirma los cambios acumulados en la unidad de trabajo actual."""

    async def commit(self) -> None: ...


__all__ = [
    "AccessTokenIssuerPort",
    "AuditLogPort",
    "ClockPort",
    "GmailConnectionStatusPort",
    "GoogleIdTokenVerifierPort",
    "RefreshTokenRepositoryPort",
    "TokenGeneratorPort",
    "UnitOfWorkPort",
    "UserRepositoryPort",
]
