import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'captured_notification.freezed.dart';

/// Canal de `POST /v1/ingest/notifications` (spec 005 §5): la notificación
/// de una app bancaria o el SMS que llega como notificación de Mensajes.
enum CaptureChannel { notification, smsNotification }

/// Notificación que el listener nativo ya filtró (spec 006 §3.2) y guardó en
/// su cola local, pendiente de enviar.
@freezed
abstract class CapturedNotification with _$CapturedNotification {
  const factory CapturedNotification({
    /// Id de la fila en la cola nativa, para sacarla tras enviarla.
    required int id,
    required String package,
    required CaptureChannel channel,

    /// Instante en que se publicó, en UTC.
    required DateTime postedAt,

    /// Zona del teléfono en ese momento: el backend exige `posted_at` con
    /// zona horaria.
    required Duration utcOffset,

    /// `bigText` si la notificación lo trae; si no, `text`.
    required String text,

    /// En SMS es el remitente: el backend re-valida el patrón sobre él.
    String? title,
  }) = _CapturedNotification;

  const CapturedNotification._();

  /// `external_id` del canal (spec 006 §3.2): sha256 de
  /// `paquete|minuto|texto`, con el minuto UTC de [postedAt]. Una
  /// notificación re-publicada en el mismo minuto da el mismo hash y el
  /// backend la cuenta como duplicada.
  String get clientHash {
    final minute = postedAt.millisecondsSinceEpoch ~/ 60000;
    return sha256.convert(utf8.encode('$package|$minute|$text')).toString();
  }
}

/// Paquetes y remitentes soportados, espejo de `GET /v1/config/capture`
/// (spec 006 §3.1). El listener nativo filtra con ella.
@freezed
abstract class CaptureConfig with _$CaptureConfig {
  const factory CaptureConfig({
    required int version,
    required List<String> bankingApps,
    required List<String> messagesApps,

    /// Regex con flags en línea (`(?i)…`), aplicadas al título de la
    /// notificación de Mensajes.
    required List<String> smsSenderPatterns,
  }) = _CaptureConfig;
}

/// Respuesta de `POST /v1/ingest/notifications`.
typedef IngestResult = ({int accepted, int duplicates, int discarded});
