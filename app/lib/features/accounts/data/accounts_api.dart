import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:finanzia/core/network/api_exception.dart';
import 'package:finanzia/features/accounts/domain/account_draft.dart';
import 'package:finanzia/features/accounts/domain/accounts_ports.dart';
import 'package:finanzia/features/sync/data/dtos/catalog_dtos.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';

/// [AccountsRemote] sobre dio, contra `/v1/accounts` (spec 005 §7).
/// Falla con [AccountFailure], nunca con `DioException`.
class AccountsApi implements AccountsRemote {
  AccountsApi(this._dio);

  final Dio _dio;

  @override
  Future<SyncedAccount> create(AccountDraft draft) =>
      _send('POST', '/v1/accounts', {'bank': draft.bank, ..._editable(draft)});

  @override
  Future<SyncedAccount> update(String id, AccountDraft draft) =>
      _send('PATCH', '/v1/accounts/$id', _editable(draft));

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/v1/accounts/$id');
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
  }

  /// Vacíos van como `null`: en el PATCH, `null` borra el valor.
  Map<String, Object?> _editable(AccountDraft draft) => {
    'kind': draft.kind,
    'last4': draft.cleanLast4,
    'alias': draft.cleanAlias,
  };

  Future<SyncedAccount> _send(
    String method,
    String path,
    Map<String, Object?> body,
  ) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.request<Map<String, dynamic>>(
        path,
        data: jsonEncode(body),
        options: Options(method: method),
      );
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
    try {
      return AccountDto.fromJson(response.data!).toDomain();
    } on Object {
      throw const AccountUnexpected();
    }
  }

  AccountFailure _failure(ApiException e) => switch (e) {
    ApiException(code: ApiErrorCode.network) => const AccountOffline(),
    ApiException(statusCode: 409) => const AccountDuplicate(),
    ApiException(statusCode: 404) => const AccountGone(),
    _ => const AccountUnexpected(),
  };
}
