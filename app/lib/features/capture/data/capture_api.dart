import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:luka/core/network/api_exception.dart';
import 'package:luka/features/capture/data/dtos/capture_dtos.dart';
import 'package:luka/features/capture/domain/capture_ports.dart';
import 'package:luka/features/capture/domain/captured_notification.dart';
import 'package:luka/features/sync/domain/sync_rules.dart';

/// `CaptureRemote` sobre dio (spec 005 §5). Falla con [RemoteFailure].
///
/// El lote no lleva `Idempotency-Key`: ya es idempotente por `client_hash`.
class CaptureApi implements CaptureRemote {
  CaptureApi(this._dio);

  final Dio _dio;

  @override
  Future<CaptureConfig> config() async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>('/v1/config/capture');
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
    return _decode(() => CaptureConfigDto.fromJson(response.data!).toDomain());
  }

  @override
  Future<IngestResult> ingest(List<CapturedNotification> items) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        '/v1/ingest/notifications',
        data: jsonEncode({
          'items': [
            for (final item in items) IngestItemDto.fromDomain(item).toJson(),
          ],
        }),
      );
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
    return _decode(() => IngestResultDto.fromJson(response.data!).toDomain());
  }

  /// Un cuerpo fuera de contrato es un fallo del servidor.
  T _decode<T>(T Function() decode) {
    try {
      return decode();
    } on Object {
      throw const RemoteFailure(statusCode: 200, code: 'unknown');
    }
  }

  RemoteFailure _failure(ApiException e) {
    if (e.code == ApiErrorCode.network) return const RemoteFailure.network();
    return RemoteFailure(
      statusCode: e.statusCode,
      code: e.code.name,
      retryAfter: e.retryAfter,
    );
  }
}
