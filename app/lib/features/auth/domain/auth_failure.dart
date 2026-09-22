/// Por qué no se pudo iniciar o mantener la sesión.
sealed class AuthFailure implements Exception {
  const AuthFailure();
}

/// El usuario cerró la ventana de Google. No es un error que mostrar.
final class AuthCancelled extends AuthFailure {
  const AuthCancelled();
}

/// Sin conexión con Google o con el backend.
final class AuthNetworkFailure extends AuthFailure {
  const AuthNetworkFailure();
}

/// Demasiados intentos (`429`); `retryAfter` viene de la cabecera.
final class AuthRateLimited extends AuthFailure {
  const AuthRateLimited([this.retryAfter]);

  final Duration? retryAfter;
}

/// El backend rechazó la credencial (token de Google inválido o sesión
/// revocada).
final class AuthRejected extends AuthFailure {
  const AuthRejected();
}

/// Google Sign-In no está configurado en este build (falta client ID).
final class AuthMisconfigured extends AuthFailure {
  const AuthMisconfigured(this.detail);

  final String detail;
}

final class AuthUnexpected extends AuthFailure {
  const AuthUnexpected([this.cause]);

  final Object? cause;
}
