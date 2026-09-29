"""Loader de la config YAML de parsing (`parsing/config/*.yaml`, D6).

Vive en infrastructure porque usa `pyyaml`/`importlib.resources` (R1 prohibe
que `parsing.domain` importe pyyaml); el resultado es un objeto de dominio
puro (`ParsingConfig`), cacheado en proceso.
"""

from __future__ import annotations

import functools
from dataclasses import dataclass
from importlib import resources
from typing import Any

import yaml

from finanzia.modules.parsing.domain.allowlist import CaptureConfig, SenderAllowlist
from finanzia.modules.parsing.domain.errors import TemplateConfigError
from finanzia.modules.parsing.domain.templates import TemplateRegistry

_CONFIG_PACKAGE = "finanzia.modules.parsing.config"
_TEMPLATES_PACKAGE = f"{_CONFIG_PACKAGE}.templates"
# Orden de prueba en `TemplateRegistry.match(None, ...)`.
_TEMPLATE_FILES = ("bancolombia.yaml", "nequi.yaml", "apple_wallet.yaml")


@dataclass(frozen=True, slots=True)
class ParsingConfig:
    """Config de parsing ya compilada/validada, lista para el dominio."""

    templates: TemplateRegistry
    senders: SenderAllowlist
    capture: CaptureConfig
    capture_raw: dict[str, Any]


def _read_yaml(package: str, filename: str) -> dict[str, Any]:
    try:
        raw = resources.files(package).joinpath(filename).read_text(encoding="utf-8")
        data = yaml.safe_load(raw)
    except (OSError, yaml.YAMLError) as exc:
        raise TemplateConfigError(f"no se pudo leer {package}/{filename}: {exc}") from exc
    if not isinstance(data, dict):
        raise TemplateConfigError(f"{package}/{filename} no es un mapeo YAML valido")
    return data


@functools.lru_cache(maxsize=1)
def load_parsing_config() -> ParsingConfig:
    """Carga y compila `senders.yaml`, `capture.yaml` y las plantillas de
    `templates/` (un YAML por banco, en `_TEMPLATE_FILES`).

    Cacheado (`lru_cache`): la config no cambia sin un redeploy. Lanza
    `TemplateConfigError` si algun YAML falta o es invalido.
    """
    senders_raw = _read_yaml(_CONFIG_PACKAGE, "senders.yaml")
    capture_raw = _read_yaml(_CONFIG_PACKAGE, "capture.yaml")
    templates_raw = [_read_yaml(_TEMPLATES_PACKAGE, name) for name in _TEMPLATE_FILES]

    try:
        senders = SenderAllowlist.from_config(senders_raw)
        capture = CaptureConfig.from_config(capture_raw)
        templates = TemplateRegistry.from_dicts(templates_raw)
    except TemplateConfigError:
        raise
    except (KeyError, TypeError, ValueError) as exc:
        raise TemplateConfigError(f"config de parsing invalida: {exc}") from exc

    return ParsingConfig(
        templates=templates,
        senders=senders,
        capture=capture,
        capture_raw=capture_raw,
    )


__all__ = ["ParsingConfig", "load_parsing_config"]
