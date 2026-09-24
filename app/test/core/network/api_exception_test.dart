import 'package:dio/dio.dart';
import 'package:finanzia/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stub_backend.dart';

void main() {
  Future<ApiException> failWith(StubHandler handler) async {
    final dio = stubDio(StubBackend(handler));
    try {
      await dio.get<void>('/x');
    } on DioException catch (e) {
      return ApiException.fromDio(e);
    }
    throw StateError('se esperaba un error');
  }

  test('traduce el sobre de error del backend', () async {
    final error = await failWith(
      (_) => const StubResponse(400, {
        'error': {
          'code': 'validation_error',
          'message': 'id_token muy corto',
          'field': 'id_token',
        },
      }),
    );
    expect(error.code, ApiErrorCode.validationError);
    expect(error.field, 'id_token');
    expect(error.reason, isNull);
    expect(error.statusCode, 400);
  });

  test('lee el reason opcional del sobre', () async {
    final error = await failWith(
      (_) => const StubResponse(400, {
        'error': {
          'code': 'validation_error',
          'message': 'da igual',
          'field': 'server_auth_code',
          'reason': 'scope_not_granted',
        },
      }),
    );
    expect(error.reason, 'scope_not_granted');
  });

  test('distingue token_expired de unauthorized', () async {
    expect(
      (await failWith((_) => StubResponse.error(401, 'token_expired'))).code,
      ApiErrorCode.tokenExpired,
    );
    expect(
      (await failWith((_) => StubResponse.error(401, 'unauthorized'))).code,
      ApiErrorCode.unauthorized,
    );
  });

  test('429 lleva Retry-After', () async {
    final error = await failWith(
      (_) => StubResponse.error(
        429,
        'rate_limited',
        headers: {'retry-after': '48'},
      ),
    );
    expect(error.code, ApiErrorCode.rateLimited);
    expect(error.retryAfter, const Duration(seconds: 48));
  });

  test('429 sin sobre sigue siendo rate_limited', () async {
    expect(
      (await failWith((_) => const StubResponse(429, 'Too Many'))).code,
      ApiErrorCode.rateLimited,
    );
  });

  test('503 upstream_unavailable se reconoce', () async {
    expect(
      (await failWith(
        (_) => StubResponse.error(503, 'upstream_unavailable'),
      )).code,
      ApiErrorCode.upstreamUnavailable,
    );
  });

  test('sin conexión es network', () async {
    expect(
      (await failWith((r) => throw connectionError(r))).code,
      ApiErrorCode.network,
    );
  });

  test('respuesta fuera de contrato es unknown', () async {
    expect(
      (await failWith((_) => const StubResponse(502, 'Bad Gateway'))).code,
      ApiErrorCode.unknown,
    );
  });
}
