import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/core/network/dio_providers.dart';
import 'package:luka/features/push/data/firebase_push_service.dart';
import 'package:luka/features/push/data/push_token_api.dart';

/// Si Firebase inició en `main()`; se sobrescribe allí con el resultado.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final firebasePushServiceProvider = Provider<FirebasePushService>(
  (ref) => FirebasePushService(available: ref.watch(firebaseReadyProvider)),
);

final pushTokenApiProvider = Provider<PushTokenApi>(
  (ref) => PushTokenApi(ref.watch(apiDioProvider)),
);

final driftPushPrefsProvider = Provider<DriftPushPrefs>(
  (ref) => DriftPushPrefs(ref.watch(appDatabaseProvider)),
);
