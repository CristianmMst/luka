import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:luka/core/network/api_exception.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/recurring/data/recurring_dtos.dart';
import 'package:luka/features/recurring/domain/recurring_draft.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/recurring_ports.dart';

/// [RecurringRemote] sobre dio (spec 005 §10). Falla con
/// [RecurringFailure], nunca con `DioException`.
class RecurringApi implements RecurringRemote {
  RecurringApi(this._dio);

  final Dio _dio;

  static const _expenses = '/v1/recurring-expenses';
  static const _occurrences = '/v1/recurring-occurrences';

  @override
  Future<List<RecurringExpense>> expenses() async {
    final data = await _call<List<dynamic>>('GET', _expenses);
    return _decode(
      () => [
        for (final item in data ?? const [])
          RecurringExpenseDto.fromJson(
            item as Map<String, dynamic>,
          ).toDomain(),
      ],
    );
  }

  @override
  Future<List<RecurringOccurrence>> occurrences(
    ColombiaMonth from,
    ColombiaMonth to,
  ) async {
    final data = await _call<List<dynamic>>(
      'GET',
      _occurrences,
      query: {'from': _month(from), 'to': _month(to)},
    );
    return _decode(
      () => [
        for (final item in data ?? const [])
          OccurrenceDto.fromJson(item as Map<String, dynamic>).toDomain(),
      ],
    );
  }

  @override
  Future<RecurringExpense> create(RecurringDraft draft) =>
      _expense('POST', _expenses, _body(draft));

  @override
  Future<RecurringExpense> update(String id, RecurringDraft draft) =>
      _expense('PATCH', '$_expenses/$id', _body(draft));

  @override
  Future<RecurringExpense> setActive(String id, {required bool active}) =>
      _expense('PATCH', '$_expenses/$id', {'active': active});

  @override
  Future<void> delete(String id) => _call<void>('DELETE', '$_expenses/$id');

  @override
  Future<RecurringOccurrence> markPaid(String id, {String? transactionId}) =>
      _occurrence('$_occurrences/$id/mark-paid', {
        'transaction_id': transactionId,
      });

  @override
  Future<RecurringOccurrence> unmark(String id) =>
      _occurrence('$_occurrences/$id/unmark', null);

  @override
  Future<RecurringOccurrence> skip(String id) =>
      _occurrence('$_occurrences/$id/skip', null);

  Map<String, Object?> _body(RecurringDraft draft) => {
    // Sin palabra clave ni margen: el backend usa el nombre y el monto
    // exacto (spec 011 §4).
    'name': draft.name,
    'expected_amount': draft.expectedAmount?.toWire(),
    'day_of_month': draft.dayOfMonth,
    'remind_days_before': draft.remindDaysBefore,
    'category_id': draft.categoryId,
    'account_id': draft.accountId,
  };

  Future<RecurringExpense> _expense(
    String method,
    String path,
    Map<String, Object?> body,
  ) async {
    final data = await _call<Map<String, dynamic>>(method, path, body: body);
    return _decode(() => RecurringExpenseDto.fromJson(data!).toDomain());
  }

  Future<RecurringOccurrence> _occurrence(
    String path,
    Map<String, Object?>? body,
  ) async {
    final data = await _call<Map<String, dynamic>>('POST', path, body: body);
    return _decode(() => OccurrenceDto.fromJson(data!).toDomain());
  }

  Future<T?> _call<T>(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, Object?>? query,
  }) async {
    try {
      final response = await _dio.request<T>(
        path,
        data: body == null ? null : jsonEncode(body),
        queryParameters: query,
        options: Options(method: method),
      );
      return response.data;
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
  }

  T _decode<T>(T Function() decode) {
    try {
      return decode();
    } on Object {
      throw const RecurringUnexpected(statusCode: 200);
    }
  }

  static String _month(ColombiaMonth month) =>
      '${month.year}-${'${month.month}'.padLeft(2, '0')}';

  RecurringFailure _failure(ApiException e) => switch (e) {
    ApiException(code: ApiErrorCode.network) => const RecurringOffline(),
    ApiException(statusCode: 404) => const RecurringGone(),
    ApiException(statusCode: 409) => const RecurringConflict(),
    ApiException(:final statusCode) => RecurringUnexpected(
      statusCode: statusCode,
    ),
  };
}
