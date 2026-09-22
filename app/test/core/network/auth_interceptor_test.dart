import 'package:dio/dio.dart';
import 'package:finanzia/core/network/auth_interceptor.dart';
import 'package:finanzia/core/network/session_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_backend.dart';

/// Sesión en memoria que cuenta refreshes y expiraciones.
class _FakeSession implements SessionBridge {
  _FakeSession({this.token = 'old', this.outcome = RefreshOutcome.refreshed});

  String? token;
  RefreshOutcome outcome;
  int refreshes = 0;
  int expirations = 0;

  @override
  Future<String?> accessToken() async => token;

  @override
  Future<RefreshOutcome> refresh() async {
    refreshes++;
    if (outcome == RefreshOutcome.refreshed) token = 'new';
    return outcome;
  }

  @override
  Future<void> expire() async {
    expirations++;
    token = null;
  }
}

void main() {
  late FakeBackend backend;
  late Dio dio;
  late _FakeSession session;

  /// El backend acepta solo `Bearer new`; `old` está vencido.
  FakeResponse acceptOnlyNew(RequestOptions request) =>
      request.headers['Authorization'] == 'Bearer new'
      ? const FakeResponse(200, {'ok': true})
      : FakeResponse.error(401, 'token_expired');

  void setUpClient(FakeHandler handler, {_FakeSession? withSession}) {
    backend = FakeBackend(handler);
    session = withSession ?? _FakeSession();
    dio = fakeDio(backend);
    dio.interceptors.add(AuthInterceptor(dio: dio, session: session));
  }

  test('añade el Bearer del access token vigente', () async {
    setUpClient((_) => const FakeResponse(200, {'ok': true}));
    session.token = 'new';
    await dio.get<void>('/v1/me');
    expect(backend.requests.single.headers['Authorization'], 'Bearer new');
  });

  test('sin sesión no añade Authorization', () async {
    setUpClient(
      (_) => const FakeResponse(200, {'ok': true}),
      withSession: _FakeSession(token: null),
    );
    await dio.get<void>('/v1/me');
    expect(backend.requests.single.headers, isNot(contains('Authorization')));
  });

  test('token_expired: refresca y reintenta con el token nuevo', () async {
    setUpClient(acceptOnlyNew);
    final response = await dio.get<Map<String, dynamic>>('/v1/me');
    expect(response.data, {'ok': true});
    expect(session.refreshes, 1);
    expect(backend.requests.map((r) => r.headers['Authorization']), [
      'Bearer old',
      'Bearer new',
    ]);
  });

  test('refresh rechazado: expira la sesión y propaga el 401', () async {
    setUpClient(
      acceptOnlyNew,
      withSession: _FakeSession(outcome: RefreshOutcome.rejected),
    );
    await expectLater(
      dio.get<void>('/v1/me'),
      throwsA(isA<DioException>()),
    );
    expect(session.expirations, 1);
  });

  test('refresh sin red: no expira la sesión', () async {
    setUpClient(
      acceptOnlyNew,
      withSession: _FakeSession(outcome: RefreshOutcome.unavailable),
    );
    await expectLater(
      dio.get<void>('/v1/me'),
      throwsA(isA<DioException>()),
    );
    expect(session.expirations, 0);
  });

  test('401 unauthorized expira sin intentar refresh', () async {
    setUpClient((_) => FakeResponse.error(401, 'unauthorized'));
    await expectLater(
      dio.get<void>('/v1/me'),
      throwsA(isA<DioException>()),
    );
    expect(session.refreshes, 0);
    expect(session.expirations, 1);
  });

  test('el reintento no entra en bucle si vuelve a fallar', () async {
    setUpClient((_) => FakeResponse.error(401, 'token_expired'));
    await expectLater(
      dio.get<void>('/v1/me'),
      throwsA(isA<DioException>()),
    );
    expect(session.refreshes, 1);
    expect(backend.requests, hasLength(2));
    expect(session.expirations, 1);
  });

  test('otros errores pasan intactos', () async {
    setUpClient((_) => FakeResponse.error(404, 'not_found'));
    await expectLater(
      dio.get<void>('/v1/transactions/x'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          404,
        ),
      ),
    );
    expect(session.refreshes, 0);
    expect(session.expirations, 0);
  });
}
