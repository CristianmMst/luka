import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/categories/data/categories_api.dart';
import 'package:luka/features/categories/domain/categories_ports.dart';
import 'package:luka/features/categories/domain/category_draft.dart';

import '../../../helpers/stub_backend.dart';

Map<String, dynamic> _categoryJson({String name = 'Mascotas'}) => {
  'id': 'c-1',
  'user_id': 'u-1',
  'slug': null,
  'name': name,
  'icon': 'pets',
  'color': '#6B4C9A',
  'fiscal_tag': 'no_deducible',
  'is_system': false,
};

const _draft = CategoryDraft(
  name: 'Mascotas',
  icon: 'pets',
  color: '#6B4C9A',
);

void main() {
  test('crear hace POST /v1/categories con el borrador', () async {
    final backend = StubBackend((_) => StubResponse(201, _categoryJson()));

    final created = await CategoriesApi(stubDio(backend)).create(_draft);

    expect(created.id, 'c-1');
    expect(created.isSystem, isFalse);
    final request = backend.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/v1/categories');
    expect(jsonDecode(request.data as String), {
      'name': 'Mascotas',
      'fiscal_tag': 'no_deducible',
      'icon': 'pets',
      'color': '#6B4C9A',
    });
  });

  test('editar hace PATCH con todos los campos', () async {
    final backend = StubBackend(
      (_) => StubResponse(200, _categoryJson(name: 'Mascotas y más')),
    );

    final updated = await CategoriesApi(
      stubDio(backend),
    ).update('c-1', _draft.copyWith(name: 'Mascotas y más'));

    expect(updated.name, 'Mascotas y más');
    expect(backend.requests.single.method, 'PATCH');
    expect(backend.requests.single.path, '/v1/categories/c-1');
  });

  test('borrar hace DELETE', () async {
    final backend = StubBackend((_) => const StubResponse(204));

    await CategoriesApi(stubDio(backend)).delete('c-1');

    expect(backend.requests.single.method, 'DELETE');
    expect(backend.requests.single.path, '/v1/categories/c-1');
  });

  test('los errores se traducen a CategoryFailure', () async {
    Future<Object?> failure(StubHandler handler) async {
      try {
        await CategoriesApi(stubDio(StubBackend(handler))).create(_draft);
      } on CategoryFailure catch (e) {
        return e;
      }
      return null;
    }

    expect(
      await failure((_) => StubResponse.error(409, 'conflict')),
      isA<CategoryDuplicateName>(),
    );
    expect(
      await failure((_) => StubResponse.error(404, 'not_found')),
      isA<CategoryGone>(),
    );
    expect(
      await failure((_) => StubResponse.error(403, 'forbidden')),
      isA<CategoryGone>(),
    );
    expect(
      await failure((r) => throw connectionError(r)),
      isA<CategoryOffline>(),
    );
    expect(
      await failure((_) => StubResponse.error(500, 'internal')),
      isA<CategoryUnexpected>(),
    );
    expect(
      await failure((_) => const StubResponse(201, {'nope': true})),
      isA<CategoryUnexpected>(),
    );
  });
}
