import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:finanzia/core/network/api_exception.dart';
import 'package:finanzia/features/sync/data/dtos/catalog_dtos.dart';
import 'package:finanzia/features/sync/data/dtos/review_dto.dart';
import 'package:finanzia/features/sync/data/dtos/transaction_dto.dart';
import 'package:finanzia/features/sync/data/outbox_requests.dart';
import 'package:finanzia/features/sync/domain/sync_ports.dart';
import 'package:finanzia/features/sync/domain/sync_rules.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';

/// `SyncRemote` sobre dio, contra `/v1/*` (spec 005 §6-7). Falla con
/// [RemoteFailure], nunca con `DioException`/`ApiException`.
class SyncApi implements SyncRemote {
  SyncApi(this._dio);

  final Dio _dio;

  /// El máximo que acepta el backend (`shared/http/pagination.py`).
  static const _pageLimit = 200;

  @override
  Future<SyncedTransaction?> send(OutboxEntry entry) async {
    final request = requestFor(entry.op);
    final Response<Object?> response;
    try {
      response = await _dio.request<Object?>(
        request.path,
        data: request.body == null ? null : jsonEncode(request.body),
        options: Options(
          method: request.method,
          headers: {
            if (request.method == 'POST')
              'Idempotency-Key': entry.idempotencyKey,
          },
        ),
      );
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
    return _transactionOrNull(response.data);
  }

  @override
  Future<SyncedTransaction?> fetchTransaction(String id) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>('/v1/transactions/$id');
    } on DioException catch (e) {
      final failure = ApiException.fromDio(e);
      if (failure.statusCode == 404) return null;
      throw _failure(failure);
    }
    return _decodeOrUnknown(
      () => TransactionDto.fromJson(response.data!).toDomain(),
    );
  }

  @override
  Future<TransactionDetail?> fetchTransactionDetail(String id) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>('/v1/transactions/$id');
    } on DioException catch (e) {
      final failure = ApiException.fromDio(e);
      if (failure.statusCode == 404) return null;
      throw _failure(failure);
    }
    return _decodeOrUnknown(() {
      final dto = TransactionDetailDto.fromJson(response.data!);
      return (
        tx: dto.transaction.toDomain(),
        sources: [for (final source in dto.sources) source.toDomain()],
      );
    });
  }

  @override
  Future<TransactionsPage> transactionsSince(
    DateTime since, {
    String? cursor,
  }) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>(
        '/v1/transactions',
        queryParameters: {
          'updated_since': since.toUtc().toIso8601String(),
          'limit': _pageLimit,
          'cursor': ?cursor,
        },
      );
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
    final page = _decodeOrUnknown(
      () => TransactionPageDto.fromJson(response.data!),
    );
    return (
      items: [for (final item in page.items) item.toDomain()],
      nextCursor: page.nextCursor,
    );
  }

  @override
  Future<List<SyncedCategory>> categories() async {
    final Response<List<dynamic>> response;
    try {
      response = await _dio.get<List<dynamic>>('/v1/categories');
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
    return _decodeOrUnknown(
      () => [
        for (final item in response.data ?? const [])
          CategoryDto.fromJson(item as Map<String, dynamic>).toDomain(),
      ],
    );
  }

  @override
  Future<List<SyncedAccount>> accounts() async {
    final Response<List<dynamic>> response;
    try {
      response = await _dio.get<List<dynamic>>('/v1/accounts');
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
    return _decodeOrUnknown(
      () => [
        for (final item in response.data ?? const [])
          AccountDto.fromJson(item as Map<String, dynamic>).toDomain(),
      ],
    );
  }

  @override
  Future<List<SyncedReviewItem>> openReview() async {
    final items = <SyncedReviewItem>[];
    String? cursor;
    while (true) {
      final Response<Map<String, dynamic>> response;
      try {
        response = await _dio.get<Map<String, dynamic>>(
          '/v1/review',
          queryParameters: {'limit': _pageLimit, 'cursor': ?cursor},
        );
      } on DioException catch (e) {
        throw _failure(ApiException.fromDio(e));
      }
      final page = _decodeOrUnknown(
        () => ReviewPageDto.fromJson(response.data!),
      );
      items.addAll([for (final item in page.items) item.toDomain()]);
      final nextCursor = page.nextCursor;
      if (nextCursor == null) break;
      cursor = nextCursor;
    }
    return items;
  }

  /// La transacción del servidor si la respuesta la trae (`amount` presente);
  /// `null` para las respuestas sin cuerpo (204) o de otra forma (descartar).
  SyncedTransaction? _transactionOrNull(Object? data) {
    if (data is! Map<String, dynamic> || !data.containsKey('amount')) {
      return null;
    }
    return _decodeOrUnknown(() => TransactionDto.fromJson(data).toDomain());
  }

  /// Un cuerpo que no sigue el contrato (campo ausente o de otro tipo) es un
  /// fallo del servidor, no un bug del cliente: se traduce a [RemoteFailure].
  T _decodeOrUnknown<T>(T Function() decode) {
    try {
      return decode();
    } on RemoteFailure {
      rethrow;
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
