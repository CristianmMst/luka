import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/features/categories/domain/category_draft.dart';
import 'package:luka/features/sync/domain/synced_models.dart';

part 'categories_ports.freezed.dart';

/// Categoría propia del usuario, con cuántos movimientos locales la usan
/// (para "Mis categorías" y el diálogo de borrar).
@freezed
abstract class OwnCategory with _$OwnCategory {
  const factory OwnCategory({
    required String id,
    required String name,
    required String fiscalTag,
    required int transactionCount,
    String? icon,
    String? color,
  }) = _OwnCategory;
}

/// Por qué no se pudo crear, editar o borrar una categoría.
sealed class CategoryFailure implements Exception {
  const CategoryFailure();
}

/// Sin conexión: las categorías se gestionan solo en línea.
final class CategoryOffline extends CategoryFailure {
  const CategoryOffline();
}

/// 409: el nombre ya existe (propia o del sistema, sin mayúsculas).
final class CategoryDuplicateName extends CategoryFailure {
  const CategoryDuplicateName();
}

/// 404 o 403: ya no existe o no se puede tocar (del sistema).
final class CategoryGone extends CategoryFailure {
  const CategoryGone();
}

/// Cualquier otro fallo (5xx, respuesta fuera de contrato).
final class CategoryUnexpected extends CategoryFailure {
  const CategoryUnexpected();
}

/// `/v1/categories` del backend. Falla con [CategoryFailure].
abstract interface class CategoriesRemote {
  Future<SyncedCategory> create(CategoryDraft draft);
  Future<SyncedCategory> update(String id, CategoryDraft draft);
  Future<void> delete(String id);
}

/// Copia local (Drift) de las categorías.
abstract interface class CategoriesStore {
  /// Las propias del usuario, ordenadas por nombre.
  Stream<List<OwnCategory>> watchOwn();

  /// Guarda la categoría que devolvió el servidor, para verla sin esperar
  /// al próximo pull.
  Future<void> upsert(SyncedCategory category);

  /// Quita la categoría y deja sus movimientos locales en "Sin categoría"
  /// hasta que el pull traiga la versión del servidor.
  Future<void> remove(String id);
}
