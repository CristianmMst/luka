/// Por qué no se pudo exportar o borrar la cuenta.
sealed class PrivacyFailure implements Exception {
  const PrivacyFailure();
}

/// Sin conexión: exportar y borrar son solo en línea.
final class PrivacyOffline extends PrivacyFailure {
  const PrivacyOffline();
}

/// Cualquier otro fallo del servidor.
final class PrivacyUnexpected extends PrivacyFailure {
  const PrivacyUnexpected();
}

/// `GET/DELETE /v1/me*` del backend (spec 005 §2). Falla con
/// [PrivacyFailure].
abstract interface class PrivacyRemote {
  /// El JSON de la exportación, tal cual lo entrega el servidor.
  Future<String> exportData();

  /// Borra la cuenta y todos sus datos en el servidor (irreversible).
  Future<void> deleteAccount();
}

/// Entrega el archivo exportado al usuario (hoja de compartir del sistema).
// ignore: one_member_abstracts
abstract interface class ExportSaver {
  Future<void> save(String json, {required String fileName});
}
