"""Caso de uso: login con Google (spec 009 SS2.1, AC-1.1)."""

from dataclasses import replace
from datetime import timedelta

from finanzia.modules.identity.application.dto import SessionResult
from finanzia.modules.identity.application.ports import (
    AccessTokenIssuerPort,
    AuditLogPort,
    ClockPort,
    GoogleIdTokenVerifierPort,
    RefreshTokenRepositoryPort,
    TokenGeneratorPort,
    UnitOfWorkPort,
    UserRepositoryPort,
)
from finanzia.modules.identity.domain.entities import User, UserStatus
from finanzia.modules.identity.domain.errors import EmailNotVerified
from finanzia.modules.identity.domain.sessions import hash_refresh_token, new_family

REFRESH_TTL = timedelta(days=60)


class LoginWithGoogle:
    """Verifica un `id_token` de Google y abre (o continua) la sesion del usuario."""

    def __init__(  # noqa: PLR0913 - un puerto por dependencia externa, ver 009 SS2.1
        self,
        *,
        verifier: GoogleIdTokenVerifierPort,
        users: UserRepositoryPort,
        tokens: RefreshTokenRepositoryPort,
        clock: ClockPort,
        token_generator: TokenGeneratorPort,
        issuer: AccessTokenIssuerPort,
        audit: AuditLogPort,
        uow: UnitOfWorkPort,
        refresh_ttl: timedelta = REFRESH_TTL,
    ) -> None:
        self._verifier = verifier
        self._users = users
        self._tokens = tokens
        self._clock = clock
        self._token_generator = token_generator
        self._issuer = issuer
        self._audit = audit
        self._uow = uow
        self._refresh_ttl = refresh_ttl

    async def execute(self, id_token: str, device_info: str | None) -> SessionResult:
        """Autentica con Google, crea/actualiza el usuario y abre una nueva sesion."""
        identity = await self._verifier.verify(id_token)
        if not identity.email_verified:
            raise EmailNotVerified

        now = self._clock.now()
        user = await self._users.get_by_google_sub(identity.sub)
        if user is None:
            user = User(
                id=self._token_generator.new_id(),
                google_sub=identity.sub,
                email=identity.email,
                display_name=identity.name,
                photo_url=identity.picture,
                status=UserStatus.ACTIVE,
                consents={},
                created_at=now,
                updated_at=now,
            )
            await self._users.add(user)
        elif (
            user.email != identity.email
            or user.display_name != identity.name
            or user.photo_url != identity.picture
        ):
            user = replace(
                user,
                email=identity.email,
                display_name=identity.name,
                photo_url=identity.picture,
                updated_at=now,
            )
            await self._users.update_profile(user)

        raw_refresh = self._token_generator.new_refresh_token()
        refresh_token = new_family(
            id=self._token_generator.new_id(),
            user_id=user.id,
            token_hash=hash_refresh_token(raw_refresh),
            family_id=self._token_generator.new_id(),
            now=now,
            ttl=self._refresh_ttl,
            device_info=device_info,
        )
        await self._tokens.add(refresh_token)
        await self._uow.commit()

        access_token, expires_in = self._issuer.issue(user.id, now)
        self._audit.record("login", user_id=user.id)
        return SessionResult(
            access_token=access_token,
            refresh_token=raw_refresh,
            expires_in=expires_in,
            user=user,
        )
