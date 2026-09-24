import 'package:finanzia/features/gmail/domain/gmail_connection.dart';

/// Puerto de la conexión de Gmail. Las operaciones fallan con
/// `GmailFailure`.
abstract interface class GmailRepository {
  /// Estado guardado en el backend.
  Future<GmailConnectionInfo> status();

  /// Pide al usuario permiso de lectura de Gmail (consentimiento de Google)
  /// y entrega el `serverAuthCode` al backend, que guarda el refresh token
  /// y crea el watch. Cancelar el consentimiento lanza
  /// `GmailConsentCancelled`.
  Future<GmailConnectionInfo> connect();

  /// Detiene la captura y borra la conexión; las transacciones se quedan.
  Future<void> disconnect();
}
