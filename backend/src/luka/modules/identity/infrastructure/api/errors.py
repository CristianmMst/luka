"""Mapa de errores de dominio de identity -> `AppError` HTTP (spec 005 SS1, ruling 7).

Todos los errores de dominio de autenticacion se degradan a 401 `unauthorized`
generico: nunca se distingue en la respuesta el motivo exacto (token invalido,
email no verificado, refresh desconocido/reusado/vencido o usuario inexistente)
para no filtrar informacion util a un atacante.
"""

from luka.modules.identity.domain.errors import (
    EmailNotVerified,
    InvalidGoogleToken,
    RefreshTokenExpired,
    RefreshTokenInvalid,
    RefreshTokenReused,
    UserNotFound,
)
from luka.shared.errors import ExceptionMap, UnauthorizedError

EXCEPTION_MAP: ExceptionMap = {
    InvalidGoogleToken: lambda e: UnauthorizedError(),
    EmailNotVerified: lambda e: UnauthorizedError(),
    RefreshTokenInvalid: lambda e: UnauthorizedError(),
    RefreshTokenReused: lambda e: UnauthorizedError(),
    RefreshTokenExpired: lambda e: UnauthorizedError(),
    UserNotFound: lambda e: UnauthorizedError(),
}
