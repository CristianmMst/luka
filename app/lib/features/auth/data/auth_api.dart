import 'package:dio/dio.dart';
import 'package:luka/core/network/api_exception.dart';
import 'package:luka/features/auth/data/dtos/session_dto.dart';

/// Endpoints `/v1/auth/*` (spec 005 §2). Usa el cliente sin interceptor de
/// auth para que un refresh nunca dispare otro refresh.
///
/// Todos los métodos fallan con `ApiException`.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<SessionDto> loginWithGoogle({
    required String idToken,
    String? deviceInfo,
  }) {
    return _session('/v1/auth/google', {
      'id_token': idToken,
      'device_info': ?deviceInfo,
    });
  }

  Future<SessionDto> refresh({
    required String refreshToken,
    String? deviceInfo,
  }) {
    return _session('/v1/auth/refresh', {
      'refresh_token': refreshToken,
      'device_info': ?deviceInfo,
    });
  }

  /// Revoca el refresh token. El backend responde 204 siempre que el
  /// Bearer sea válido.
  Future<void> logout({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _dio.post<void>(
        '/v1/auth/logout',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SessionDto> _session(String path, Map<String, dynamic> body) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(path, data: body);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    final data = response.data;
    try {
      if (data != null) return SessionDto.fromJson(data);
    } on Object catch (e) {
      // Cuerpo que no sigue el contrato (campo ausente o de otro tipo).
      throw ApiException(ApiErrorCode.unknown, message: '$e');
    }
    throw const ApiException(ApiErrorCode.unknown, message: 'Respuesta vacía');
  }
}
