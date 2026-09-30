"""Errores de dominio de identity (sin dependencias de framework, P3)."""

from uuid import UUID


class IdentityError(Exception):
    """Base de todos los errores de dominio del modulo identity."""


class InvalidGoogleToken(IdentityError):  # noqa: N818 - nombre fijado por spec 009 SS2.1
    """El `id_token` de Google no pudo verificarse (firma, `aud`, `iss` o `exp`)."""


class EmailNotVerified(IdentityError):  # noqa: N818 - nombre fijado por spec 009 SS2.1
    """Google reporta el email de la identidad como no verificado."""


class RefreshTokenInvalid(IdentityError):  # noqa: N818 - nombre fijado por spec 009 SS2.2
    """El refresh token presentado no existe (desconocido)."""


class RefreshTokenReused(IdentityError):  # noqa: N818 - nombre fijado por spec 009 SS2.2
    """Se presento un refresh token ya rotado: posible robo (spec 009 AC-1.4)."""

    def __init__(self, family_id: UUID) -> None:
        super().__init__(f"refresh token reused for family {family_id}")
        self.family_id = family_id


class RefreshTokenExpired(IdentityError):  # noqa: N818 - nombre fijado por spec 009 SS2.2
    """El refresh token presentado ya vencio."""


class UserNotFound(IdentityError):  # noqa: N818 - nombre fijado por spec 009 SS2.1
    """No existe un usuario con el identificador solicitado."""
