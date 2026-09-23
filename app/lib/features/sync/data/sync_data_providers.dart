import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/core/network/dio_providers.dart';
import 'package:finanzia/features/sync/data/drift_sync_store.dart';
import 'package:finanzia/features/sync/data/platform_signals.dart';
import 'package:finanzia/features/sync/data/sync_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncApiProvider = Provider<SyncApi>(
  (ref) => SyncApi(ref.watch(apiDioProvider)),
);

final driftSyncStoreProvider = Provider<DriftSyncStore>(
  (ref) => DriftSyncStore(ref.watch(appDatabaseProvider)),
);

final connectivityStreamProvider = Provider<Stream<bool>>(
  (ref) => connectivityStream(Connectivity()),
);

final foregroundTicksStreamProvider = Provider<Stream<void>>(
  (ref) => foregroundTicks(),
);
