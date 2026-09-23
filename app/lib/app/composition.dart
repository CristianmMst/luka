import 'package:finanzia/core/network/dio_providers.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/data/auth_data_providers.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/data/sync_data_providers.dart';
import 'package:flutter_riverpod/misc.dart';

/// Raíz de composición: conecta los puertos de `core` y de las capas de
/// aplicación con sus implementaciones en `data`. Es el único lugar donde
/// `application` y `data` se encuentran.
List<Override> get appOverrides => [
  sessionBridgeProvider.overrideWith(
    (ref) => ref.watch(sessionManagerProvider),
  ),
  authRepositoryProvider.overrideWith(
    (ref) => ref.watch(authRepositoryImplProvider),
  ),
  syncStoreProvider.overrideWith((ref) => ref.watch(driftSyncStoreProvider)),
  syncRemoteProvider.overrideWith((ref) => ref.watch(syncApiProvider)),
  connectivityProvider.overrideWith(
    (ref) => ref.watch(connectivityStreamProvider),
  ),
  foregroundTicksProvider.overrideWith(
    (ref) => ref.watch(foregroundTicksStreamProvider),
  ),
];
