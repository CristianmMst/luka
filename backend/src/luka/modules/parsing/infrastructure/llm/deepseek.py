"""Adapter DeepSeek (httpx) para `LlmParserPort` (spec 006 §4.2, R1/R2: el
unico lugar de parsing con `httpx` es infrastructure).

Nunca loguea el contenido de la respuesta ni el prompt (spec 009 §5): solo
`status_code`, `latency_ms`, `tokens` y `model` en `llm_request`.
"""

from __future__ import annotations

import json
import time
from typing import TYPE_CHECKING, Any

import httpx
import structlog

from luka.modules.parsing.application.dto import LlmInvalidOutput, LlmOutput
from luka.modules.parsing.domain.errors import LlmUnavailable
from luka.modules.parsing.infrastructure.llm.prompt import SYSTEM_PROMPT, build_user_message
from luka.modules.parsing.infrastructure.llm.schema import LlmSchemaInvalid, parse_llm_response

if TYPE_CHECKING:
    from datetime import date

    from luka.modules.parsing.application.dto import LlmResult

_logger = structlog.get_logger()

_MAX_TOKENS = 300
_TEMPERATURE = 0


class DeepSeekLlmParser:
    """`LlmParserPort` real: `POST {base_url}/chat/completions` (DeepSeek, API
    compatible OpenAI).
    """

    enabled = True

    def __init__(
        self,
        client: httpx.AsyncClient,
        *,
        api_key: str,
        model: str,
        base_url: str,
        timeout_s: float,
    ) -> None:
        self._client = client
        self._api_key = api_key
        self._model = model
        self._base_url = base_url.rstrip("/")
        self._timeout_s = timeout_s

    async def parse(self, excerpt: str, received_on: date) -> LlmResult:
        url = f"{self._base_url}/chat/completions"
        body = {
            "model": self._model,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": build_user_message(excerpt, received_on)},
            ],
            "temperature": _TEMPERATURE,
            "response_format": {"type": "json_object"},
            "max_tokens": _MAX_TOKENS,
        }
        headers = {"Authorization": f"Bearer {self._api_key}"}

        start = time.monotonic()
        status_code: int | None = None
        try:
            response = await self._client.post(
                url, json=body, headers=headers, timeout=self._timeout_s
            )
            status_code = response.status_code
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            self._log_request(status_code, start, tokens=None)
            raise LlmUnavailable(str(status_code)) from exc
        except httpx.RequestError as exc:
            # `httpx.RequestError` (no `TransportError`) es la raiz correcta: cubre
            # timeouts y errores de red/conexion (`TransportError`) y ademas
            # `DecodingError`/`TooManyRedirects`, que son hermanas de
            # `TransportError` y antes se escapaban sin mapear a `LlmUnavailable`.
            self._log_request(status_code, start, tokens=None)
            raise LlmUnavailable(type(exc).__name__) from exc

        return self._parse_response(response, status_code, start)

    def _parse_response(
        self, response: httpx.Response, status_code: int | None, start: float
    ) -> LlmResult:
        try:
            payload: dict[str, Any] = response.json()
        except ValueError as exc:  # `json.JSONDecodeError`/`UnicodeDecodeError`
            # Un 200 cuyo cuerpo ni siquiera es JSON (HTML de un proxy/WAF, cuerpo
            # truncado) no es una respuesta del modelo: es el endpoint que no esta
            # disponible, asi que se mapea a `LlmUnavailable` (revision por
            # `llm_error`) en vez de propagar el `JSONDecodeError` fuera de
            # `parse()`, que nadie captura y terminaba en DLQ con la fila `pending`.
            # Un JSON valido pero con envelope/contenido invalido es otra cosa y
            # sigue devolviendo `LlmInvalidOutput` (abajo).
            self._log_request(status_code, start, tokens=None)
            raise LlmUnavailable("invalid_json_body") from exc

        usage = payload.get("usage") or {}
        tokens = int(usage.get("total_tokens") or 0)
        self._log_request(status_code, start, tokens=tokens)

        try:
            content = payload["choices"][0]["message"]["content"]
            parsed_content = json.loads(content)
            validated = parse_llm_response(parsed_content)
        except (KeyError, IndexError, TypeError, json.JSONDecodeError, LlmSchemaInvalid):
            return LlmInvalidOutput(tokens=tokens)

        return LlmOutput(extraction=validated.to_extraction(), tokens=tokens)

    def _log_request(self, status_code: int | None, start: float, *, tokens: int | None) -> None:
        latency_ms = int((time.monotonic() - start) * 1000)
        _logger.info(
            "llm_request",
            status_code=status_code,
            latency_ms=latency_ms,
            tokens=tokens,
            model=self._model,
        )


__all__ = ["DeepSeekLlmParser"]
