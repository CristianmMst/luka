import 'dart:io';

import 'package:finanzia/core/config/app_config.dart';
import 'package:finanzia/core/network/dio_providers.dart';
import 'package:finanzia/core/storage/secure_storage_provider.dart';
import 'package:finanzia/features/auth/data/auth_api.dart';
import 'package:finanzia/features/auth/data/auth_repository_impl.dart';
import 'package:finanzia/features/auth/data/id_token_provider.dart';
import 'package:finanzia/features/auth/data/session_manager.dart';
import 'package:finanzia/features/auth/data/token_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `device_info` para las sesiones del backend (máx. 200 caracteres).
final deviceInfoProvider = Provider<String?>((ref) {
  final info = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  return info.length > 200 ? info.substring(0, 200) : info;
});

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(ref.watch(secureStorageProvider)),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(publicDioProvider)),
);

final sessionManagerProvider = Provider<SessionManager>((ref) {
  final manager = SessionManager(
    store: ref.watch(tokenStoreProvider),
    api: ref.watch(authApiProvider),
    deviceInfo: ref.watch(deviceInfoProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

final idTokenProviderProvider = Provider<IdTokenProvider>(
  (ref) => GoogleIdTokenProvider(
    serverClientId: ref.watch(appConfigProvider).googleServerClientId,
  ),
);

final authRepositoryImplProvider = Provider<AuthRepositoryImpl>(
  (ref) => AuthRepositoryImpl(
    idTokens: ref.watch(idTokenProviderProvider),
    api: ref.watch(authApiProvider),
    session: ref.watch(sessionManagerProvider),
    deviceInfo: ref.watch(deviceInfoProvider),
  ),
);
