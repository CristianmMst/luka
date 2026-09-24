import 'dart:convert';

import 'package:finanzia/features/gmail/data/gmail_api.dart';
import 'package:finanzia/features/gmail/data/gmail_authorizer.dart';
import 'package:finanzia/features/gmail/data/gmail_repository_impl.dart';
import 'package:finanzia/features/gmail/domain/gmail_connection.dart';
import 'package:finanzia/features/gmail/domain/gmail_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/stub_backend.dart';

class _MockAuthorizer extends Mock implements GmailAuthorizer {}

/// Sobre de error de `POST /v1/gmail/connect` con el mensaje real del
/// backend (`ingestion/infrastructure/api/errors.py`) y, si se da, su
/// `reason`.
StubResponse _codeError(String message, {String? reason}) => StubResponse(400, {
  'error': {
    'code': 'validation_error',
    'message': message,
    'field': 'server_auth_code',
    'reason': ?reason,
  },
});

void main() {
  late _MockAuthorizer authorizer;
  late StubBackend backend;
  late GmailRepositoryImpl repository;

  setUp(() {
    authorizer = _MockAuthorizer();
    when(
      () => authorizer.obtainServerAuthCode(),
    ).thenAnswer((_) async => '4/code');
    backend = StubBackend((_) => const StubResponse(500));
    repository = GmailRepositoryImpl(
      authorizer: authorizer,
      api: GmailApi(stubDio(backend)),
    );
  });

  group('status', () {
    test('lee GET /v1/gmail/status', () async {
      backend.handler = (_) => const StubResponse(200, {
        'status': 'active',
        'email': 'ana@gmail.com',
        'last_sync_at': '2026-09-24T10:00:00Z',
        'watch_expires_at': '2026-10-01T10:00:00Z',
      });

      final info = await repository.status();

      expect(backend.requests.single.method, 'GET');
      expect(backend.requests.single.path, '/v1/gmail/status');
      expect(
        info,
        GmailConnectionInfo(
          status: GmailStatus.active,
          email: 'ana@gmail.com',
          lastSyncAt: DateTime.utc(2026, 9, 24, 10),
          watchExpiresAt: DateTime.utc(2026, 10, 1, 10),
        ),
      );
    });

    test('mapea cada estado del contrato', () async {
      const cases = {
        'active': GmailStatus.active,
        'revoked': GmailStatus.revoked,
        'error': GmailStatus.error,
        'disconnected': GmailStatus.disconnected,
        'algo_nuevo': GmailStatus.error,
      };
      for (final MapEntry(:key, :value) in cases.entries) {
        backend.handler = (_) => StubResponse(200, {
          'status': key,
          'email': null,
          'last_sync_at': null,
          'watch_expires_at': null,
        });
        expect((await repository.status()).status, value, reason: key);
      }
    });

    test('sin red → GmailNetworkFailure', () async {
      backend.handler = (r) => throw connectionError(r);
      await expectLater(
        repository.status(),
        throwsA(isA<GmailNetworkFailure>()),
      );
    });

    test('cuerpo fuera de contrato → GmailUnexpected', () async {
      backend.handler = (_) => const StubResponse(200, {'status': 3});
      await expectLater(
        repository.status(),
        throwsA(isA<GmailUnexpected>()),
      );
    });

    test('cuerpo vacío → GmailUnexpected', () async {
      backend.handler = (_) => const StubResponse(200);
      await expectLater(
        repository.status(),
        throwsA(isA<GmailUnexpected>()),
      );
    });
  });

  group('connect', () {
    test('envía el serverAuthCode y devuelve la conexión', () async {
      backend.handler = (_) => const StubResponse(200, {
        'status': 'active',
        'email': 'ana@gmail.com',
        'watch_expires_at': '2026-10-01T10:00:00Z',
      });

      final info = await repository.connect();

      final request = backend.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/v1/gmail/connect');
      final body = request.data is String
          ? jsonDecode(request.data as String)
          : request.data;
      expect(body, {'server_auth_code': '4/code'});
      expect(info.status, GmailStatus.active);
      expect(info.email, 'ana@gmail.com');
      expect(info.lastSyncAt, isNull);
      expect(info.watchExpiresAt, DateTime.utc(2026, 10, 1, 10));
    });

    test('watch fallido: 200 con status error', () async {
      backend.handler = (_) => const StubResponse(200, {
        'status': 'error',
        'email': 'ana@gmail.com',
        'watch_expires_at': null,
      });
      final info = await repository.connect();
      expect(info.status, GmailStatus.error);
      expect(info.needsReconnect, isTrue);
    });

    test('cancelar el consentimiento no llama al backend', () async {
      when(
        () => authorizer.obtainServerAuthCode(),
      ).thenThrow(const GmailConsentCancelled());
      await expectLater(
        repository.connect(),
        throwsA(isA<GmailConsentCancelled>()),
      );
      expect(backend.requests, isEmpty);
    });

    test('distingue los tres 400 de server_auth_code por reason', () async {
      final cases = <String, Matcher>{
        'invalid_code': isA<GmailCodeRejected>(),
        'refresh_token_missing': isA<GmailRefreshTokenMissing>(),
        'scope_not_granted': isA<GmailScopeDenied>(),
      };
      for (final MapEntry(:key, :value) in cases.entries) {
        // El mensaje no decide: con reason, se ignora.
        backend.handler = (_) => _codeError('otro texto', reason: key);
        await expectLater(repository.connect(), throwsA(value), reason: key);
      }
    });

    test('reason desconocido cae al mensaje', () async {
      backend.handler = (_) => _codeError(
        'permiso de Gmail no concedido: la app debe pedir gmail.readonly',
        reason: 'motivo_nuevo',
      );
      await expectLater(repository.connect(), throwsA(isA<GmailScopeDenied>()));
    });

    test('sin reason distingue los tres 400 por el mensaje', () async {
      final cases = <String, Matcher>{
        'server_auth_code invalido, vencido o ya usado':
            isA<GmailCodeRejected>(),
        'Google no entrego refresh token: la app debe pedir acceso offline '
                'y forzar el consentimiento':
            isA<GmailRefreshTokenMissing>(),
        'permiso de Gmail no concedido: la app debe pedir gmail.readonly':
            isA<GmailScopeDenied>(),
      };
      for (final MapEntry(:key, :value) in cases.entries) {
        backend.handler = (_) => _codeError(key);
        await expectLater(repository.connect(), throwsA(value), reason: key);
      }
    });

    test('503 upstream_unavailable → GmailUpstreamUnavailable', () async {
      backend.handler = (_) => StubResponse.error(503, 'upstream_unavailable');
      await expectLater(
        repository.connect(),
        throwsA(isA<GmailUpstreamUnavailable>()),
      );
    });

    test('429 → GmailRateLimited con retry-after', () async {
      backend.handler = (_) => StubResponse.error(
        429,
        'rate_limited',
        headers: {'retry-after': '7'},
      );
      await expectLater(
        repository.connect(),
        throwsA(
          isA<GmailRateLimited>().having(
            (f) => f.retryAfter,
            'retryAfter',
            const Duration(seconds: 7),
          ),
        ),
      );
    });

    test('otro 400 → GmailUnexpected', () async {
      backend.handler = (_) => StubResponse.error(400, 'validation_error');
      await expectLater(
        repository.connect(),
        throwsA(isA<GmailUnexpected>()),
      );
    });
  });

  group('disconnect', () {
    test('DELETE /v1/gmail/connect', () async {
      backend.handler = (_) => const StubResponse(204);

      await repository.disconnect();

      expect(backend.requests.single.method, 'DELETE');
      expect(backend.requests.single.path, '/v1/gmail/connect');
    });

    test('sin red → GmailNetworkFailure', () async {
      backend.handler = (r) => throw connectionError(r);
      await expectLater(
        repository.disconnect(),
        throwsA(isA<GmailNetworkFailure>()),
      );
    });
  });
}
