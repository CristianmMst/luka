"""Errores de aplicacion: excepciones tipadas mapeadas a la envoltura HTTP (spec 005 SS1).

Modulo stdlib-only: no importa FastAPI ni pydantic para que `finanzia.shared` siga
siendo importable desde cualquier capa (incluido el dominio de los modulos).
"""

from collections.abc import Callable, Mapping


class AppError(Exception):
    """Excepcion base de aplicacion con status/code HTTP explicitos.

    Los mensajes por defecto son genericos y nunca deben construirse a partir de
    entrada del usuario (evita filtrar datos en la respuesta de error).
    """

    def __init__(
        self,
        status: int,
        code: str,
        message: str,
        field: str | None = None,
        headers: dict[str, str] | None = None,
    ) -> None:
        super().__init__(message)
        self.status = status
        self.code = code
        self.message = message
        self.field = field
        self.headers = headers if headers is not None else {}


class ValidationAppError(AppError):
    """400 - entrada invalida (reemplaza el 422 por defecto de FastAPI, spec 005 SS1)."""

    def __init__(self, message: str = "Entrada invalida", field: str | None = None) -> None:
        super().__init__(400, "validation_error", message, field=field)


class UnauthorizedError(AppError):
    """401 - sin autenticacion valida."""

    def __init__(self, message: str = "No autenticado") -> None:
        super().__init__(401, "unauthorized", message)


class TokenExpiredError(AppError):
    """401 - access token vencido (distinto de `unauthorized` generico)."""

    def __init__(self, message: str = "Token expirado") -> None:
        super().__init__(401, "token_expired", message)


class ForbiddenError(AppError):
    """403 - accion no permitida sobre un recurso propio/visible."""

    def __init__(self, message: str = "Accion no permitida") -> None:
        super().__init__(403, "forbidden", message)


class NotFoundError(AppError):
    """404 - recurso no encontrado (incluye recursos ajenos, spec 009 SS4)."""

    def __init__(self, message: str = "Recurso no encontrado", field: str | None = None) -> None:
        super().__init__(404, "not_found", message, field=field)


class ConflictError(AppError):
    """409 - conflicto (p. ej. duplicado).

    `headers` es opcional: lo usa el candado de idempotencia en curso para sumar
    `Retry-After: 1` (spec 005 SS1) sin afectar el resto de los conflictos.
    """

    def __init__(
        self,
        message: str = "Conflicto",
        field: str | None = None,
        headers: dict[str, str] | None = None,
    ) -> None:
        super().__init__(409, "conflict", message, field=field, headers=headers)


class RateLimitedError(AppError):
    """429 - limite de tasa excedido; agrega el header `Retry-After`."""

    def __init__(self, retry_after: int, message: str = "Demasiadas solicitudes") -> None:
        super().__init__(
            429,
            "rate_limited",
            message,
            headers={"Retry-After": str(retry_after)},
        )


class UpstreamUnavailableError(AppError):
    """503 - un servicio externo (p. ej. Google) fallo de forma transitoria; reintentar."""

    def __init__(self, message: str = "Servicio externo no disponible, reintenta") -> None:
        super().__init__(503, "upstream_unavailable", message)


class InternalError(AppError):
    """500 - error interno; el mensaje nunca debe incluir detalles internos."""

    def __init__(self, message: str = "Internal server error") -> None:
        super().__init__(500, "internal", message)


ExceptionMap = Mapping[type[Exception], Callable[[Exception], AppError]]
