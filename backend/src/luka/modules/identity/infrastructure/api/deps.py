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

from luka.modules.identity.application.ports import GoogleIdTokenVerifierPort
from luka.modules.identity.application.use_cases.delete_account import DeleteAccount
from luka.modules.identity.application.use_cases.export_data import ExportUserData
from luka.modules.identity.application.use_cases.get_me import GetMe
from luka.modules.identity.application.use_cases.login_with_google import LoginWithGoogle
from luka.modules.identity.application.use_cases.logout import Logout
from luka.modules.identity.application.use_cases.refresh_session import RefreshSession
from luka.modules.identity.infrastructure.access_token_issuer import JwtAccessTokenIssuer
from luka.modules.identity.infrastructure.audit import StructlogAudit
from luka.modules.identity.infrastructure.data_export import ModulesDataExport
from luka.modules.identity.infrastructure.event_publisher import BusEventPublisher
from luka.modules.identity.infrastructure.gmail_status import (
    IngestionGmailCleanup,
    IngestionGmailStatus,
)
from luka.modules.identity.infrastructure.repositories import (
    SqlAlchemyRefreshTokenRepository,
    SqlAlchemyUserRepository,
)
from luka.modules.identity.infrastructure.token_generator import SecretsTokenGenerator
from luka.modules.identity.infrastructure.uow import SqlAlchemyUnitOfWork
from luka.shared.clock import SystemClock
from luka.shared.security import bearer_token, decode_access_token
from luka.shared.settings import Settings


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


def get_google_verifier(request: Request) -> GoogleIdTokenVerifierPort:
    """Devuelve el verificador de Google construido una unica vez en el lifespan.

    `GoogleAuthIdTokenVerifier` mantiene una sesion HTTP con cache de claves publicas
    (`cachecontrol`); construirlo por request tiraria ese cache en cada login. Se crea
    una sola vez en `app.py` (`app.state.google_verifier`) y esta dependencia solo
    lo expone.
    """
    return request.app.state.google_verifier  # type: ignore[no-any-return]


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
    """Ensambla `GetMe` con el repositorio de usuarios y el estado Gmail de ingestion."""
    return GetMe(users=SqlAlchemyUserRepository(session), gmail=IngestionGmailStatus(session))


def get_delete_account_use_case(
    request: Request,
    session: AsyncSession = Depends(get_session),
    clock: SystemClock = Depends(get_clock),
) -> DeleteAccount:
    """Ensambla `DeleteAccount`: Gmail por ingestion, bus y repositorios SQLAlchemy."""
    return DeleteAccount(
        users=SqlAlchemyUserRepository(session),
        tokens=SqlAlchemyRefreshTokenRepository(session),
        gmail=IngestionGmailCleanup(
            session, request.app.state.gmail_client, request.app.state.settings
        ),
        events=BusEventPublisher(request.app.state.event_bus),
        audit=StructlogAudit(),
        clock=clock,
        ids=SecretsTokenGenerator(),
        uow=SqlAlchemyUnitOfWork(session),
    )


def get_export_use_case(
    session: AsyncSession = Depends(get_session),
    clock: SystemClock = Depends(get_clock),
) -> ExportUserData:
    """Ensambla `ExportUserData` con los datos de ledger e ingestion."""
    return ExportUserData(
        users=SqlAlchemyUserRepository(session),
        data=ModulesDataExport(session),
        audit=StructlogAudit(),
        clock=clock,
    )


def _build_issuer(settings: Settings) -> JwtAccessTokenIssuer:
    return JwtAccessTokenIssuer(
        settings.jwt_secret.get_secret_value(),
        timedelta(seconds=settings.jwt_access_ttl_seconds),
    )
