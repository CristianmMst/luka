import 'package:finanzia/features/capture/domain/capture_ports.dart';
import 'package:finanzia/features/capture/domain/captured_notification.dart';
import 'package:flutter/services.dart';

/// Listener de Android (`android/app/src/main/kotlin/.../capture/`) visto
/// por su `MethodChannel`. El filtrado ocurre en nativo, antes de guardar
/// nada (spec 006 §3.2).
class MethodChannelNotificationSource implements NotificationSource {
  MethodChannelNotificationSource();

  static const _channel = MethodChannel('co.finanzia/capture');

  @override
  bool get isSupported => true;

  @override
  Future<bool> isPermissionGranted() async =>
      await _channel.invokeMethod<bool>('isPermissionGranted') ?? false;

  @override
  Future<void> openPermissionSettings() =>
      _channel.invokeMethod<void>('openPermissionSettings');

  @override
  Future<void> claimFor(String userId) =>
      _channel.invokeMethod<void>('claimFor', {'userId': userId});

  @override
  Future<void> setConfig(CaptureConfig config) =>
      _channel.invokeMethod<void>('setConfig', {
        'bankingApps': config.bankingApps,
        'messagesApps': config.messagesApps,
        'smsSenderPatterns': config.smsSenderPatterns,
      });

  @override
  Future<List<CapturedNotification>> pending(int limit) async {
    final rows =
        await _channel.invokeListMethod<Map<Object?, Object?>>('pending', {
          'limit': limit,
        }) ??
        const [];
    return [for (final row in rows) _decode(row)];
  }

  @override
  Future<void> remove(List<int> ids) =>
      _channel.invokeMethod<void>('remove', {'ids': ids});

  @override
  Future<void> clear() => _channel.invokeMethod<void>('clear');

  CapturedNotification _decode(Map<Object?, Object?> row) =>
      CapturedNotification(
        id: row['id']! as int,
        package: row['package']! as String,
        channel: switch (row['channel']) {
          'notification' => CaptureChannel.notification,
          'sms_notification' => CaptureChannel.smsNotification,
          _ => throw const FormatException('canal de captura desconocido'),
        },
        postedAt: DateTime.fromMillisecondsSinceEpoch(
          row['postedAtMs']! as int,
          isUtc: true,
        ),
        utcOffset: Duration(minutes: row['offsetMinutes']! as int),
        title: row['title'] as String?,
        text: row['text']! as String,
      );
}

/// iOS no deja leer notificaciones de otras apps: todo es no-op.
class NoopNotificationSource implements NotificationSource {
  const NoopNotificationSource();

  @override
  bool get isSupported => false;

  @override
  Future<bool> isPermissionGranted() async => false;

  @override
  Future<void> openPermissionSettings() async {}

  @override
  Future<void> claimFor(String userId) async {}

  @override
  Future<void> setConfig(CaptureConfig config) async {}

  @override
  Future<List<CapturedNotification>> pending(int limit) async => const [];

  @override
  Future<void> remove(List<int> ids) async {}

  @override
  Future<void> clear() async {}
}
