"""Parser LLM deshabilitado: sin `LUKA_DEEPSEEK_API_KEY` configurada (§5)."""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from datetime import date

    from luka.modules.parsing.application.dto import LlmResult


class DisabledLlmParser:
    """Satisface `LlmParserPort` con `enabled=False`.

    `ParseRawMessage` nunca llama a `parse` cuando `enabled` es `False` (corta
    antes, produce `Failed(reason=llm_disabled)`); `parse` existe solo para
    cumplir el protocolo y lanza si por error se invoca de todos modos.
    """

    enabled = False

    async def parse(self, excerpt: str, received_on: date) -> LlmResult:
        del excerpt, received_on
        msg = "DisabledLlmParser.parse no deberia invocarse nunca (enabled=False)"
        raise RuntimeError(msg)


__all__ = ["DisabledLlmParser"]
