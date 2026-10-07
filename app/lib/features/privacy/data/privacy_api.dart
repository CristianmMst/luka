import 'package:dio/dio.dart';
import 'package:luka/core/network/api_exception.dart';
import 'package:luka/features/privacy/domain/privacy_ports.dart';

/// [PrivacyRemote] sobre dio (spec 005 §2). Falla con [PrivacyFailure],
/// nunca con `DioException`.
class PrivacyApi implements PrivacyRemote {
  PrivacyApi(this._dio);

  final Dio _dio;

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
