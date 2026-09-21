"""Allowlists de captura: remitentes de correo y apps/paquetes Android (spec 006
§2.2/§3.1, D6). Puro (stdlib solo, P3); la config YAML se carga en
`parsing/infrastructure/config_loader.py`.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from email.utils import parseaddr
from typing import Any, cast

from finanzia.modules.parsing.domain.errors import TemplateConfigError


@dataclass(frozen=True, slots=True)
class NotificationDecision:
    """Resultado de evaluar una notificacion/SMS contra `CaptureConfig`."""

    accepted: bool
    bank: str | None


def _extract_address(sender: str) -> str:
    """Extrae la direccion de un remitente `Nombre <addr>` o `addr` (stdlib `email.utils`)."""
    _, address = parseaddr(sender)
    return (address or sender).strip().lower()


@dataclass(frozen=True, slots=True)
class SenderAllowlist:
    """Lista blanca de remitentes de correo por banco (spec 006 §2.2)."""

    banks: dict[str, tuple[str, ...]]

    @classmethod
    def from_config(cls, config: dict[str, Any]) -> SenderAllowlist:
        raw_banks = config.get("banks")
        if not isinstance(raw_banks, dict) or not raw_banks:
            raise TemplateConfigError("senders.yaml: 'banks' debe ser un mapeo no vacio")
        banks_config = cast("dict[str, Any]", raw_banks)

        banks: dict[str, tuple[str, ...]] = {}
        for bank, raw_entry in banks_config.items():
            if not isinstance(raw_entry, dict) or "senders" not in raw_entry:
                raise TemplateConfigError(f"senders.yaml: entrada invalida para banco {bank!r}")
            entry = cast("dict[str, Any]", raw_entry)
            senders = entry["senders"]
            if not isinstance(senders, list):
                raise TemplateConfigError(
                    f"senders.yaml: 'senders' de {bank!r} debe ser una lista de strings"
                )
            senders_candidates = cast("list[Any]", senders)
            if not all(isinstance(s, str) for s in senders_candidates):
                raise TemplateConfigError(
                    f"senders.yaml: 'senders' de {bank!r} debe ser una lista de strings"
                )
            senders_list = cast("list[str]", senders_candidates)
            banks[str(bank)] = tuple(s.lower() for s in senders_list)
        return cls(banks=banks)

    def known_banks(self) -> frozenset[str]:
        """Los bancos declarados en la config (con o sin fixture que los confirme)."""
        return frozenset(self.banks)

    def bank_for_email_sender(self, sender: str) -> str | None:
        """Banco cuyo patron matchea `sender`, o `None` si ninguno matchea (AC-2.4).

        Solo mira la direccion (el display name nunca se matchea). Un patron
        exacto compara la direccion completa; un patron `"@dominio"` matchea
        `x@dominio` y cualquier subdominio (`x@sub.dominio`), pero nunca un
        dominio "hijo" como `x@dominio.evil.com`.
        """
        address = _extract_address(sender)
        if "@" not in address:
            return None
        domain = address.rpartition("@")[2]

        for bank, patterns in self.banks.items():
            for pattern in patterns:
                if pattern.startswith("@"):
                    suffix = pattern[1:]
                    if domain == suffix or domain.endswith(f".{suffix}"):
                        return bank
                elif address == pattern:
                    return bank
        return None


@dataclass(frozen=True, slots=True)
class _SmsPattern:
    regex: re.Pattern[str]
    bank: str


@dataclass(frozen=True, slots=True)
class CaptureConfig:
    """Apps/paquetes soportados por el listener de notificaciones (spec 006 §3.1)."""

    banking_apps: dict[str, str | None]
    messages_apps: frozenset[str]
    sms_patterns: tuple[_SmsPattern, ...]

    @classmethod
    def from_config(cls, config: dict[str, Any]) -> CaptureConfig:
        raw_apps = config.get("banking_apps")
        raw_messages = config.get("messages_apps")
        raw_sms = config.get("sms_sender_patterns")
        if not isinstance(raw_apps, list) or not raw_apps:
            raise TemplateConfigError("capture.yaml: 'banking_apps' debe ser una lista no vacia")
        if not isinstance(raw_messages, list):
            raise TemplateConfigError("capture.yaml: 'messages_apps' debe ser una lista")
        if not isinstance(raw_sms, list):
            raise TemplateConfigError("capture.yaml: 'sms_sender_patterns' debe ser una lista")

        apps_config = cast("list[Any]", raw_apps)
        messages_config = cast("list[Any]", raw_messages)
        sms_config = cast("list[Any]", raw_sms)

        banking_apps: dict[str, str | None] = {}
        for raw_app in apps_config:
            if not isinstance(raw_app, dict) or "package" not in raw_app:
                raise TemplateConfigError("capture.yaml: entrada invalida en 'banking_apps'")
            app = cast("dict[str, Any]", raw_app)
            bank_value = app.get("bank")
            banking_apps[str(app["package"])] = str(bank_value) if bank_value is not None else None

        sms_patterns: list[_SmsPattern] = []
        for raw_entry in sms_config:
            if (
                not isinstance(raw_entry, dict)
                or "pattern" not in raw_entry
                or "bank" not in raw_entry
            ):
                raise TemplateConfigError("capture.yaml: entrada invalida en 'sms_sender_patterns'")
            entry = cast("dict[str, Any]", raw_entry)
            pattern_str = str(entry["pattern"])
            try:
                regex = re.compile(pattern_str)
            except re.error as exc:
                raise TemplateConfigError(
                    f"capture.yaml: patron invalido {pattern_str!r}: {exc}"
                ) from exc
            sms_patterns.append(_SmsPattern(regex=regex, bank=str(entry["bank"])))

        return cls(
            banking_apps=banking_apps,
            messages_apps=frozenset(str(a) for a in messages_config),
            sms_patterns=tuple(sms_patterns),
        )

    def bank_for_notification(
        self, package: str, channel: str, title: str | None
    ) -> NotificationDecision:
        """Decide si una notificacion/SMS se acepta y con que banco (spec 006 §3.2).

        `channel="notification"`: aceptada si `package` esta en `banking_apps`
        (el banco puede ser `None`, p. ej. Google Wallet). `channel=
        "sms_notification"`: aceptada si `package` esta en `messages_apps` **y**
        `title` matchea algun `sms_sender_patterns` (AC-3.3: si no matchea, se
        rechaza sin seguir leyendo). Cualquier otro canal/paquete se rechaza.
        """
        if channel == "notification":
            if package in self.banking_apps:
                return NotificationDecision(accepted=True, bank=self.banking_apps[package])
            return NotificationDecision(accepted=False, bank=None)

        if channel == "sms_notification":
            if package not in self.messages_apps or not title:
                return NotificationDecision(accepted=False, bank=None)
            for sms_pattern in self.sms_patterns:
                if sms_pattern.regex.search(title):
                    return NotificationDecision(accepted=True, bank=sms_pattern.bank)
            return NotificationDecision(accepted=False, bank=None)

        return NotificationDecision(accepted=False, bank=None)


__all__ = ["CaptureConfig", "NotificationDecision", "SenderAllowlist"]
