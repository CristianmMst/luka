"""Wiring de dependencias FastAPI de identity: unico lugar que ensambla adapters.

El router queda deliberadamente "delgado": solo llama a los casos de uso obtenidos
aqui (controller ruling 5).
"""

from collections.abc import AsyncIterator
from datetime import timedelta
from uuid import UUID

import structlog
from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from finanzia.modules.identity.application.ports import GoogleIdTokenVerifierPort
from finanzia.modules.identity.application.use_cases.get_me import GetMe
from finanzia.modules.identity.application.use_cases.login_with_google import LoginWithGoogle
from finanzia.modules.identity.application.use_cases.logout import Logout
from finanzia.modules.identity.application.use_cases.refresh_session import RefreshSession
from finanzia.modules.identity.infrastructure.access_token_issuer import JwtAccessTokenIssuer
from finanzia.modules.identity.infrastructure.audit import StructlogAudit
from finanzia.modules.identity.infrastructure.google_verifier import (
    FakeGoogleIdTokenVerifier,
    GoogleAuthIdTokenVerifier,
)
from finanzia.modules.identity.infrastructure.repositories import (
    SqlAlchemyRefreshTokenRepository,
    SqlAlchemyUserRepository,
)
from finanzia.modules.identity.infrastructure.token_generator import SecretsTokenGenerator
from finanzia.modules.identity.infrastructure.uow import SqlAlchemyUnitOfWork
from finanzia.shared.clock import SystemClock
from finanzia.shared.security import bearer_token, decode_access_token
from finanzia.shared.settings import Settings


def get_settings_dep(request: Request) -> Settings:
    """Devuelve los `Settings` cableados en `app.state` durante el lifespan."""
    return request.app.state.settings  # type: ignore[no-any-return]


async def get_session(request: Request) -> AsyncIterator[AsyncSession]:
    """Sesion por request desde `app.state.session_factory`; rollback si queda abierta."""
    async with request.app.state.session_factory() as session:
        try:
            yield session
        finally:
            if session.in_transaction():
                await session.rollback()


def get_clock() -> SystemClock:
    """Reloj real del sistema (UTC, aware)."""
    return SystemClock()


def get_google_verifier(
    settings: Settings = Depends(get_settings_dep),
) -> GoogleIdTokenVerifierPort:
    """Selecciona el verificador de Google segun `settings.google_verifier`."""
    if settings.google_verifier == "fake":
        return FakeGoogleIdTokenVerifier()
    return GoogleAuthIdTokenVerifier(settings.google_client_id)


async def get_current_user_id(
    request: Request,
    settings: Settings = Depends(get_settings_dep),
) -> UUID:
    """Extrae y valida el `user_id` del access JWT; liga contextvars para logging."""
    token = bearer_token(request.headers.get("authorization"))
    claims = decode_access_token(token, settings.jwt_secret.get_secret_value())
    structlog.contextvars.bind_contextvars(user_id=str(claims.sub))
    request.state.user_id = str(claims.sub)
    return claims.sub


def get_login_use_case(
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings_dep),
    verifier: GoogleIdTokenVerifierPort = Depends(get_google_verifier),
    clock: SystemClock = Depends(get_clock),
) -> LoginWithGoogle:
    """Ensambla `LoginWithGoogle` con los adapters SQLAlchemy/Google/JWT."""
    return LoginWithGoogle(
        verifier=verifier,
        users=SqlAlchemyUserRepository(session),
        tokens=SqlAlchemyRefreshTokenRepository(session),
        clock=clock,
        token_generator=SecretsTokenGenerator(),
        issuer=_build_issuer(settings),
        audit=StructlogAudit(),
        uow=SqlAlchemyUnitOfWork(session),
        refresh_ttl=timedelta(days=settings.refresh_ttl_days),
    )


def get_refresh_use_case(
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings_dep),
    clock: SystemClock = Depends(get_clock),
) -> RefreshSession:
    """Ensambla `RefreshSession` con los adapters SQLAlchemy/JWT."""
    return RefreshSession(
        users=SqlAlchemyUserRepository(session),
        tokens=SqlAlchemyRefreshTokenRepository(session),
        clock=clock,
        token_generator=SecretsTokenGenerator(),
        issuer=_build_issuer(settings),
        audit=StructlogAudit(),
        uow=SqlAlchemyUnitOfWork(session),
        refresh_ttl=timedelta(days=settings.refresh_ttl_days),
    )


def get_logout_use_case(
    session: AsyncSession = Depends(get_session),
    clock: SystemClock = Depends(get_clock),
) -> Logout:
    """Ensambla `Logout` con el repositorio SQLAlchemy de refresh tokens."""
    return Logout(
        tokens=SqlAlchemyRefreshTokenRepository(session),
        clock=clock,
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_me_use_case(session: AsyncSession = Depends(get_session)) -> GetMe:
    """Ensambla `GetMe` con el repositorio SQLAlchemy de usuarios."""
    return GetMe(users=SqlAlchemyUserRepository(session))


def _build_issuer(settings: Settings) -> JwtAccessTokenIssuer:
    return JwtAccessTokenIssuer(
        settings.jwt_secret.get_secret_value(),
        timedelta(seconds=settings.jwt_access_ttl_seconds),
    )
