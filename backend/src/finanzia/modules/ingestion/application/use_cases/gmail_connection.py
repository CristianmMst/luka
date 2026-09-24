"""Casos de uso de la conexion Gmail: conectar, desconectar y estado (F3.3, spec 005 §3).

Ninguno devuelve ni guarda el refresh token en claro: solo pasa por
`TokenCipherPort` (spec 009 §3). Las llamadas a Google ocurren antes de tocar la
base, asi que no queda una transaccion abierta mientras se espera la red.
"""

from __future__ import annotations

from dataclasses import replace
from uuid import UUID

from finanzia.modules.ingestion.application.dto import (
    GMAIL_DISCONNECTED,
    DisconnectResult,
    GmailConnectionView,
)
from finanzia.modules.ingestion.application.ports import (
    ClockPort,
    GmailClientPort,
    GmailConnectionRepositoryPort,
    TokenCipherPort,
    UnitOfWorkPort,
)
from finanzia.modules.ingestion.domain.entities import GmailConnection
from finanzia.modules.ingestion.domain.enums import GmailConnectionStatus
from finanzia.modules.ingestion.domain.errors import (
    GmailAuthRevoked,
    GmailError,
    GmailTokenUndecryptable,
    InvalidServerAuthCode,
)


def _view(connection: GmailConnection) -> GmailConnectionView:
    return GmailConnectionView(
        status=connection.status.value,
        email=connection.email,
        last_sync_at=connection.last_sync_at,
        watch_expires_at=connection.watch_expires_at,
    )


class ConnectGmail:
    """Canjea el `serverAuthCode`, crea el watch y guarda la conexion cifrada (AC-1.2).

    Si el canje falla no se guarda nada. Si el canje sale bien pero el watch no,
    la conexion se guarda igual (el refresh token ya no se puede volver a pedir
    con el mismo codigo) con `status=error`, o `revoked` si Google invalido el
    token recien emitido; la renovacion de watch (cron) o una reconexion la
    recuperan.
    """

    def __init__(  # noqa: PLR0913 - un parametro por port + el topic
        self,
        *,
        repo: GmailConnectionRepositoryPort,
        gmail: GmailClientPort,
        cipher: TokenCipherPort,
        clock: ClockPort,
        uow: UnitOfWorkPort,
        topic: str,
    ) -> None:
        self._repo = repo
        self._gmail = gmail
        self._cipher = cipher
        self._clock = clock
        self._uow = uow
        self._topic = topic

    async def execute(self, user_id: UUID, server_auth_code: str) -> GmailConnectionView:
        try:
            refresh_token, email = await self._gmail.exchange_code(server_auth_code)
        except GmailAuthRevoked as exc:
            raise InvalidServerAuthCode from exc

        now = self._clock.now()
        connection = GmailConnection(
            user_id=user_id,
            email=email,
            refresh_token_enc=self._cipher.encrypt(user_id, refresh_token),
            history_id=None,
            watch_expires_at=None,
            status=GmailConnectionStatus.ACTIVE,
            last_sync_at=None,
            created_at=now,
            updated_at=now,
        )
        try:
            access_token = await self._gmail.access_token(refresh_token)
            history_id, expires_at = await self._gmail.watch(access_token, self._topic)
        except GmailAuthRevoked:
            connection = replace(connection, status=GmailConnectionStatus.REVOKED)
        except GmailError:
            connection = replace(connection, status=GmailConnectionStatus.ERROR)
        else:
            connection = replace(connection, history_id=history_id, watch_expires_at=expires_at)

        await self._repo.upsert(connection)
        await self._uow.commit()
        return _view(connection)


class DisconnectGmail:
    """Detiene el watch, revoca el token en Google y borra la conexion (AC-11.1).

    Google es best effort: cualquier fallo (red, token ya revocado, blob que no
    descifra) se tolera y la fila se borra igual. Las transacciones del usuario
    no se tocan.
    """

    def __init__(
        self,
        *,
        repo: GmailConnectionRepositoryPort,
        gmail: GmailClientPort,
        cipher: TokenCipherPort,
        uow: UnitOfWorkPort,
    ) -> None:
        self._repo = repo
        self._gmail = gmail
        self._cipher = cipher
        self._uow = uow

    async def execute(self, user_id: UUID) -> DisconnectResult:
        connection = await self._repo.get(user_id)
        if connection is None:
            return DisconnectResult(existed=False, remote_cleanup=False)

        remote_cleanup = False
        try:
            refresh_token = self._cipher.decrypt(user_id, connection.refresh_token_enc)
        except GmailTokenUndecryptable:
            refresh_token = None
        if refresh_token is not None:
            remote_cleanup = await self._cleanup_remote(refresh_token)

        await self._repo.delete(user_id)
        await self._uow.commit()
        return DisconnectResult(existed=True, remote_cleanup=remote_cleanup)

    async def _cleanup_remote(self, refresh_token: str) -> bool:
        """`stop` y luego `revoke`; el revoke se intenta aunque el stop falle."""
        stopped = True
        try:
            access_token = await self._gmail.access_token(refresh_token)
            await self._gmail.stop(access_token)
        except GmailError:
            stopped = False
        try:
            await self._gmail.revoke(refresh_token)
        except GmailError:
            return False
        return stopped


class GetGmailStatus:
    """Estado de la conexion Gmail del usuario (`disconnected` si no tiene)."""

    def __init__(self, *, repo: GmailConnectionRepositoryPort) -> None:
        self._repo = repo

    async def execute(self, user_id: UUID) -> GmailConnectionView:
        connection = await self._repo.get(user_id)
        if connection is None:
            return GmailConnectionView(
                status=GMAIL_DISCONNECTED, email=None, last_sync_at=None, watch_expires_at=None
            )
        return _view(connection)


__all__ = ["ConnectGmail", "DisconnectGmail", "GetGmailStatus"]
