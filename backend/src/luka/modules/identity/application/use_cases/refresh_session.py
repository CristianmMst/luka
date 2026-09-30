"""Caso de uso: refrescar sesion con rotacion y deteccion de reuso (spec 009 AC-1.4)."""

from datetime import timedelta

from luka.modules.identity.application.dto import SessionResult
from luka.modules.identity.application.ports import (
    AccessTokenIssuerPort,
    AuditLogPort,
    ClockPort,
    RefreshTokenRepositoryPort,
    TokenGeneratorPort,
    UnitOfWorkPort,
    UserRepositoryPort,
)
from luka.modules.identity.domain.errors import (
    RefreshTokenExpired,
    RefreshTokenInvalid,
    RefreshTokenReused,
    UserNotFound,
)
from luka.modules.identity.domain.sessions import (
    RefreshDecision,
    evaluate_refresh,
    hash_refresh_token,
    rotate,
)

REFRESH_TTL = timedelta(days=60)


class RefreshSession:
    """Evalua un refresh token candidato y, si es valido, rota la sesion."""

    def __init__(  # noqa: PLR0913 - un puerto por dependencia externa, ver 009 SS2.2
        self,
        *,
        users: UserRepositoryPort,
        tokens: RefreshTokenRepositoryPort,
        clock: ClockPort,
        token_generator: TokenGeneratorPort,
        issuer: AccessTokenIssuerPort,
        audit: AuditLogPort,
        uow: UnitOfWorkPort,
        refresh_ttl: timedelta = REFRESH_TTL,
    ) -> None:
        self._users = users
        self._tokens = tokens
        self._clock = clock
        self._token_generator = token_generator
        self._issuer = issuer
        self._audit = audit
        self._uow = uow
        self._refresh_ttl = refresh_ttl

    async def execute(self, raw_refresh: str, device_info: str | None) -> SessionResult:
        """Rota `raw_refresh` si es valido; revoca y falla ante reuso o vencimiento."""
        now = self._clock.now()
        token = await self._tokens.get_by_hash_for_update(hash_refresh_token(raw_refresh))
        decision = evaluate_refresh(token, now)

        if decision is RefreshDecision.UNKNOWN:
            raise RefreshTokenInvalid

        assert token is not None  # noqa: S101 - UNKNOWN ya descartado arriba

        if decision is RefreshDecision.REUSED:
            await self._tokens.revoke_family(token.family_id, now)
            await self._uow.commit()
            self._audit.record("refresh_reuse_detected", user_id=token.user_id)
            raise RefreshTokenReused(token.family_id)

        if decision is RefreshDecision.EXPIRED:
            await self._tokens.revoke(token.id, now)
            await self._uow.commit()
            raise RefreshTokenExpired

        new_raw = self._token_generator.new_refresh_token()
        old, new_token = rotate(
            token,
            now=now,
            new_id=self._token_generator.new_id(),
            new_hash=hash_refresh_token(new_raw),
            ttl=self._refresh_ttl,
        )
        await self._tokens.revoke(old.id, now)
        await self._tokens.add(new_token)
        await self._uow.commit()

        user = await self._users.get_by_id(token.user_id)
        if user is None:
            raise UserNotFound

        access_token, expires_in = self._issuer.issue(user.id, now)
        return SessionResult(
            access_token=access_token,
            refresh_token=new_raw,
            expires_in=expires_in,
            user=user,
        )
