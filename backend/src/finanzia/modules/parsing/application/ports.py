"""Ports (interfaces) que la capa application de parsing expone a infrastructure."""

from __future__ import annotations

from datetime import date, datetime
from typing import Protocol
from uuid import UUID

from finanzia.modules.parsing.application.dto import LlmResult, RawMessageView
from finanzia.modules.parsing.domain.templates import BankTemplates, TemplateMatch

# --- Lectura/transicion del raw_message (D2, D8) ------------------------------------


class RawMessageGatewayPort(Protocol):
    """Unico punto por el que parsing lee un `raw_message` y transiciona su estado.

    `get_for_parsing` nunca devuelve el cuerpo via el evento de ingestion (D2): lo
    trae con su propia lectura. `mark` es idempotente (P2): reintentar con el mismo
    `status` no debe fallar.
    """

    async def get_for_parsing(self, raw_message_id: UUID) -> RawMessageView | None: ...

    async def mark(self, raw_message_id: UUID, status: str, now: datetime) -> bool: ...


# --- LLM (spec 006 SS4.2, P1: solo excerpt + fecha) ----------------------------------


class LlmParserPort(Protocol):
    """Adapter del LLM (DeepSeek u otro). Recibe solo el extracto y la fecha de
    recepcion (P1): nunca `user_id`, remitente ni `raw_message_id`.
    """

    enabled: bool

    async def parse(self, excerpt: str, received_on: date) -> LlmResult:
        """Lanza `finanzia.modules.parsing.domain.errors.LlmUnavailable` si la
        llamada no pudo completarse (timeout/5xx/red, D11).
        """
        ...


class LlmBudgetPort(Protocol):
    """Presupuesto mensual de tokens del LLM por usuario (spec 006 SS4.2)."""

    async def used(self, user_id: UUID, month_key: str) -> int: ...

    async def add(self, user_id: UUID, month_key: str, tokens: int) -> None: ...


# --- Plantillas (coincide estructuralmente con `domain.templates.TemplateRegistry`) --


class TemplateRegistryPort(Protocol):
    """Subconjunto de `TemplateRegistry` que el caso de uso necesita."""

    def match(self, bank: str | None, excerpt: str) -> TemplateMatch | None: ...

    def bank_config(self, bank: str) -> BankTemplates | None: ...

    def known_banks(self) -> frozenset[str]: ...


# --- Observabilidad (spec 006 SS6): el caso de uso nunca loguea ----------------------


class MetricsPort(Protocol):
    """Metricas de negocio de parsing (`parsed_by_rule`, `parsed_by_llm`,
    `sent_to_review`, `discarded`). La application no puede importar `structlog`
    (R2): toda observabilidad pasa por este puerto.
    """

    def record(  # noqa: PLR0913 - un kwarg por dimension de la metrica (spec 006 SS6)
        self,
        outcome: str,
        *,
        bank: str | None,
        channel: str,
        template_id: str | None = None,
        reason: str | None = None,
        llm_tokens: int | None = None,
    ) -> None: ...


# --- Infraestructura transversal ------------------------------------------------------


class EventPublisherPort(Protocol):
    """Publicacion de eventos de dominio (`finanzia.modules.parsing.events`)."""

    async def publish(self, event: object) -> None: ...


class ClockPort(Protocol):
    """Fuente de tiempo inyectable (siempre aware, UTC)."""

    def now(self) -> datetime: ...


class UnitOfWorkPort(Protocol):
    """Confirma los cambios acumulados en la unidad de trabajo actual."""

    async def commit(self) -> None: ...


__all__ = [
    "ClockPort",
    "EventPublisherPort",
    "LlmBudgetPort",
    "LlmParserPort",
    "MetricsPort",
    "RawMessageGatewayPort",
    "TemplateRegistryPort",
    "UnitOfWorkPort",
]
