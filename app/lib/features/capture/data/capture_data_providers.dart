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

/// El listener existe solo en Android (spec 003 §3).
final platformNotificationSourceProvider = Provider<NotificationSource>(
  (ref) => defaultTargetPlatform == TargetPlatform.android && !kIsWeb
      ? MethodChannelNotificationSource()
      : const NoopNotificationSource(),
);

final driftCaptureGrantStoreProvider = Provider<DriftCaptureGrantStore>(
  (ref) => DriftCaptureGrantStore(ref.watch(appDatabaseProvider)),
);
