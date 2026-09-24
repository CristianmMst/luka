import 'package:freezed_annotation/freezed_annotation.dart';

part 'gmail_connection.freezed.dart';

/// Estado de la conexión de Gmail (spec 005 §3, spec 004 §2.3).
///
/// - `active`: el watch está vivo y llegan los correos del banco.
/// - `revoked`: Google revocó el permiso; hay que reconectar.
/// - `error`: la conexión existe pero el watch falló; el backend lo reintenta
///   a diario y reconectar también la arregla.
/// - `disconnected`: el usuario nunca conectó Gmail o lo desconectó.
enum GmailStatus { active, revoked, error, disconnected }

/// Conexión de Gmail del usuario, espejo de `GET /v1/gmail/status`.
/// [email] es la cuenta Gmail conectada, que puede diferir de la del login.
@freezed
abstract class GmailConnectionInfo with _$GmailConnectionInfo {
  const factory GmailConnectionInfo({
    required GmailStatus status,
    String? email,
    DateTime? lastSyncAt,
    DateTime? watchExpiresAt,
  }) = _GmailConnectionInfo;

  const GmailConnectionInfo._();

  static const disconnected = GmailConnectionInfo(
    status: GmailStatus.disconnected,
  );

  /// Hay una conexión guardada en el backend, sana o no.
  bool get isConnected => status != GmailStatus.disconnected;

  /// La conexión existe pero no captura correos: toca reconectar.
  bool get needsReconnect =>
      status == GmailStatus.revoked || status == GmailStatus.error;
}
