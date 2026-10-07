/// Por qué no se pudo borrar la cuenta.
sealed class PrivacyFailure implements Exception {
  const PrivacyFailure();
}

/// Sin conexión: borrar la cuenta es solo en línea.
final class PrivacyOffline extends PrivacyFailure {
  const PrivacyOffline();
}

/// Cualquier otro fallo del servidor.
final class PrivacyUnexpected extends PrivacyFailure {
  const PrivacyUnexpected();
}

/// `DELETE /v1/me` del backend (spec 005 §2). Falla con [PrivacyFailure].
// ignore: one_member_abstracts
abstract interface class PrivacyRemote {
  /// Borra la cuenta y todos sus datos en el servidor (irreversible).
  Future<void> deleteAccount();
}
