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
def test_google_verifier_fake_en_prod_falla(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", "prod")
    monkeypatch.setenv("FINANZIA_GOOGLE_VERIFIER", "fake")

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
    assert settings.google_verifier == "google"
    assert settings.log_json is False  # env == "dev"


@pytest.mark.unit
def test_log_json_por_defecto_es_true_fuera_de_dev(monkeypatch: pytest.MonkeyPatch) -> None:
    _setear_env_valido(monkeypatch)
    monkeypatch.setenv("FINANZIA_ENV", "test")

    settings = _construir_settings()

    assert settings.log_json is True
