"""Configuracion de la aplicacion via variables de entorno (spec 003 F0.4)."""

import base64
import binascii
from functools import lru_cache
from typing import Literal, Self

from pydantic import PostgresDsn, RedisDsn, SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_JWT_SECRET_MIN_LENGTH = 32
_RAW_MESSAGE_BODY_MAX_BYTES_MINIMO = 512
_GMAIL_TOKEN_KEY_LENGTH_BYTES = 32


class Settings(BaseSettings):
    """Configuracion tipada de finanzia, leida de variables `FINANZIA_*` o `.env`."""

    model_config = SettingsConfigDict(
        env_prefix="FINANZIA_",
        env_file=".env",
        extra="ignore",
    )

    env: Literal["dev", "test", "prod"] = "dev"

    database_url: PostgresDsn
    redis_url: RedisDsn

    jwt_secret: SecretStr
    jwt_access_ttl_seconds: int = 900
    refresh_ttl_days: int = 60

    google_client_id: str
    google_client_secret: SecretStr

    # Cifrado AES-256-GCM de `gmail_connections.refresh_token_enc` (spec 009 §3, F3.2).
    gmail_token_key: SecretStr
    gmail_pubsub_topic: str = "projects/finanzia-509500/topics/gmail-push"
    gmail_push_audience: str = "finanzia-gmail-push"
    gmail_push_service_account: str = "gmail-push-invoker@finanzia-509500.iam.gserviceaccount.com"

    log_level: str = "INFO"
    log_json: bool | None = None

    trust_proxy_headers: bool = False

    rate_limit_auth_per_minute: int = 10
    rate_limit_user_per_minute: int = 600
    idempotency_ttl_seconds: int = 86400
    max_body_bytes: int = 1_048_576

    db_pool_size: int = 10
    db_echo: bool = False

    rate_limit_ingest_per_minute: int = 60

    deepseek_api_key: SecretStr | None = None
    deepseek_base_url: str = "https://api.deepseek.com"
    deepseek_model: str = "deepseek-v4-flash"
    llm_timeout_seconds: float = 20.0
    llm_monthly_token_budget_per_user: int = 200_000
    llm_confidence_threshold: float = 0.8

    raw_message_retention_days: int = 90
    raw_message_body_max_bytes: int = 8192

    @field_validator("jwt_secret")
    @classmethod
    def _jwt_secret_debe_ser_largo(cls, value: SecretStr) -> SecretStr:
        if len(value.get_secret_value()) < _JWT_SECRET_MIN_LENGTH:
            msg = f"jwt_secret debe tener al menos {_JWT_SECRET_MIN_LENGTH} caracteres"
            raise ValueError(msg)
        return value

    @field_validator("llm_confidence_threshold")
    @classmethod
    def _llm_confidence_threshold_en_rango(cls, value: float) -> float:
        if not (0 < value <= 1):
            msg = "llm_confidence_threshold debe estar en el rango (0, 1]"
            raise ValueError(msg)
        return value

    @field_validator("raw_message_retention_days")
    @classmethod
    def _raw_message_retention_days_minimo(cls, value: int) -> int:
        if value < 1:
            msg = "raw_message_retention_days debe ser >= 1"
            raise ValueError(msg)
        return value

    @field_validator("raw_message_body_max_bytes")
    @classmethod
    def _raw_message_body_max_bytes_minimo(cls, value: int) -> int:
        if value < _RAW_MESSAGE_BODY_MAX_BYTES_MINIMO:
            msg = "raw_message_body_max_bytes debe ser >= 512"
            raise ValueError(msg)
        return value

    @field_validator("gmail_token_key")
    @classmethod
    def _gmail_token_key_debe_decodificar_a_32_bytes(cls, value: SecretStr) -> SecretStr:
        try:
            decodificada = base64.b64decode(value.get_secret_value(), validate=True)
        except (binascii.Error, ValueError) as exc:
            msg = "gmail_token_key debe ser base64 valido"
            raise ValueError(msg) from exc
        if len(decodificada) != _GMAIL_TOKEN_KEY_LENGTH_BYTES:
            msg = f"gmail_token_key debe decodificar a {_GMAIL_TOKEN_KEY_LENGTH_BYTES} bytes"
            raise ValueError(msg)
        return value

    @model_validator(mode="after")
    def _validar_restricciones_de_produccion(self) -> Self:
        if self.env == "prod":
            if self.db_echo:
                msg = "db_echo=True no esta permitido cuando env='prod'"
                raise ValueError(msg)
        if self.log_json is None:
            self.log_json = self.env != "dev"
        return self


@lru_cache
def get_settings() -> Settings:
    """Devuelve la instancia de Settings cacheada para el proceso actual."""
    # Los campos requeridos llegan por variables de entorno FINANZIA_* o .env;
    # pyright no puede verlo porque BaseSettings sintetiza el __init__ desde los campos.
    return Settings()  # pyright: ignore[reportCallIssue]
