"""Tests unitarios de `Settings`: prefijo de entorno y validadores (spec 003 F0.4)."""

import pytest
from pydantic import ValidationError

from finanzia.shared.settings import Settings

_ENV_VALIDO = {
    "FINANZIA_DATABASE_URL": "postgresql+asyncpg://finanzia:finanzia@localhost:5432/finanzia_test",
    "FINANZIA_REDIS_URL": "redis://localhost:6379/1",
    "FINANZIA_JWT_SECRET": "a" * 32,
    "FINANZIA_GOOGLE_CLIENT_ID": "test-client",
}


def _setear_env_valido(monkeypatch: pytest.MonkeyPatch) -> None:
    for clave, valor in _ENV_VALIDO.items():
        monkeypatch.setenv(clave, valor)


def _construir_settings() -> Settings:
    # Los campos requeridos vienen de las variables de entorno seteadas por el test;
    # pyright no lo ve porque BaseSettings sintetiza el __init__ desde los campos.
    return Settings(_env_file=None)  # pyright: ignore[reportCallIssue]


@pytest.mark.unit
def test_lee_variables_con_prefijo_finanzia(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", "test")

    settings = _construir_settings()

    assert settings.env == "test"
    assert str(settings.database_url).startswith("postgresql+asyncpg://")
    assert settings.google_client_id == "test-client"


@pytest.mark.unit
def test_jwt_secret_menor_a_32_caracteres_falla(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_JWT_SECRET", "muy-corto")

    with pytest.raises(ValidationError):
        _construir_settings()


@pytest.mark.unit
def test_db_echo_true_en_prod_falla(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", "prod")
    monkeypatch.setenv("FINANZIA_DB_ECHO", "true")

    with pytest.raises(ValidationError):
        _construir_settings()


@pytest.mark.unit
def test_valores_por_defecto(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)

    settings = _construir_settings()

    assert settings.env == "dev"
    assert settings.jwt_access_ttl_seconds == 900
    assert settings.refresh_ttl_days == 60
    assert settings.rate_limit_auth_per_minute == 10
    assert settings.rate_limit_user_per_minute == 600
    assert settings.idempotency_ttl_seconds == 86400
    assert settings.max_body_bytes == 1_048_576
    assert settings.db_pool_size == 10
    assert settings.db_echo is False
    assert settings.trust_proxy_headers is False
    assert settings.log_json is False  # env == "dev"
    assert settings.rate_limit_ingest_per_minute == 60
    assert settings.deepseek_api_key is None
    assert settings.deepseek_base_url == "https://api.deepseek.com"
    assert settings.deepseek_model == "deepseek-v4-flash"
    assert settings.llm_timeout_seconds == 20.0
    assert settings.llm_monthly_token_budget_per_user == 200_000
    assert settings.llm_confidence_threshold == 0.8
    assert settings.raw_message_retention_days == 90
    assert settings.raw_message_body_max_bytes == 8192


@pytest.mark.unit
def test_log_json_por_defecto_es_true_fuera_de_dev(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", "test")

    settings = _construir_settings()

    assert settings.log_json is True


@pytest.mark.unit
def test_deepseek_api_key_none_en_prod_no_falla(monkeypatch: pytest.MonkeyPatch) -> None:
    """LLM deshabilitado (sin API key) es legitimo incluso en prod."""
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", "prod")

    settings = _construir_settings()

    assert settings.deepseek_api_key is None


@pytest.mark.unit
@pytest.mark.parametrize("valor", ["0", "-0.1", "1.1", "2"])
def test_llm_confidence_threshold_fuera_de_rango_falla(
    monkeypatch: pytest.MonkeyPatch, valor: str
) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_LLM_CONFIDENCE_THRESHOLD", valor)

    with pytest.raises(ValidationError):
        _construir_settings()


@pytest.mark.unit
def test_llm_confidence_threshold_uno_es_valido(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_LLM_CONFIDENCE_THRESHOLD", "1")

    settings = _construir_settings()

    assert settings.llm_confidence_threshold == 1.0


@pytest.mark.unit
def test_raw_message_retention_days_menor_a_uno_falla(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_RAW_MESSAGE_RETENTION_DAYS", "0")

    with pytest.raises(ValidationError):
        _construir_settings()


@pytest.mark.unit
def test_raw_message_body_max_bytes_menor_a_512_falla(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_RAW_MESSAGE_BODY_MAX_BYTES", "511")

    with pytest.raises(ValidationError):
        _construir_settings()
