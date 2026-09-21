"""Fabrica del adapter LLM de parsing (spec 006 §4.2, controller ruling §5).

`build_llm_parser` decide en un unico lugar si el LLM esta habilitado: sin
`FINANZIA_DEEPSEEK_API_KEY` (o vacia), `DisabledLlmParser`; con ella,
`DeepSeekLlmParser` real sobre httpx.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import httpx

from finanzia.modules.parsing.infrastructure.llm.deepseek import DeepSeekLlmParser
from finanzia.modules.parsing.infrastructure.llm.disabled import DisabledLlmParser

if TYPE_CHECKING:
    from finanzia.modules.parsing.application.ports import LlmParserPort
    from finanzia.shared.settings import Settings


def build_llm_parser(settings: Settings, client: httpx.AsyncClient | None) -> LlmParserPort:
    """`DisabledLlmParser` si no hay API key configurada; si no, `DeepSeekLlmParser`.

    `client`, si se pasa, es el `httpx.AsyncClient` a reutilizar (p. ej. el de
    la app, compartido entre requests); si es `None` se crea uno nuevo.
    """
    api_key = settings.deepseek_api_key
    if api_key is None or not api_key.get_secret_value():
        return DisabledLlmParser()
    return DeepSeekLlmParser(
        client if client is not None else httpx.AsyncClient(),
        api_key=api_key.get_secret_value(),
        model=settings.deepseek_model,
        base_url=settings.deepseek_base_url,
        timeout_s=settings.llm_timeout_seconds,
    )


__all__ = ["DeepSeekLlmParser", "DisabledLlmParser", "build_llm_parser"]
