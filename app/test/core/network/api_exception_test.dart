import 'package:dio/dio.dart';
import 'package:finanzia/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_backend.dart';

void main() {
  Future<ApiException> failWith(FakeHandler handler) async {
    final dio = fakeDio(FakeBackend(handler));
    try {
      await dio.get<void>('/x');
    } on DioException catch (e) {
      return ApiException.fromDio(e);
    }
    throw StateError('se esperaba un error');
  }

  test('traduce el sobre de error del backend', () async {
    final error = await failWith(
      (_) => const FakeResponse(400, {
        'error': {
          'code': 'validation_error',
          'message': 'id_token muy corto',
          'field': 'id_token',
        },
      }),
    );
    expect(error.code, ApiErrorCode.validationError);
    expect(error.field, 'id_token');
    expect(error.statusCode, 400);
  });

  test('distingue token_expired de unauthorized', () async {
    expect(
      (await failWith((_) => FakeResponse.error(401, 'token_expired'))).code,
      ApiErrorCode.tokenExpired,
    );
    expect(
      (await failWith((_) => FakeResponse.error(401, 'unauthorized'))).code,
      ApiErrorCode.unauthorized,
    );
  });

  test('429 lleva Retry-After', () async {
    final error = await failWith(
      (_) => FakeResponse.error(
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
      (await failWith((_) => const FakeResponse(429, 'Too Many'))).code,
      ApiErrorCode.rateLimited,
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
      (await failWith((_) => const FakeResponse(502, 'Bad Gateway'))).code,
      ApiErrorCode.unknown,
    );
  });
}
