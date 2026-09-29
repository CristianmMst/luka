"""Motor de plantillas regex por banco (spec 006 §4.1, F2.3). Puro (stdlib
solo, P3). Ninguna plantilla entra sin fixture real (regla de oro, spec 006
§4.1): `config/templates/bancolombia.yaml` y `nequi.yaml`.
"""

from __future__ import annotations

import re
from collections.abc import Mapping
from datetime import datetime, timedelta
from typing import Any, cast

from finanzia.modules.parsing.domain.enums import Direction
from finanzia.modules.parsing.domain.errors import (
    AmountInvalid,
    DateInvalid,
    TemplateConfigError,
    TemplateExtractionInvalid,
)
from finanzia.modules.parsing.domain.normalizers import (
    clean_text,
    parse_amount,
    parse_local_datetime,
)
from finanzia.modules.parsing.domain.parsed import ParsedTransaction

_MAX_DRIFT = timedelta(days=7)
_REQUIRED_GROUPS = frozenset({"amount", "date", "time"})


class Template:
    """Una plantilla: regex nombrada + post-proceso."""

    __slots__ = (
        "counterparty",
        "date_format",
        "direction",
        "id",
        "pattern",
        "suggested_category",
    )

    def __init__(  # noqa: PLR0913 - un campo por clave del YAML
        self,
        *,
        id: str,
        direction: Direction,
        pattern: re.Pattern[str],
        date_format: str,
        suggested_category: str | None,
        counterparty: bool = False,
    ) -> None:
        self.id = id
        self.direction = direction
        self.pattern = pattern
        self.date_format = date_format
        self.suggested_category = suggested_category
        # El grupo `merchant` es una persona (envio o recibo entre personas),
        # no un comercio: ledger lo compara con el titular (transferencia
        # propia, spec 004 §4.1).
        self.counterparty = counterparty


class BankTemplates:
    """Plantillas de un banco: extracto de referencia + lista versionada."""

    __slots__ = ("bank", "relevant_line_prefix", "templates", "version")

    def __init__(
        self,
        *,
        bank: str,
        version: int,
        relevant_line_prefix: str | None,
        templates: tuple[Template, ...],
    ) -> None:
        self.bank = bank
        self.version = version
        self.relevant_line_prefix = relevant_line_prefix
        self.templates = templates


class TemplateMatch:
    """Un match de plantilla contra un extracto, antes de normalizar."""

    __slots__ = ("bank", "groups", "template", "version")

    def __init__(
        self,
        *,
        bank: str,
        version: int,
        template: Template,
        groups: Mapping[str, str | None],
    ) -> None:
        self.bank = bank
        self.version = version
        self.template = template
        self.groups = groups

    def to_parsed(self, received_at: datetime) -> ParsedTransaction:
        """Aplica los normalizadores y produce un `ParsedTransaction`.

        `occurred_at` fuera de `received_at +/- 7 dias`, o un monto/fecha
        invalidos, lanzan `TemplateExtractionInvalid` (el caso de uso sigue
        al LLM en vez de fallar duro).
        """
        try:
            amount = parse_amount(self.groups["amount"] or "")
            occurred_at = parse_local_datetime(
                self.groups["date"] or "",
                self.groups["time"] or "",
                self.template.date_format,
            )
        except (AmountInvalid, DateInvalid) as exc:
            raise TemplateExtractionInvalid(str(exc)) from exc

        if not (received_at - _MAX_DRIFT <= occurred_at <= received_at + _MAX_DRIFT):
            raise TemplateExtractionInvalid(
                f"occurred_at {occurred_at} fuera de received_at +/- 7 dias ({received_at})"
            )

        merchant_raw = self.groups.get("merchant")
        merchant = clean_text(merchant_raw) if merchant_raw else None

        return ParsedTransaction(
            bank=self.bank,
            amount=amount,
            direction=self.template.direction,
            occurred_at=occurred_at,
            merchant=merchant,
            last4=self.groups.get("last4"),
            suggested_category=self.template.suggested_category,
            parsed_by=f"rule:{self.bank}:{self.template.id}:v{self.version}",
            confidence=None,
            merchant_is_person=self.template.counterparty,
        )


