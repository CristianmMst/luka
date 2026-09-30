/// Por qué no se pudo conectar, consultar o desconectar Gmail.
sealed class GmailFailure implements Exception {
  const GmailFailure();
}

/// El usuario cerró la pantalla de consentimiento. No es un error que
/// mostrar.
final class GmailConsentCancelled extends GmailFailure {
  const GmailConsentCancelled();
}

/// Sin conexión con el backend.
final class GmailNetworkFailure extends GmailFailure {
  const GmailNetworkFailure();
}

/// El backend no pudo hablar con Google (`503 upstream_unavailable`).
final class GmailUpstreamUnavailable extends GmailFailure {
  const GmailUpstreamUnavailable();
}

/// Demasiados intentos (`429`).
final class GmailRateLimited extends GmailFailure {
  const GmailRateLimited([this.retryAfter]);

  final Duration? retryAfter;
}

/// Google rechazó el `serverAuthCode` (inválido, vencido o ya usado). Pedir
/// un código nuevo, es decir volver a intentarlo, lo arregla.
final class GmailCodeRejected extends GmailFailure {
  const GmailCodeRejected();
}

/// Google no entregó refresh token al canjear el código. Volver a intentarlo
/// fuerza de nuevo el consentimiento con acceso offline.
final class GmailRefreshTokenMissing extends GmailFailure {
  const GmailRefreshTokenMissing();
}

/// El usuario desmarcó el permiso de lectura de Gmail en el consentimiento.
final class GmailScopeDenied extends GmailFailure {
  const GmailScopeDenied();
}

/// Google Sign-In no está configurado en este build (falta el client ID) o
/// la plataforma no soporta la autorización.
final class GmailMisconfigured extends GmailFailure {
  const GmailMisconfigured(this.detail);

  final String detail;
}

final class GmailUnexpected extends GmailFailure {
  const GmailUnexpected([this.cause, this.code]);

  final Object? cause;

  /// Código corto y sin datos de la cuenta (p. ej. `uiUnavailable`) que la
  /// app muestra para diagnosticar desde el teléfono.
  final String? code;
}
