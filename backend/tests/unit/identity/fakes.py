"""Dobles de prueba de identity: repos en memoria y ports fake (sin infraestructura)."""

from dataclasses import replace
from datetime import datetime
from uuid import UUID, uuid4

# Reutilizado como `ClockPort`: ya expone `now()` y `advance(delta)` (referenciado en `__all__`).
from support.clock import FixedClock

from luka.modules.identity.domain.entities import GoogleIdentity, RefreshToken, User
from luka.modules.identity.domain.errors import InvalidGoogleToken

__all__ = [
    "FakeAccessTokenIssuer",
    "FakeGmailCleanup",
    "FakeGoogleVerifier",
    "FixedClock",
    "InMemoryRefreshTokenRepo",
    "InMemoryUserRepo",
    "NoopUoW",
    "RecordingAudit",
    "RecordingPublisher",
    "SequenceTokenGenerator",
]


class InMemoryUserRepo:
    """Doble en memoria de `UserRepositoryPort`."""

    def __init__(self) -> None:
        self._by_id: dict[UUID, User] = {}
        self._by_sub: dict[str, UUID] = {}

    async def get_by_google_sub(self, sub: str) -> User | None:
        user_id = self._by_sub.get(sub)
        return self._by_id.get(user_id) if user_id is not None else None

    async def get_by_id(self, id: UUID) -> User | None:
        return self._by_id.get(id)

    async def add(self, user: User) -> None:
        self._by_id[user.id] = user
        self._by_sub[user.google_sub] = user.id

    async def update_profile(self, user: User) -> None:
        self._by_id[user.id] = user
        self._by_sub[user.google_sub] = user.id

    async def delete(self, id: UUID) -> None:
        user = self._by_id.pop(id, None)
        if user is not None:
            self._by_sub.pop(user.google_sub, None)


class InMemoryRefreshTokenRepo:
    """Doble en memoria de `RefreshTokenRepositoryPort`: solo guarda hashes."""

    def __init__(self) -> None:
        self._by_id: dict[UUID, RefreshToken] = {}
        self._by_hash: dict[str, UUID] = {}

    async def get_by_hash_for_update(self, token_hash: str) -> RefreshToken | None:
        token_id = self._by_hash.get(token_hash)
        return self._by_id.get(token_id) if token_id is not None else None

    async def add(self, token: RefreshToken) -> None:
        self._by_id[token.id] = token
        self._by_hash[token.token_hash] = token.id

    async def revoke(self, token_id: UUID, now: datetime) -> None:
        token = self._by_id.get(token_id)
        if token is not None and token.revoked_at is None:
            self._by_id[token_id] = replace(token, revoked_at=now)

    async def revoke_family(self, family_id: UUID, now: datetime) -> None:
        for token in list(self._by_id.values()):
            if token.family_id == family_id and token.revoked_at is None:
                self._by_id[token.id] = replace(token, revoked_at=now)

    async def revoke_all_for_user(self, user_id: UUID, now: datetime) -> None:
        for token in list(self._by_id.values()):
            if token.user_id == user_id and token.revoked_at is None:
                self._by_id[token.id] = replace(token, revoked_at=now)


class FakeGoogleVerifier:
    """Doble de `GoogleIdTokenVerifierPort`: mapea `id_token` -> `GoogleIdentity`."""

    def __init__(self, identities: dict[str, GoogleIdentity]) -> None:
        self._identities = identities

    async def verify(self, id_token: str) -> GoogleIdentity:
        identity = self._identities.get(id_token)
        if identity is None:
            raise InvalidGoogleToken
        return identity


class SequenceTokenGenerator:
    """Doble de `TokenGeneratorPort`: refresh tokens deterministas, ids uuid4."""

    def __init__(self) -> None:
        self._counter = 0

    def new_refresh_token(self) -> str:
        self._counter += 1
        return f"refresh-{self._counter}"

    def new_id(self) -> UUID:
        return uuid4()


class FakeAccessTokenIssuer:
    """Doble de `AccessTokenIssuerPort`: JWT fake, TTL fijo de 900s."""

    def issue(self, user_id: UUID, now: datetime) -> tuple[str, int]:
        return f"access-for-{user_id}", 900


class RecordingAudit:
    """Doble de `AuditLogPort`: guarda cada llamada para inspeccion en tests."""

    def __init__(self) -> None:
        self.events: list[tuple[str, UUID | None, dict[str, str]]] = []

    def record(self, event: str, *, user_id: UUID | None = None, **attrs: str) -> None:
        self.events.append((event, user_id, attrs))


class NoopUoW:
    """Doble de `UnitOfWorkPort`: no persiste nada, solo cuenta los commits."""

    def __init__(self) -> None:
        self.commits = 0

    async def commit(self) -> None:
        self.commits += 1


class FakeGmailCleanup:
    """Doble de `GmailCleanupPort`: anota a quien se le desconecto Gmail."""

    def __init__(self) -> None:
        self.disconnected: list[UUID] = []

    async def disconnect(self, user_id: UUID) -> None:
        self.disconnected.append(user_id)


class RecordingPublisher:
    """Doble de `EventPublisherPort`: guarda los eventos publicados."""

    def __init__(self) -> None:
        self.events: list[object] = []

    async def publish(self, event: object) -> None:
        self.events.append(event)
