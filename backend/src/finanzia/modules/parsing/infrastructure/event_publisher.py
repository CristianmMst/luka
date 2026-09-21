"""Adaptador que publica eventos de parsing en el bus compartido (spec 003 §2.3).

A diferencia de `ledger`/`ingestion` (que tragan errores de publish porque se
llaman DESPUES del commit, D8/D9 de esos modulos), en `parsing` el orden es al
reves: `ParseRawMessage` publica el evento de salida ANTES de marcar/comitear
el estado del `raw_message` (D8 de este modulo). Si tragaramos la excepcion
aqui, un fallo de Redis dejaria la fila en `pending` sin haber emitido
`TransactionParsed`/`ParseFailed` — pero el caso de uso igual seguiria
adelante y comitearia el `mark`, perdiendo el evento para siempre. Por eso
`publish` es un pass-through puro: cualquier excepcion del bus se propaga, el
caso de uso NO llega a marcar/comitear, y el `raw_message` sigue `pending`
para que el mensaje se reprocese (StreamConsumer deja el mensaje en el PEL).
"""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from finanzia.shared.events.port import EventBusPort


class BusEventPublisher:
    """Satisface `EventPublisherPort` delegando en un `EventBusPort` (Redis o memoria).

    Deliberadamente NO fail-soft (ver docstring del modulo): las excepciones
    del bus se dejan propagar.
    """

    def __init__(self, bus: EventBusPort) -> None:
        self._bus = bus

    async def publish(self, event: object) -> None:
        await self._bus.publish(event)


__all__ = ["BusEventPublisher"]
