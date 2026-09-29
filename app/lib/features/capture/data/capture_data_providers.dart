import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/core/network/dio_providers.dart';
import 'package:finanzia/features/capture/data/capture_api.dart';
import 'package:finanzia/features/capture/data/drift_capture_grant_store.dart';
import 'package:finanzia/features/capture/data/method_channel_notification_source.dart';
import 'package:finanzia/features/capture/domain/capture_ports.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final captureApiProvider = Provider<CaptureApi>(
  (ref) => CaptureApi(ref.watch(apiDioProvider)),
);

/// Android lee notificaciones; iOS recibe los pagos con Apple Pay
/// (spec 003 §3, spec 006 §3.3).
final platformNotificationSourceProvider = Provider<NotificationSource>(
  (ref) => switch (defaultTargetPlatform) {
    _ when kIsWeb => const NoopNotificationSource(),
    TargetPlatform.android => MethodChannelNotificationSource(),
    TargetPlatform.iOS => IosWalletNotificationSource(),
    _ => const NoopNotificationSource(),
  },
);

final driftCaptureGrantStoreProvider = Provider<DriftCaptureGrantStore>(
  (ref) => DriftCaptureGrantStore(ref.watch(appDatabaseProvider)),
);
