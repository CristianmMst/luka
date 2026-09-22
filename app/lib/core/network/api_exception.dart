import 'package:dio/dio.dart';

/// Códigos del sobre de error del backend `{"error": {"code", ...}}`
/// (spec 005 §1), más los que solo existen del lado del cliente.
enum ApiErrorCode {
  validationError,
  unauthorized,
  tokenExpired,
  forbidden,
  notFound,
  conflict,
  rateLimited,
  internal,

  /// Sin conexión, timeout o DNS: la petición no llegó al servidor.
  network,

  /// Respuesta que no sigue el contrato.
  unknown;

  static ApiErrorCode fromWire(String? code) => switch (code) {
    'validation_error' => validationError,
    'unauthorized' => unauthorized,
    'token_expired' => tokenExpired,
    'forbidden' => forbidden,
    'not_found' => notFound,
    'conflict' => conflict,
    'rate_limited' => rateLimited,
    'internal' => internal,
    _ => unknown,
  };
}

/// Error de la API ya traducido desde `DioException`.
final class ApiException implements Exception {
  const ApiException(
    this.code, {
    this.message,
    this.field,
    this.statusCode,
    this.retryAfter,
  });

  factory ApiException.fromDio(DioException error) {
    final inner = error.error;
    if (inner is ApiException) return inner;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException(ApiErrorCode.network, message: error.message);
      case DioExceptionType.transformTimeout:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final response = error.response;
    if (response == null) {
      return ApiException(ApiErrorCode.network, message: error.message);
    }
    return ApiException.fromResponse(response);
  }

  factory ApiException.fromResponse(Response<dynamic> response) {
    final body = response.data;
    final envelope = body is Map && body['error'] is Map
        ? body['error'] as Map
        : null;
    final code = ApiErrorCode.fromWire(envelope?['code'] as String?);
    return ApiException(
      code == ApiErrorCode.unknown && response.statusCode == 429
          ? ApiErrorCode.rateLimited
          : code,
      message: envelope?['message'] as String?,
      field: envelope?['field'] as String?,
      statusCode: response.statusCode,
      retryAfter: _parseRetryAfter(response.headers.value('retry-after')),
    );
  }

  final ApiErrorCode code;
  final String? message;
  final String? field;
  final int? statusCode;
  final Duration? retryAfter;

  static Duration? _parseRetryAfter(String? raw) {
    final seconds = int.tryParse(raw?.trim() ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }

  @override
  String toString() => 'ApiException($code, status: $statusCode, $message)';
}
