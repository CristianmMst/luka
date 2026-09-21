"""Loader de fixtures de correos bancarios (insumo de F2.3, spec 006 §4.1).

Cada fixture es un archivo de texto con un encabezado YAML (`from`, `subject`,
`received_at`, `expected`, opcionalmente `discarded_by_sender_filter` dentro
de `expected`) separado del cuerpo por la primera linea `---` (ver
`backend/tests/fixtures/emails/README.md` para el contrato completo).
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

import yaml

FIXTURES_DIR = Path(__file__).resolve().parents[1] / "fixtures" / "emails"


@dataclass(frozen=True, slots=True)
class EmailFixture:
    """Un fixture de correo ya parseado: encabezado + cuerpo."""

    name: str
    sender: str
    subject: str
    received_at: datetime
    expected: dict[str, Any]
    body: str
    path: Path


def _load_one(path: Path) -> EmailFixture:
    raw = path.read_text(encoding="utf-8")
    header_text, _, body = raw.partition("\n---\n")
    header = yaml.safe_load(header_text)
    return EmailFixture(
        name=path.name,
        sender=header["from"],
        subject=header["subject"],
        received_at=header["received_at"],
        expected=header.get("expected", {}),
        body=body,
        path=path,
    )


def load_email_fixtures(directory: Path) -> list[EmailFixture]:
    """Carga todos los fixtures `*.txt` de `directory`, ordenados por nombre."""
    return [_load_one(path) for path in sorted(directory.glob("*.txt"))]


def bancolombia_fixtures() -> list[EmailFixture]:
    """Los 4 fixtures de Bancolombia (correo real, F2.3)."""
    return load_email_fixtures(FIXTURES_DIR / "bancolombia")


__all__ = ["FIXTURES_DIR", "EmailFixture", "bancolombia_fixtures", "load_email_fixtures"]
