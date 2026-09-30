import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:luka/features/push/domain/push_ports.dart';
import 'package:luka/features/recurring/domain/reminder_plan.dart';
import 'package:timezone/timezone.dart' as tz;

/// iPhone sin APNs (spec 011 §5.1): los recordatorios los programa el
/// teléfono. Implementa [PushService] (permiso y apertura desde el aviso,
/// sin token) y [ReminderScheduler].
class LocalReminderService implements PushService, ReminderScheduler {
  LocalReminderService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _opened = StreamController<PushOpen>.broadcast();
  Future<void>? _ready;

  static const _details = NotificationDetails(
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    ),
  );

  Future<void> _init() => _ready ??= _plugin.initialize(
    settings: const InitializationSettings(
      // El permiso se pide en contexto (spec 008 §3.8), no al iniciar.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
    onDidReceiveNotificationResponse: (response) {
      final open = _openFor(response.payload);
      if (open != null) _opened.add(open);
    },
  );

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  bool get isAvailable => true;

  @override
  String get platform => 'ios';

  @override
  Future<PushPermission> permission() async {
    await _init();
    final options = await _ios?.checkPermissions();
    if (options == null) return PushPermission.notDetermined;
    return options.isEnabled ? PushPermission.granted : PushPermission.denied;
  }

  @override
  Future<PushPermission> requestPermission() async {
    await _init();
    final granted = await _ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false ? PushPermission.granted : PushPermission.denied;
  }

  /// Sin APNs no hay token: el servidor no envía nada a este teléfono.
  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<PushOpen?> initialOpen() async {
    await _init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return _openFor(details.notificationResponse?.payload);
  }

  @override
  Stream<PushOpen> get onOpened => _opened.stream;

  /// En primer plano iOS muestra el aviso local igual (`presentBanner`).
  @override
  Stream<PushOpen> get onForeground => const Stream.empty();

  /// Al cerrar sesión: ningún aviso de la cuenta anterior queda programado.
  @override
  Future<void> deleteToken() async {
    await _init();
    await _plugin.cancelAll();
  }

  @override
  Future<void> replaceAll(List<LocalReminder> reminders) async {
    await _init();
    await _plugin.cancelAll();
    for (final reminder in reminders) {
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.UTC),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: reminder.occurrenceId,
        );
      } on Object catch (e) {
        // Un aviso que no se pudo programar no frena los demás. Solo el
        // tipo (P1).
        debugPrint('[recordatorios] programar: ${e.runtimeType}');
      }
    }
  }

  static PushOpen? _openFor(String? payload) =>
      payload == null || payload.isEmpty
      ? null
      : PushOpen(occurrenceId: payload);
}
