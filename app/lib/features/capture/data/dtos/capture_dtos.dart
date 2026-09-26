import 'package:finanzia/features/capture/domain/captured_notification.dart';
import 'package:json_annotation/json_annotation.dart';

part 'capture_dtos.g.dart';

/// `CaptureConfigResponse` de `GET /v1/config/capture`
/// (`ingestion/infrastructure/api/schemas.py`). `email_senders` no le sirve
/// al listener y se ignora.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class CaptureConfigDto {
  const CaptureConfigDto({
    required this.version,
    required this.bankingApps,
    required this.messagesApps,
    required this.smsSenderPatterns,
  });

  factory CaptureConfigDto.fromJson(Map<String, dynamic> json) =>
      _$CaptureConfigDtoFromJson(json);

  final int version;
  final List<String> bankingApps;
  final List<String> messagesApps;
  final List<String> smsSenderPatterns;

  CaptureConfig toDomain() => CaptureConfig(
    version: version,
    bankingApps: bankingApps,
    messagesApps: messagesApps,
    smsSenderPatterns: smsSenderPatterns,
  );
}

/// Un ítem de `POST /v1/ingest/notifications` (spec 005 §5).
@JsonSerializable(
  fieldRename: FieldRename.snake,
  createFactory: false,
  includeIfNull: false,
)
class IngestItemDto {
  const IngestItemDto({
    required this.package,
    required this.channel,
    required this.postedAt,
    required this.text,
    required this.clientHash,
    this.title,
  });

  factory IngestItemDto.fromDomain(CapturedNotification n) => IngestItemDto(
    package: n.package,
    channel: switch (n.channel) {
      CaptureChannel.notification => 'notification',
      CaptureChannel.smsNotification => 'sms_notification',
    },
    postedAt: _isoWithOffset(n.postedAt, n.utcOffset),
    title: n.title,
    text: n.text,
    clientHash: n.clientHash,
  );

  final String package;
  final String channel;

  /// ISO 8601 con la zona del teléfono: el backend rechaza fechas sin zona.
  final String postedAt;
  final String? title;
  final String text;
  final String clientHash;

  Map<String, dynamic> toJson() => _$IngestItemDtoToJson(this);
}

/// `IngestNotificationsResponse`.
@JsonSerializable(createToJson: false)
class IngestResultDto {
  const IngestResultDto({
    required this.accepted,
    required this.duplicates,
    required this.discarded,
  });

  factory IngestResultDto.fromJson(Map<String, dynamic> json) =>
      _$IngestResultDtoFromJson(json);

  final int accepted;
  final int duplicates;
  final int discarded;

  IngestResult toDomain() =>
      (accepted: accepted, duplicates: duplicates, discarded: discarded);
}

/// `2026-08-05T14:30:05-05:00`: la hora local de [instant] en [offset].
String _isoWithOffset(DateTime instant, Duration offset) {
  final local = instant.toUtc().add(offset);
  String two(int v) => v.toString().padLeft(2, '0');
  final sign = offset.isNegative ? '-' : '+';
  final minutes = offset.inMinutes.abs();
  return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-'
      '${two(local.day)}T${two(local.hour)}:${two(local.minute)}:'
      '${two(local.second)}$sign${two(minutes ~/ 60)}:${two(minutes % 60)}';
}
