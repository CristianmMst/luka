"""Instala los manejadores de excepciones que producen la envoltura de error (spec 005 SS1)."""

from collections.abc import Awaitable, Callable, Sequence

import structlog
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from luka.shared.errors import AppError, ExceptionMap

_LEADING_LOC_PREFIXES = {"body", "query", "path", "header"}

_STATUS_CODE_TO_CODE = {
    401: "unauthorized",
    403: "forbidden",
    409: "conflict",
    429: "rate_limited",
}

_MESSAGE_BY_CODE = {
    "unauthorized": "No autenticado",
    "forbidden": "Accion no permitida",
    "not_found": "Recurso no encontrado",
    "conflict": "Conflicto",
    "rate_limited": "Demasiadas solicitudes",
    "internal": "Internal server error",
}


def _error_response(  # noqa: PLR0913 - un parametro por campo del sobre + headers y reason
    status: int,
    code: str,
    message: str,
    field: str | None = None,
    *,
    headers: dict[str, str] | None = None,
    reason: str | None = None,
) -> JSONResponse:
    error: dict[str, object] = {"code": code, "message": message}
    if field is not None:
        error["field"] = field
    if reason is not None:
        error["reason"] = reason
    return JSONResponse(status_code=status, content={"error": error}, headers=headers or None)


async def _handle_app_error(request: Request, exc: Exception) -> JSONResponse:
    del request
    assert isinstance(exc, AppError)  # noqa: S101 - guardia de tipo para el dispatcher
    return _error_response(
        exc.status, exc.code, exc.message, exc.field, headers=exc.headers, reason=exc.reason
    )


async def _handle_validation_error(request: Request, exc: Exception) -> JSONResponse:
    del request
    assert isinstance(exc, RequestValidationError)  # noqa: S101
    errors = exc.errors()
    message = "Entrada invalida"
    field: str | None = None
    if errors:
        first = errors[0]
        loc = [str(part) for part in first.get("loc", ())]
        if loc and loc[0] in _LEADING_LOC_PREFIXES:
            loc = loc[1:]
        field = ".".join(loc) if loc else None
        message = str(first.get("msg", message))
    return _error_response(400, "validation_error", message, field)


async def _handle_http_exception(request: Request, exc: Exception) -> JSONResponse:
    del request
    assert isinstance(exc, StarletteHTTPException)  # noqa: S101
    if exc.status_code in (404, 405):
        return _error_response(404, "not_found", _MESSAGE_BY_CODE["not_found"])
    code = _STATUS_CODE_TO_CODE.get(exc.status_code)
    if code is None:
        # Status HTTP sin mapeo explicito: nunca se refleja tal cual (evita filtrar
        # semantica no contemplada); se degrada a 500 internal y se deja rastro para
        # detectar el hueco de mapeo.
        structlog.get_logger().warning("unmapped_http_exception", status=exc.status_code)
        return _error_response(500, "internal", _MESSAGE_BY_CODE["internal"])
    message = _MESSAGE_BY_CODE[code]
    headers = dict(exc.headers) if exc.headers else None
    return _error_response(exc.status_code, code, message, headers=headers)


async def _handle_unhandled_exception(request: Request, exc: Exception) -> JSONResponse:
    del request
    request_id = structlog.contextvars.get_contextvars().get("request_id")
    structlog.get_logger().exception("unhandled_error", request_id=request_id)
    return _error_response(500, "internal", _MESSAGE_BY_CODE["internal"])


def _make_module_handler(
    converter: Callable[[Exception], AppError],
) -> Callable[[Request, Exception], Awaitable[JSONResponse]]:
    async def _handler(request: Request, exc: Exception) -> JSONResponse:
        app_error = converter(exc)
        return await _handle_app_error(request, app_error)

    return _handler


def install_error_handlers(app: FastAPI, module_maps: Sequence[ExceptionMap] = ()) -> None:
    """Registra los manejadores de errores base y, opcionalmente, mapas por modulo."""
    app.add_exception_handler(AppError, _handle_app_error)
    app.add_exception_handler(RequestValidationError, _handle_validation_error)
    app.add_exception_handler(StarletteHTTPException, _handle_http_exception)
    app.add_exception_handler(Exception, _handle_unhandled_exception)

    for exception_map in module_maps:
        for exc_type, converter in exception_map.items():
            app.add_exception_handler(exc_type, _make_module_handler(converter))
