import 'dart:async';

import 'package:finanzia/features/categories/domain/categories_ports.dart';
import 'package:finanzia/features/categories/domain/category_draft.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puertos de categorías; se sobrescriben en `lib/app/composition.dart`.
final categoriesRemoteProvider = Provider<CategoriesRemote>(
  (ref) => throw UnimplementedError(
    'categoriesRemoteProvider se sobrescribe en la composición',
  ),
);
final categoriesStoreProvider = Provider<CategoriesStore>(
  (ref) => throw UnimplementedError(
    'categoriesStoreProvider se sobrescribe en la composición',
  ),
);

/// Categorías propias del usuario con su conteo de movimientos.
final StreamProvider<List<OwnCategory>> ownCategoriesProvider =
    StreamProvider.autoDispose<List<OwnCategory>>(
      (ref) => ref.watch(categoriesStoreProvider).watchOwn(),
    );

/// El borrador no se puede enviar; [errors] dice por qué.
class InvalidCategoryDraft implements Exception {
  const InvalidCategoryDraft(this.errors);

  final Set<CategoryDraftError> errors;

  @override
  String toString() => 'InvalidCategoryDraft($errors)';
}

/// Crear, editar y borrar categorías propias (spec 005 §7). Van directo al
/// servidor, sin outbox: sin conexión fallan con `CategoryOffline`. Tras un
/// éxito la copia local se actualiza al instante.
class CategoryActions {
  CategoryActions({
    required CategoriesRemote remote,
    required CategoriesStore store,
    required void Function() requestSync,
  }) : _remote = remote,
       _store = store,
       _requestSync = requestSync;

  final CategoriesRemote _remote;
  final CategoriesStore _store;
  final void Function() _requestSync;

  Future<SyncedCategory> create(CategoryDraft draft) async {
    final created = await _remote.create(_checked(draft));
    await _store.upsert(created);
    return created;
  }

  /// Un cambio de etiqueta fiscal también cambia los movimientos de la
  /// categoría en el servidor: se pide un sync para traerlos.
  Future<SyncedCategory> update(String id, CategoryDraft draft) async {
    final updated = await _remote.update(id, _checked(draft));
    await _store.upsert(updated);
    _requestSync();
    return updated;
  }

  /// El servidor pasa sus movimientos a "Sin categoría"; el sync los trae.
  Future<void> delete(String id) async {
    await _remote.delete(id);
    await _store.remove(id);
    _requestSync();
  }

  CategoryDraft _checked(CategoryDraft draft) {
    final errors = draft.validate();
    if (errors.isNotEmpty) throw InvalidCategoryDraft(errors);
    return draft.copyWith(name: draft.cleanName);
  }
}

final categoryActionsProvider = Provider<CategoryActions>(
  (ref) => CategoryActions(
    remote: ref.watch(categoriesRemoteProvider),
    store: ref.watch(categoriesStoreProvider),
    requestSync: () =>
        unawaited(ref.read(syncCoordinatorProvider.notifier).sync()),
  ),
);
