import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/auth/data/auth_api.dart';
import 'package:luka/features/auth/data/auth_repository_impl.dart';
import 'package:luka/features/auth/data/dtos/session_dto.dart';
import 'package:luka/features/auth/data/id_token_provider.dart';
import 'package:luka/features/auth/data/session_manager.dart';
import 'package:luka/features/auth/data/token_store.dart';
import 'package:luka/features/auth/domain/auth_failure.dart';
import 'package:luka/features/auth/domain/entities/user.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/stub_backend.dart';

class _MockIdTokens extends Mock implements IdTokenProvider {}

void main() {
  var now = DateTime.utc(2026, 9, 22, 12);
  late StubBackend backend;
  late _MockIdTokens idTokens;
  late SessionManager session;
  late AuthRepositoryImpl repository;

  setUp(() {
    now = DateTime.utc(2026, 9, 22, 12);
    FlutterSecureStorage.setMockInitialValues({});
    backend = StubBackend((_) => StubResponse(200, sessionJson()));
    idTokens = _MockIdTokens();
    when(
      () => idTokens.obtainIdToken(),
    ).thenAnswer((_) async => 'google-id-token-ana');
    when(() => idTokens.signOut()).thenAnswer((_) async {});
    final api = AuthApi(stubDio(backend));
    session = SessionManager(
      store: TokenStore(const FlutterSecureStorage()),
      api: api,
      now: () => now,
    );
    repository = AuthRepositoryImpl(
      idTokens: idTokens,
      api: api,
      session: session,
      deviceInfo: 'android test',
    );
  });

  group('signInWithGoogle', () {
    test('canjea el id_token y guarda la sesión', () async {
      final user = await repository.signInWithGoogle();

      expect(user.email, 'ana@example.com');
      expect(user.status, UserStatus.active);
      expect(user.greetingName, 'Ana');
      expect(backend.requests.single.path, '/v1/auth/google');
      expect(backend.requests.single.data, {
        'id_token': 'google-id-token-ana',
        'device_info': 'android test',
      });
      expect(await session.accessToken(), 'access-1');
    });

    test('cancelar en Google no llama al backend', () async {
      when(() => idTokens.obtainIdToken()).thenThrow(const AuthCancelled());
      await expectLater(
        repository.signInWithGoogle(),
        throwsA(isA<AuthCancelled>()),
      );
      expect(backend.requests, isEmpty);
    });

    final cases = <String, (StubHandler, Matcher)>{
      'sin red': ((r) => throw connectionError(r), isA<AuthNetworkFailure>()),
      '429': (
        (_) => StubResponse.error(
          429,
          'rate_limited',
          headers: {'retry-after': '30'},
        ),
        isA<AuthRateLimited>().having(
          (f) => f.retryAfter,
          'retryAfter',
          const Duration(seconds: 30),
        ),
      ),
      '401': (
        (_) => StubResponse.error(401, 'unauthorized'),
        isA<AuthRejected>(),
      ),
      '500': (
        (_) => StubResponse.error(500, 'internal'),
        isA<AuthUnexpected>(),
      ),
      'cuerpo fuera de contrato': (
        (_) => const StubResponse(200, {'access_token': 1}),
        isA<AuthUnexpected>(),
      ),
    };
    for (final MapEntry(key: name, value: (handler, matcher))
        in cases.entries) {
      test('backend $name → falla tipada, sin sesión', () async {
        backend.handler = handler;
        await expectLater(repository.signInWithGoogle(), throwsA(matcher));
        expect(await session.current(), isNull);
      });
    }
  });

  group('restoreSession', () {
    Future<void> seed({int expiresIn = 900}) =>
        session.save(SessionDto.fromJson(sessionJson(expiresIn: expiresIn)));

    test('sin sesión guardada → null', () async {
      expect(await repository.restoreSession(), isNull);
    });

    test('access vigente → usuario en caché, sin red', () async {
      await seed();
      expect((await repository.restoreSession())?.email, 'ana@example.com');
      expect(backend.requests, isEmpty);
    });

    test('access vencido → refresca', () async {
      await seed();
      now = now.add(const Duration(hours: 1));
      backend.handler = (_) => StubResponse(200, sessionJson(access: 'a-2'));
      expect(await repository.restoreSession(), isNotNull);
      expect(backend.countOf('/v1/auth/refresh'), 1);
      expect(await session.accessToken(), 'a-2');
    });

    test('refresh rechazado → null y sesión borrada', () async {
      await seed();
      now = now.add(const Duration(hours: 1));
      backend.handler = (_) => StubResponse.error(401, 'unauthorized');
      expect(await repository.restoreSession(), isNull);
      expect(await session.current(), isNull);
    });

    test('sin red → entra con el usuario en caché (P4)', () async {
      await seed();
      now = now.add(const Duration(hours: 1));
      backend.handler = (r) => throw connectionError(r);
      expect((await repository.restoreSession())?.email, 'ana@example.com');
      expect(await session.current(), isNotNull);
    });
  });

  group('signOut', () {
    test('revoca en el backend con el Bearer y borra todo', () async {
      await repository.signInWithGoogle();
      backend.handler = (_) => const StubResponse(204);

      await repository.signOut();

      final logout = backend.requests.last;
      expect(logout.path, '/v1/auth/logout');
      expect(logout.headers['Authorization'], 'Bearer access-1');
      expect(logout.data, {'refresh_token': 'refresh-1'});
      expect(await session.current(), isNull);
      verify(() => idTokens.signOut()).called(1);
    });

    test('sin red igual cierra la sesión local', () async {
      await repository.signInWithGoogle();
      backend.handler = (r) => throw connectionError(r);
      await repository.signOut();
      expect(await session.current(), isNull);
    });

    test('con access vencido refresca antes de revocar', () async {
      await repository.signInWithGoogle();
      now = now.add(const Duration(hours: 1));
      backend.handler = (r) => r.path == '/v1/auth/refresh'
          ? StubResponse(200, sessionJson(access: 'a-2', refresh: 'r-2'))
          : const StubResponse(204);

      await repository.signOut();

      final logout = backend.requests.last;
      expect(logout.headers['Authorization'], 'Bearer a-2');
      expect(logout.data, {'refresh_token': 'r-2'});
    });
  });
}
