@Tags(['backend'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:finanzia/core/network/auth_interceptor.dart';
import 'package:finanzia/core/network/dio_providers.dart';
import 'package:finanzia/core/network/session_bridge.dart';
import 'package:finanzia/features/auth/data/auth_api.dart';
import 'package:finanzia/features/auth/data/auth_repository_impl.dart';
import 'package:finanzia/features/auth/data/id_token_provider.dart';
import 'package:finanzia/features/auth/data/session_manager.dart';
import 'package:finanzia/features/auth/data/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrato de la feature auth contra el backend real.
///
/// Requiere la API local con `FINANZIA_GOOGLE_VERIFIER=fake`:
///   FINANZIA_API_URL=http://localhost:8000 flutter test --tags backend
void main() {
  final baseUrl = Platform.environment['FINANZIA_API_URL'];
  final skip = baseUrl == null ? 'Define FINANZIA_API_URL' : null;

  var now = DateTime.now().toUtc();
  late AuthApi api;
  late SessionManager session;
  late AuthRepositoryImpl repository;
  late Dio apiDio;

  setUp(() {
    now = DateTime.now().toUtc();
    FlutterSecureStorage.setMockInitialValues({});
    api = AuthApi(buildDio(baseUrl ?? ''));
    session = SessionManager(
      store: TokenStore(const FlutterSecureStorage()),
      api: api,
      deviceInfo: 'contract-test',
      now: () => now,
    );
    final email = 'contrato-${now.microsecondsSinceEpoch}@finanzia.local';
    repository = AuthRepositoryImpl(
      idTokens: FakeIdTokenProvider(email: email),
      api: api,
      session: session,
      deviceInfo: 'contract-test',
    );
    apiDio = buildDio(baseUrl ?? '');
    apiDio.interceptors.add(AuthInterceptor(dio: apiDio, session: session));
  });

  test('login → /me → refresh → logout', skip: skip, () async {
    final user = await repository.signInWithGoogle();
    expect(user.email, startsWith('contrato-'));

    final me = await apiDio.get<Map<String, dynamic>>('/v1/me');
    expect(me.data?['email'], user.email);
    expect(me.data?['connections'], isA<Map<String, dynamic>>());

    final before = await session.current();
    expect(await session.refresh(), RefreshOutcome.refreshed);
    final after = await session.current();
    expect(after?.refreshToken, isNot(before?.refreshToken));

    // Abrir la app una hora después: restore refresca contra el backend.
    now = now.add(const Duration(hours: 1));
    final restored = await repository.restoreSession();
    expect(restored?.email, user.email);
    now = DateTime.now().toUtc();

    final revoked = (await session.current())!.refreshToken;
    await repository.signOut();
    expect(await session.current(), isNull);

    // El refresh token revocado ya no sirve.
    await expectLater(
      api.refresh(refreshToken: revoked),
      throwsA(anything),
    );
  });
}
