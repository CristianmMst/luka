"""Adaptador que delega en `parsing.public` para resolver banco/aceptacion (D6).

Es el unico cruce de infraestructura entre `ingestion` y `parsing` (R4): ingestion
consume las allowlists de remitentes/paquetes de captura sin importar los internals
de parsing.
"""

from __future__ import annotations

from typing import Any

from luka.modules.ingestion.application.dto import BankDecision
from luka.modules.parsing import public as parsing_public


class ParsingSenderPolicy:
    """Satisface `SenderPolicyPort` delegando en `luka.modules.parsing.public`."""

    def bank_for_email_sender(self, sender: str) -> str | None:
        return parsing_public.bank_for_email_sender(sender)

    def bank_for_notification(self, package: str, channel: str, title: str | None) -> BankDecision:
        decision = parsing_public.bank_for_notification(package, channel, title)
        return BankDecision(accepted=decision.accepted, bank=decision.bank)

    def capture_config(self) -> dict[str, Any]:
        """Config cruda de captura (`GET /v1/config/capture`, spec 006 §3.1, D6)."""
        return parsing_public.capture_config()


__all__ = ["ParsingSenderPolicy"]
