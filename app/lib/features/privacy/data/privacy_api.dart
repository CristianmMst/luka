import 'package:dio/dio.dart';
import 'package:finanzia/core/network/api_exception.dart';
import 'package:finanzia/features/privacy/domain/privacy_ports.dart';

/// [PrivacyRemote] sobre dio (spec 005 §2). Falla con [PrivacyFailure],
/// nunca con `DioException`.
class PrivacyApi implements PrivacyRemote {
  PrivacyApi(this._dio);

  final Dio _dio;

  @override
  Future<String> exportData() async {
    try {
      // Texto crudo: se guarda tal cual, sin decodificar y volver a codificar.
      final response = await _dio.get<String>(
        '/v1/me/export',
        options: Options(responseType: ResponseType.plain),
      );
      final body = response.data;
      if (body == null || body.isEmpty) throw const PrivacyUnexpected();
      return body;
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _dio.delete<void>('/v1/me');
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
  }

  PrivacyFailure _failure(ApiException e) => switch (e) {
    ApiException(code: ApiErrorCode.network) => const PrivacyOffline(),
    _ => const PrivacyUnexpected(),
  };
}