def _compile_template(bank: str, raw: dict[str, Any]) -> Template:
    for key in ("id", "direction", "pattern", "date_format"):
        if key not in raw:
            raise TemplateConfigError(f"plantilla de {bank!r} sin campo obligatorio {key!r}")

    try:
        direction = Direction(raw["direction"])
    except ValueError as exc:
        raise TemplateConfigError(
            f"plantilla {raw.get('id')!r} de {bank!r}: direction invalida {raw['direction']!r}"
        ) from exc

    try:
        pattern = re.compile(raw["pattern"], re.UNICODE)
    except re.error as exc:
        raise TemplateConfigError(
            f"plantilla {raw.get('id')!r} de {bank!r}: regex invalida: {exc}"
        ) from exc

    missing = _REQUIRED_GROUPS - set(pattern.groupindex)
    if missing:
        raise TemplateConfigError(
            f"plantilla {raw.get('id')!r} de {bank!r}: faltan grupos nombrados {sorted(missing)}"
        )

    counterparty = raw.get("counterparty", False)
    if not isinstance(counterparty, bool):
        raise TemplateConfigError(
            f"plantilla {raw.get('id')!r} de {bank!r}: counterparty debe ser true/false"
        )

    return Template(
        id=str(raw["id"]),
        direction=direction,
        pattern=pattern,
        date_format=str(raw["date_format"]),
        suggested_category=raw.get("suggested_category"),
        counterparty=counterparty,
    )


def _compile_bank(raw: dict[str, Any]) -> BankTemplates:
    for key in ("bank", "version", "templates"):
        if key not in raw:
            raise TemplateConfigError(f"config de plantillas sin campo obligatorio {key!r}")
    bank = str(raw["bank"])
    raw_templates = raw["templates"]
    if not isinstance(raw_templates, list) or not raw_templates:
        raise TemplateConfigError(f"{bank!r}: 'templates' debe ser una lista no vacia")
    templates_config = cast("list[dict[str, Any]]", raw_templates)

    templates = tuple(_compile_template(bank, entry) for entry in templates_config)
    return BankTemplates(
        bank=bank,
        version=int(raw["version"]),
        relevant_line_prefix=raw.get("relevant_line_prefix"),
        templates=templates,
    )


class TemplateRegistry:
    """Registro de plantillas de todos los bancos configurados."""

    __slots__ = ("_banks",)

    def __init__(self, banks: dict[str, BankTemplates]) -> None:
        self._banks = banks

    @classmethod
    def from_dicts(cls, configs: list[dict[str, Any]]) -> TemplateRegistry:
        """Compila una lista de configs (una por banco) en un `TemplateRegistry`.

        Errores de config (regex invalida, campos/direction invalidos) fallan
        al cargar (`TemplateConfigError`), nunca en tiempo de match.
        """
        banks: dict[str, BankTemplates] = {}
        for raw in configs:
            bank_templates = _compile_bank(raw)
            banks[bank_templates.bank] = bank_templates
        return cls(banks)

    def bank_config(self, bank: str) -> BankTemplates | None:
        return self._banks.get(bank)

    def known_banks(self) -> frozenset[str]:
        """Bancos con al menos una plantilla configurada (distinto de allowlist)."""
        return frozenset(self._banks)

    def person_parsed_by(self) -> frozenset[str]:
        """`parsed_by` de las plantillas con `counterparty: true` (envios y
        recibos entre personas), para reclasificar transferencias propias ya
        capturadas (spec 004 §4.1)."""
        return frozenset(
            f"rule:{bank.bank}:{template.id}:v{bank.version}"
            for bank in self._banks.values()
            for template in bank.templates
            if template.counterparty
        )

    def match(self, bank: str | None, excerpt: str) -> TemplateMatch | None:
        """Busca la primera plantilla que matchea `excerpt`.

        Si `bank` es `None` se prueban todos los bancos conocidos, en el
        orden en que fueron cargados.
        """
        if bank is None:
            candidates: list[BankTemplates] = list(self._banks.values())
        else:
            bank_templates = self._banks.get(bank)
            candidates = [bank_templates] if bank_templates is not None else []

        for bank_templates in candidates:
            for template in bank_templates.templates:
                found = template.pattern.search(excerpt)
                if found:
                    return TemplateMatch(
                        bank=bank_templates.bank,
                        version=bank_templates.version,
                        template=template,
                        groups=found.groupdict(),
                    )
        return None


__all__ = ["BankTemplates", "Template", "TemplateMatch", "TemplateRegistry"]
