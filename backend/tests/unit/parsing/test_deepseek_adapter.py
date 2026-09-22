"""Tests unitarios del adapter DeepSeek (httpx.MockTransport, sin red real)."""

from __future__ import annotations

import json
from datetime import date
from typing import Any
from uuid import uuid4

import httpx
import pytest

from finanzia.modules.parsing.application.dto import LlmInvalidOutput, LlmOutput
from finanzia.modules.parsing.domain.errors import LlmUnavailable
from finanzia.modules.parsing.infrastructure.llm import build_llm_parser
from finanzia.modules.parsing.infrastructure.llm.deepseek import DeepSeekLlmParser
from finanzia.modules.parsing.infrastructure.llm.disabled import DisabledLlmParser
from finanzia.shared.settings import Settings

_EXCERPT = (
    "Bancolombia: Compraste $176.824,00 en OXXO con tu T.Deb *1234, el 01/05/2026 a las 16:00."
)
_RECEIVED_ON = date(2026, 5, 1)
_SENTINEL_USER_ID = str(uuid4())
_SENTINEL_RAW_ID = str(uuid4())
_SENTINEL_EMAIL = "cristian.mora@x-cargo.co"


def _valid_content() -> str:
    return json.dumps(
        {
            "is_transaction": True,
            "amount": "176824.00",
            "currency": "COP",
            "direction": "debit",
            "merchant": "OXXO",
            "occurred_at": "2026-05-01T16:00:00-05:00",
            "bank": "bancolombia",
            "last4": "1234",
            "suggested_category": None,
            "confidence": 0.95,
        }
    )


def _response_body(content: str, *, total_tokens: int = 123) -> dict[str, Any]:
    return {
        "choices": [{"message": {"content": content}}],
        "usage": {"total_tokens": total_tokens},
    }


def _settings(**overrides: Any) -> Settings:
    return Settings(
        _env_file=None,  # pyright: ignore[reportCallIssue]
        env="test",
        database_url="postgresql+asyncpg://u:p@localhost:5432/db",
        redis_url="redis://localhost:6379/0",
        jwt_secret="test-secret-test-secret-test-secret-1234",
        google_client_id="test-client",
        google_verifier="fake",
        **overrides,
    )


def _make_parser(handler: Any, *, model: str = "deepseek-v4-flash") -> DeepSeekLlmParser:
    transport = httpx.MockTransport(handler)
    client = httpx.AsyncClient(transport=transport)
    return DeepSeekLlmParser(
        client,
        api_key="sk-test-key",
        model=model,
        base_url="https://api.deepseek.com",
        timeout_s=5.0,
    )


