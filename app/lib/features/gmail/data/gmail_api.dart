import 'package:dio/dio.dart';
import 'package:luka/core/network/api_exception.dart';
import 'package:luka/features/gmail/data/dtos/gmail_connection_dto.dart';

/// Endpoints `/v1/gmail/*` (spec 005 §3). Usa el cliente autenticado.
///
/// Todos los métodos fallan con `ApiException`.
class GmailApi {
  GmailApi(this._dio);

  final Dio _dio;

  static const _connectPath = '/v1/gmail/connect';

  Future<GmailConnectionDto> status() =>
      _connection(() => _dio.get<Map<String, dynamic>>('/v1/gmail/status'));

  /// Canjea el `serverAuthCode` en el backend. El código es de un solo uso y
  /// nunca se loguea.
  Future<GmailConnectionDto> connect(String serverAuthCode) => _connection(
    () => _dio.post<Map<String, dynamic>>(
      _connectPath,
      data: {'server_auth_code': serverAuthCode},
    ),
  );

  /// 204 siempre, exista o no la conexión.
  Future<void> disconnect() async {
    try {
      await _dio.delete<void>(_connectPath);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<GmailConnectionDto> _connection(
    Future<Response<Map<String, dynamic>>> Function() send,
  ) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await send();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    final data = response.data;
    try {
      if (data != null) return GmailConnectionDto.fromJson(data);
    } on Object catch (e) {
      // Cuerpo que no sigue el contrato (campo ausente o de otro tipo).
      throw ApiException(ApiErrorCode.unknown, message: '$e');
    }
    throw const ApiException(ApiErrorCode.unknown, message: 'Respuesta vacía');
  }
}
