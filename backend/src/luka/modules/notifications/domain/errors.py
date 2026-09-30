"""Errores de dominio de notifications."""


class NotificationsError(Exception):
    """Base de los errores de notifications."""


class InvalidPushToken(NotificationsError):  # noqa: N818 - nombre de dominio
    """Token vacio o de mas de 4096 caracteres (400, `field=token`)."""


class PushUnavailable(NotificationsError):  # noqa: N818 - nombre de dominio
    """FCM no respondio o respondio 429/5xx: el bus reintenta el evento."""
