import 'package:dio/dio.dart';
import 'package:luka/core/network/api_exception.dart';
import 'package:luka/core/network/session_bridge.dart';

/// Añade `Authorization: Bearer <access>` y, cuando el backend responde
/// `401 token_expired`, renueva la sesión una sola vez y reintenta.
///
/// Si el refresh es rechazado, o el backend responde `401 unauthorized`, la
/// sesión se da por terminada y el error sigue su curso.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required Dio dio, required SessionBridge session})
    : _dio = dio,
      _session = session;

  final Dio _dio;
  final SessionBridge _session;

  static const _retriedKey = 'luka.auth.retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _session.accessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response?.statusCode != 401) return handler.next(err);

    final code = ApiException.fromResponse(response!).code;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;

    if (code != ApiErrorCode.tokenExpired || alreadyRetried) {
      await _session.expire();
      return handler.next(err);
    }

    switch (await _session.refresh()) {
      case RefreshOutcome.refreshed:
        try {
          final retry = err.requestOptions..extra[_retriedKey] = true;
          handler.resolve(await _dio.fetch<dynamic>(retry));
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      case RefreshOutcome.rejected:
        await _session.expire();
        handler.next(err);
      case RefreshOutcome.unavailable:
        handler.next(err);
    }
  }
}
