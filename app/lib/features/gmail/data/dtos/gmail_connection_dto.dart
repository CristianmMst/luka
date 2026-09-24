import 'package:finanzia/features/gmail/domain/gmail_connection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gmail_connection_dto.g.dart';

/// `GmailStatusResponse` de `GET /v1/gmail/status` y `GmailConnectResponse`
/// de `POST /v1/gmail/connect` (`ingestion/infrastructure/api/schemas.py`).
/// El connect no trae `last_sync_at`.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class GmailConnectionDto {
  const GmailConnectionDto({
    required this.status,
    this.email,
    this.lastSyncAt,
    this.watchExpiresAt,
  });

  factory GmailConnectionDto.fromJson(Map<String, dynamic> json) =>
      _$GmailConnectionDtoFromJson(json);

  final String status;
  final String? email;
  final DateTime? lastSyncAt;
  final DateTime? watchExpiresAt;

  GmailConnectionInfo toDomain() => GmailConnectionInfo(
    status: switch (status) {
      'active' => GmailStatus.active,
      'revoked' => GmailStatus.revoked,
      'disconnected' => GmailStatus.disconnected,
      // `error` y cualquier estado nuevo que la app no conozca: la conexión
      // existe pero no está sana, así que se ofrece reconectar.
      _ => GmailStatus.error,
    },
    email: email,
    lastSyncAt: lastSyncAt,
    watchExpiresAt: watchExpiresAt,
  );
}
