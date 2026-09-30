import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:luka/core/network/api_exception.dart';
import 'package:luka/features/categories/domain/categories_ports.dart';
import 'package:luka/features/categories/domain/category_draft.dart';
import 'package:luka/features/sync/data/dtos/catalog_dtos.dart';
import 'package:luka/features/sync/domain/synced_models.dart';

/// [CategoriesRemote] sobre dio, contra `/v1/categories` (spec 005 §7).
/// Falla con [CategoryFailure], nunca con `DioException`.
class CategoriesApi implements CategoriesRemote {
  CategoriesApi(this._dio);

  final Dio _dio;

  @override
  Future<SyncedCategory> create(CategoryDraft draft) =>
      _send('POST', '/v1/categories', draft);

  @override
  Future<SyncedCategory> update(String id, CategoryDraft draft) =>
      _send('PATCH', '/v1/categories/$id', draft);

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/v1/categories/$id');
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
  }

  Future<SyncedCategory> _send(
    String method,
    String path,
    CategoryDraft draft,
  ) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.request<Map<String, dynamic>>(
        path,
        data: jsonEncode({
          'name': draft.name,
          'fiscal_tag': draft.fiscalTag,
          'icon': draft.icon,
          'color': draft.color,
        }),
        options: Options(method: method),
      );
    } on DioException catch (e) {
      throw _failure(ApiException.fromDio(e));
    }
    try {
      return CategoryDto.fromJson(response.data!).toDomain();
    } on Object {
      throw const CategoryUnexpected();
    }
  }

  CategoryFailure _failure(ApiException e) => switch (e) {
    ApiException(code: ApiErrorCode.network) => const CategoryOffline(),
    ApiException(statusCode: 409) => const CategoryDuplicateName(),
    ApiException(statusCode: 404 || 403) => const CategoryGone(),
    _ => const CategoryUnexpected(),
  };
}
