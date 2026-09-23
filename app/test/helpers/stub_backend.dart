import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Respuesta simulada del backend.
class StubResponse {
  const StubResponse(this.status, [this.body, this.headers = const {}]);

  /// Sobre de error del backend: `{"error": {"code", "message"}}`.
  factory StubResponse.error(
    int status,
    String code, {
    Map<String, String> headers = const {},
  }) => StubResponse(status, {
    'error': {'code': code, 'message': code},
  }, headers);

  final int status;
  final Object? body;
  final Map<String, String> headers;
}

typedef StubHandler = FutureOr<StubResponse> Function(RequestOptions request);

/// Adapter de dio que responde con [handler] y registra cada petición.
/// Lanzar un `DioException` desde el handler simula un fallo de red.
class StubBackend implements HttpClientAdapter {
  StubBackend(this.handler);

  StubHandler handler;
  final requests = <RequestOptions>[];

  int countOf(String path) => requests.where((r) => r.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Copia: dio reutiliza el mismo RequestOptions al reintentar.
    requests.add(options.copyWith(headers: Map.of(options.headers)));
    final response = await handler(options);
    return ResponseBody.fromString(
      response.body == null ? '' : jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final MapEntry(:key, :value) in response.headers.entries)
          key: [value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio stubDio(StubBackend backend) =>
    Dio(BaseOptions(baseUrl: 'http://test.local'))..httpClientAdapter = backend;

DioException connectionError(RequestOptions request) => DioException(
  requestOptions: request,
  type: DioExceptionType.connectionError,
  message: 'sin red',
);

Map<String, dynamic> userJson({String email = 'ana@example.com'}) => {
  'id': '6f1c2c1e-3b8a-4c61-9b7e-5f2f0c0e2a11',
  'email': email,
  'display_name': 'Ana María Pérez',
  'photo_url': null,
  'status': 'active',
  'created_at': '2026-09-01T12:00:00+00:00',
};

Map<String, dynamic> sessionJson({
  String access = 'access-1',
  String refresh = 'refresh-1',
  int expiresIn = 900,
}) => {
  'access_token': access,
  'refresh_token': refresh,
  'token_type': 'Bearer',
  'expires_in': expiresIn,
  'user': userJson(),
};

/// `TransactionListItem` del backend (`ledger/infrastructure/api/schemas.py`).
Map<String, dynamic> transactionJson({
  String id = '11111111-1111-1111-1111-111111111111',
  String amount = '45000.00',
  String currency = 'COP',
  String direction = 'debit',
  String kind = 'expense',
  String occurredAt = '2026-09-22T15:00:00Z',
  String? merchant = 'Éxito',
  String? description,
  String? bank,
  String? accountId,
  String categoryId = '22222222-2222-2222-2222-222222222222',
  String fiscalTag = 'deducible',
  String? transferPairId,
  bool transferAuto = false,
  String parsedBy = 'manual',
  double? confidence,
  String? notes,
  String createdAt = '2026-09-22T15:00:00Z',
  String updatedAt = '2026-09-22T15:00:00Z',
  List<String> channels = const ['manual'],
}) => {
  'id': id,
  'amount': amount,
  'currency': currency,
  'direction': direction,
  'kind': kind,
  'occurred_at': occurredAt,
  'merchant': merchant,
  'description': description,
  'bank': bank,
  'account_id': accountId,
  'category_id': categoryId,
  'fiscal_tag': fiscalTag,
  'transfer_pair_id': transferPairId,
  'transfer_auto': transferAuto,
  'parsed_by': parsedBy,
  'confidence': confidence,
  'notes': notes,
  'created_at': createdAt,
  'updated_at': updatedAt,
  'channels': channels,
};
