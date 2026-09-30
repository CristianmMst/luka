import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/core/network/dio_providers.dart';
import 'package:luka/features/push/data/firebase_push_service.dart';
import 'package:luka/features/push/data/local_reminder_service.dart';
import 'package:luka/features/push/data/push_token_api.dart';
import 'package:luka/features/push/domain/push_ports.dart';
import 'package:luka/features/recurring/domain/reminder_plan.dart';

/// Si Firebase inició en `main()`; se sobrescribe allí con el resultado.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final firebasePushServiceProvider = Provider<FirebasePushService>(
  (ref) => FirebasePushService(available: ref.watch(firebaseReadyProvider)),
);

/// Avisos locales de iPhone (spec 011 §5.1).
final localReminderServiceProvider = Provider<LocalReminderService>(
  (ref) => LocalReminderService(),
);

/// iPhone programa los avisos en el teléfono; Android usa FCM (ADR-9).
bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

final platformPushServiceProvider = Provider<PushService>(
  (ref) => _isIos
      ? ref.watch(localReminderServiceProvider)
      : ref.watch(firebasePushServiceProvider),
);

final platformReminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => _isIos
      ? ref.watch(localReminderServiceProvider)
      : const NoReminderScheduler(),
);

final pushTokenApiProvider = Provider<PushTokenApi>(
  (ref) => PushTokenApi(ref.watch(apiDioProvider)),
);

final driftPushPrefsProvider = Provider<DriftPushPrefs>(
  (ref) => DriftPushPrefs(ref.watch(appDatabaseProvider)),
);