@pytest.mark.unit
class TestDeepSeekLlmParserRequest:
    async def test_request_tiene_forma_esperada_y_no_filtra_ids_ni_email(self) -> None:
        captured: dict[str, Any] = {}

        def handler(request: httpx.Request) -> httpx.Response:
            captured["url"] = str(request.url)
            captured["authorization"] = request.headers.get("authorization")
            captured["body"] = json.loads(request.content)
            return httpx.Response(200, json=_response_body(_valid_content()))

        parser = _make_parser(handler)

        result = await parser.parse(_EXCERPT, _RECEIVED_ON)

        assert captured["url"] == "https://api.deepseek.com/chat/completions"
        assert captured["authorization"] == "Bearer sk-test-key"
        body = captured["body"]
        assert body["model"] == "deepseek-v4-flash"
        assert body["temperature"] == 0
        assert body["response_format"] == {"type": "json_object"}
        assert body["messages"][0]["role"] == "system"
        assert body["messages"][1]["role"] == "user"
        user_message = body["messages"][1]["content"]
        assert _EXCERPT in user_message
        assert _RECEIVED_ON.isoformat() in user_message

        full_request_json = json.dumps(body)
        assert _SENTINEL_USER_ID not in full_request_json
        assert _SENTINEL_RAW_ID not in full_request_json
        assert _SENTINEL_EMAIL not in full_request_json

        assert isinstance(result, LlmOutput)
        assert result.tokens == 123
        assert result.extraction.bank == "bancolombia"

    async def test_respuesta_valida_produce_llm_output_con_tokens_de_usage(self) -> None:
        def handler(request: httpx.Request) -> httpx.Response:
            del request
            return httpx.Response(200, json=_response_body(_valid_content(), total_tokens=42))

        parser = _make_parser(handler)

        result = await parser.parse(_EXCERPT, _RECEIVED_ON)

        assert isinstance(result, LlmOutput)
        assert result.tokens == 42

    async def test_usage_faltante_produce_tokens_cero(self) -> None:
        def handler(request: httpx.Request) -> httpx.Response:
            del request
            return httpx.Response(
                200, json={"choices": [{"message": {"content": _valid_content()}}]}
            )

        parser = _make_parser(handler)

        result = await parser.parse(_EXCERPT, _RECEIVED_ON)

        assert isinstance(result, LlmOutput)
        assert result.tokens == 0

    async def test_content_no_json_produce_llm_invalid_output(self) -> None:
        def handler(request: httpx.Request) -> httpx.Response:
            del request
            return httpx.Response(200, json=_response_body("esto no es json"))

        parser = _make_parser(handler)

        result = await parser.parse(_EXCERPT, _RECEIVED_ON)

        assert isinstance(result, LlmInvalidOutput)
        assert result.tokens == 123

    async def test_json_invalido_contra_esquema_produce_llm_invalid_output(self) -> None:
        content = json.dumps({"is_transaction": True, "confidence": 1.5})

        def handler(request: httpx.Request) -> httpx.Response:
            del request
            return httpx.Response(200, json=_response_body(content))

        parser = _make_parser(handler)

        result = await parser.parse(_EXCERPT, _RECEIVED_ON)

        assert isinstance(result, LlmInvalidOutput)
        assert result.tokens == 123

    async def test_cuerpo_200_que_no_es_json_lanza_llm_unavailable(self) -> None:
        """Un 200 con HTML de un proxy/WAF no es una respuesta del modelo: antes
        propagaba `json.JSONDecodeError` fuera de `parse()` (nadie la capturaba
        aguas arriba) en vez de mapear a `LlmUnavailable`.
        """

        def handler(request: httpx.Request) -> httpx.Response:
            del request
            return httpx.Response(200, text="<html>503 Service Unavailable</html>")

        parser = _make_parser(handler)

        with pytest.raises(LlmUnavailable):
            await parser.parse(_EXCERPT, _RECEIVED_ON)

    async def test_decoding_error_lanza_llm_unavailable(self) -> None:
        """`httpx.DecodingError` es `RequestError` pero NO `TransportError`, asi que
        se escapaba del mapeo (igual que `TooManyRedirects`).
        """

        def handler(request: httpx.Request) -> httpx.Response:
            raise httpx.DecodingError("contenido ilegible", request=request)

        parser = _make_parser(handler)

        with pytest.raises(LlmUnavailable):
            await parser.parse(_EXCERPT, _RECEIVED_ON)

    async def test_http_500_lanza_llm_unavailable(self) -> None:
        def handler(request: httpx.Request) -> httpx.Response:
            del request
            return httpx.Response(500, json={"error": "boom"})

        parser = _make_parser(handler)

        with pytest.raises(LlmUnavailable):
            await parser.parse(_EXCERPT, _RECEIVED_ON)

    async def test_timeout_lanza_llm_unavailable(self) -> None:
        def handler(request: httpx.Request) -> httpx.Response:
            del request
            raise httpx.ReadTimeout("timed out")

        parser = _make_parser(handler)

        with pytest.raises(LlmUnavailable):
            await parser.parse(_EXCERPT, _RECEIVED_ON)

    def test_enabled_es_true(self) -> None:
        parser = _make_parser(lambda request: httpx.Response(200, json={}))
        assert parser.enabled is True


@pytest.mark.unit
class TestBuildLlmParser:
    def test_sin_api_key_devuelve_disabled(self) -> None:
        settings = _settings(deepseek_api_key=None)

        parser = build_llm_parser(settings, client=None)

        assert isinstance(parser, DisabledLlmParser)
        assert parser.enabled is False

    def test_api_key_vacia_devuelve_disabled(self) -> None:
        settings = _settings(deepseek_api_key="")

        parser = build_llm_parser(settings, client=None)

        assert isinstance(parser, DisabledLlmParser)

    def test_con_api_key_devuelve_deepseek_parser(self) -> None:
        settings = _settings(deepseek_api_key="sk-real")
        client = httpx.AsyncClient(transport=httpx.MockTransport(lambda r: httpx.Response(200)))

        parser = build_llm_parser(settings, client=client)

        assert isinstance(parser, DeepSeekLlmParser)
        assert parser.enabled is True
