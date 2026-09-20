"""Configuracion de la aplicacion via variables de entorno (spec 003 F0.4)."""

from functools import lru_cache
from typing import Literal, Self

from pydantic import PostgresDsn, RedisDsn, SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_JWT_SECRET_MIN_LENGTH = 32


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
    google_verifier: Literal["google", "fake"] = "google"

    log_level: str = "INFO"
    log_json: bool | None = None

    trust_proxy_headers: bool = False

    rate_limit_auth_per_minute: int = 10
    rate_limit_user_per_minute: int = 600
    idempotency_ttl_seconds: int = 86400
    max_body_bytes: int = 1_048_576

    db_pool_size: int = 10
    db_echo: bool = False

    @field_validator("jwt_secret")
    @classmethod
    def _jwt_secret_debe_ser_largo(cls, value: SecretStr) -> SecretStr:
        if len(value.get_secret_value()) < _JWT_SECRET_MIN_LENGTH:
            msg = f"jwt_secret debe tener al menos {_JWT_SECRET_MIN_LENGTH} caracteres"
            raise ValueError(msg)
        return value

    @model_validator(mode="after")
    def _validar_restricciones_de_produccion(self) -> Self:
        if self.env == "prod":
            if self.google_verifier == "fake":
                msg = "google_verifier='fake' no esta permitido cuando env='prod'"
                raise ValueError(msg)
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
