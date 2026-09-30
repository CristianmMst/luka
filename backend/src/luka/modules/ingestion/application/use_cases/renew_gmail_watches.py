"""Caso de uso: renovacion diaria de watches de Gmail (F3.5, spec 006 §2.1).

Selecciona las conexiones cuyo watch toca renovar (`list_renewable_before`):
`active` que vencen dentro de las proximas 48h (`ClockPort`) y `error` sin watch
o por vencer, porque este cron es la via de recuperacion del estado `error`.
Por cada una: descifra el refresh token, pide un access token y renueva el watch
(`GmailClientPort.watch`). Un fallo en una conexion nunca corta las demas (mismo
patron que `RequeuePendingRawMessages`).

Resultado por conexion:
- Exito: `watch_expires_at` nuevo y la conexion queda `active`.
- Token guardado que no descifra (`GmailTokenUndecryptable`): pasa a `error`.
- `GmailAuthRevoked` (refresh token revocado): pasa a `revoked`.
- `GmailTransientError` (red, 5xx, 429, cuota): el estado no cambia; la ventana
  de 48h da otro intento en la corrida siguiente. Se cuenta en `deferred`.
- Cualquier otro `GmailError` (rechazo permanente): pasa a `error`.

El cursor (`history_id`) **no** se adelanta al `historyId` que devuelve el watch
(el actual del buzon): eso saltaria los correos aun no sincronizados. Solo siembra
un cursor nulo (spec 006 §2.1). Devuelve solo contadores (nunca el email de la
cuenta ni el refresh token, P1/P6); el cron del worker los loguea.
"""

from __future__ import annotations

from datetime import timedelta
from typing import TYPE_CHECKING

from luka.modules.ingestion.application.dto import RenewWatchesSummary
from luka.modules.ingestion.domain.enums import GmailConnectionStatus
from luka.modules.ingestion.domain.errors import (
    GmailAuthRevoked,
    GmailError,
    GmailTokenUndecryptable,
    GmailTransientError,
)

if TYPE_CHECKING:
    from luka.modules.ingestion.application.ports import (
        ClockPort,
        GmailClientPort,
        GmailConnectionRepositoryPort,
        TokenCipherPort,
        UnitOfWorkPort,
    )
    from luka.modules.ingestion.domain.entities import GmailConnection

#: Ventana de renovacion: todo watch que vence antes de 48h se renueva (spec 006 §2.1).
EXPIRING_WITHIN_DEFAULT = timedelta(hours=48)


class RenewGmailWatches:
    """Cron diario: renueva el watch de Gmail por vencer y recupera las conexiones `error`."""

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
        connections = await self._repo.list_renewable_before(now + expiring_within)
        # Cierra la lectura antes de llamar a Google (mismo patron que SyncGmail).
        await self._uow.commit()

        renewed = revoked = errored = deferred = 0
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
            except GmailTransientError:
                deferred += 1
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

        return RenewWatchesSummary(
            renewed=renewed, revoked=revoked, errored=errored, deferred=deferred
        )

    async def _mark(self, connection: GmailConnection, status: GmailConnectionStatus) -> None:
        await self._repo.mark_status(
            connection.user_id, connection.email, status, self._clock.now()
        )
        await self._uow.commit()


__all__ = ["EXPIRING_WITHIN_DEFAULT", "RenewGmailWatches"]
