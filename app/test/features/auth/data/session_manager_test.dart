import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/network/auth_interceptor.dart';
import 'package:luka/core/network/session_bridge.dart';
import 'package:luka/features/auth/data/auth_api.dart';
import 'package:luka/features/auth/data/dtos/session_dto.dart';
import 'package:luka/features/auth/data/session_manager.dart';
import 'package:luka/features/auth/data/token_store.dart';

import '../../../helpers/stub_backend.dart';

void main() {
  final now = DateTime.utc(2026, 9, 22, 12);
  late StubBackend authBackend;
  late SessionManager manager;
  late TokenStore store;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = TokenStore(const FlutterSecureStorage());
    authBackend = StubBackend(
      (_) => StubResponse(
        200,
        sessionJson(access: 'access-2', refresh: 'refresh-2'),
      ),
    );
    manager = SessionManager(
      store: store,
      api: AuthApi(stubDio(authBackend)),
      deviceInfo: 'android test',
      now: () => now,
    );
  });

  tearDown(() => manager.dispose());

  Future<void> seedSession() =>
      manager.save(SessionDto.fromJson(sessionJson()));

  test('save persiste tokens y calcula el vencimiento', () async {
    await seedSession();
    final stored = await store.read();
    expect(stored?.accessToken, 'access-1');
    expect(stored?.accessExpiresAt, now.add(const Duration(seconds: 900)));
    expect(await manager.accessToken(), 'access-1');
  });

  test('refresh rota los tokens y manda device_info', () async {
    await seedSession();
    expect(await manager.refresh(), RefreshOutcome.refreshed);
    expect(await manager.accessToken(), 'access-2');
    expect((await store.read())?.refreshToken, 'refresh-2');
    expect(authBackend.requests.single.data, {
      'refresh_token': 'refresh-1',
      'device_info': 'android test',
    });
  });

  test('refresh sin sesión guardada es rejected', () async {
    expect(await manager.refresh(), RefreshOutcome.rejected);
    expect(authBackend.requests, isEmpty);
  });

  test('401 del refresh es rejected; sin red es unavailable', () async {
    await seedSession();
    authBackend.handler = (_) => StubResponse.error(401, 'unauthorized');
    expect(await manager.refresh(), RefreshOutcome.rejected);

    authBackend.handler = (r) => throw connectionError(r);
    expect(await manager.refresh(), RefreshOutcome.unavailable);

    authBackend.handler = (_) => StubResponse.error(500, 'internal');
    expect(await manager.refresh(), RefreshOutcome.unavailable);
  });

  test('expire borra la sesión y avisa una sola vez', () async {
    await seedSession();
    final events = <void>[];
    final sub = manager.expired.listen(events.add);

    await manager.expire();
    await manager.expire(); // ya no hay sesión: no vuelve a avisar
    await pumpEventQueue();

    expect(events, hasLength(1));
    expect(await store.read(), isNull);
    await sub.cancel();
  });

  test('TokenStore descarta un blob corrupto', () async {
    FlutterSecureStorage.setMockInitialValues({'luka.session.v1': '{mal'});
    expect(await TokenStore(const FlutterSecureStorage()).read(), isNull);
  });

  test(
    'extremo a extremo: 3 peticiones con access vencido → un solo refresh',
    () async {
      await seedSession();
      final gate = Completer<void>();
      authBackend.handler = (_) async {
        await gate.future;
        return StubResponse(
          200,
          sessionJson(access: 'access-2', refresh: 'refresh-2'),
        );
      };
      final apiBackend = StubBackend(
        (r) => r.headers['Authorization'] == 'Bearer access-2'
            ? const StubResponse(200, {'ok': true})
            : StubResponse.error(401, 'token_expired'),
      );
      final api = stubDio(apiBackend);
      api.interceptors.add(AuthInterceptor(dio: api, session: manager));

      final calls = [
        for (var i = 0; i < 3; i++) api.get<void>('/v1/transactions'),
      ];
      await pumpEventQueue();
      gate.complete();
      final responses = await Future.wait<Response<void>>(calls);

      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(authBackend.countOf('/v1/auth/refresh'), 1);
    },
  );
}
