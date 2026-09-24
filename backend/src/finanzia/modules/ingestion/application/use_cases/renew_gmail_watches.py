"""Caso de uso: renovacion diaria de watches de Gmail (F3.5, spec 006 §2.1).

Selecciona las conexiones `active` cuyo `watch_expires_at` vence dentro de las
proximas 48h (`ClockPort`) y por cada una: descifra el refresh token, pide un
access token y renueva el watch (`GmailClientPort.watch`). Un fallo en una
conexion nunca corta las demas (mismo patron que `RequeuePendingRawMessages`).

Errores por conexion:
- Token guardado que no descifra (`GmailTokenUndecryptable`): la conexion pasa
  a `error`.
- `GmailAuthRevoked` (refresh token revocado): la conexion pasa a `revoked`.
- Cualquier otro `GmailError` (transitorio, rechazo): la conexion pasa a
  `error` (mismo patron que `ConnectGmail`: no vale la pena distinguir mas
  fino aqui, el proximo dia el usuario reconecta o el problema se resuelve
  solo). El error transitorio queda contado en `errored`, que el cron loguea.

El cursor (`history_id`) nunca retrocede: `GREATEST(actual, nuevo)` en SQL
(spec 006 §2.1), igual que `SyncGmail`/`record_sync`. Devuelve solo contadores
(nunca el email de la cuenta ni el refresh token, P1/P6); el cron del worker
los loguea.
"""

from __future__ import annotations

from datetime import timedelta
from typing import TYPE_CHECKING

from finanzia.modules.ingestion.application.dto import RenewWatchesSummary
from finanzia.modules.ingestion.domain.enums import GmailConnectionStatus
from finanzia.modules.ingestion.domain.errors import (
    GmailAuthRevoked,
    GmailError,
    GmailTokenUndecryptable,
)

if TYPE_CHECKING:
    from finanzia.modules.ingestion.application.ports import (
        ClockPort,
        GmailClientPort,
        GmailConnectionRepositoryPort,
        TokenCipherPort,
        UnitOfWorkPort,
    )
    from finanzia.modules.ingestion.domain.entities import GmailConnection

#: Ventana de renovacion: todo watch que vence antes de 48h se renueva (spec 006 §2.1).
EXPIRING_WITHIN_DEFAULT = timedelta(hours=48)


class RenewGmailWatches:
    """Cron diario: renueva el watch de Gmail de toda conexion activa por vencer."""

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

    async def execute(
        self, *, expiring_within: timedelta = EXPIRING_WITHIN_DEFAULT
    ) -> RenewWatchesSummary:
        now = self._clock.now()
        connections = await self._repo.list_active_expiring_before(now + expiring_within)
        # Cierra la lectura antes de llamar a Google (mismo patron que SyncGmail).
        await self._uow.commit()

        renewed = revoked = errored = 0
        for connection in connections:
            try:
                refresh_token = self._cipher.decrypt(
                    connection.user_id, connection.refresh_token_enc
                )
            except GmailTokenUndecryptable:
                await self._mark(connection, GmailConnectionStatus.ERROR)
                errored += 1
                continue

            try:
                access_token = await self._gmail.access_token(refresh_token)
                history_id, watch_expires_at = await self._gmail.watch(access_token, self._topic)
            except GmailAuthRevoked:
                await self._mark(connection, GmailConnectionStatus.REVOKED)
                revoked += 1
            except GmailError:
                await self._mark(connection, GmailConnectionStatus.ERROR)
                errored += 1
            else:
                await self._repo.renew_watch(
                    connection.user_id,
                    connection.email,
                    history_id,
                    watch_expires_at,
                    self._clock.now(),
                )
                await self._uow.commit()
                renewed += 1

        return RenewWatchesSummary(renewed=renewed, revoked=revoked, errored=errored)

    async def _mark(self, connection: GmailConnection, status: GmailConnectionStatus) -> None:
        await self._repo.mark_status(
            connection.user_id, connection.email, status, self._clock.now()
        )
        await self._uow.commit()


__all__ = ["EXPIRING_WITHIN_DEFAULT", "RenewGmailWatches"]
