import 'package:drift/drift.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/features/categories/domain/categories_ports.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/search.dart';

/// [CategoriesStore] sobre la base local Drift (spec 004 §5). El pull de
/// cada sync sigue siendo la verdad: `replaceCategories` reemplaza todo.
class DriftCategoriesStore implements CategoriesStore {
  DriftCategoriesStore(this._db);

  final AppDatabase _db;

  static const _uncategorizedSlug = 'sin_categoria';

  @override
  Stream<List<OwnCategory>> watchOwn() {
    final c = _db.localCategories;
    final t = _db.localTransactions;
    final count = t.id.count();
    final query =
        _db.select(c).join([
            leftOuterJoin(t, t.categoryId.equalsExp(c.id), useColumns: false),
          ])
          ..addColumns([count])
          ..where(c.isSystem.equals(false))
          ..groupBy([c.id]);
    return query.watch().map((rows) {
      final own = [
        for (final row in rows)
          () {
            final category = row.readTable(c);
            return OwnCategory(
              id: category.id,
              name: category.name,
              fiscalTag: category.fiscalTag,
              transactionCount: row.read(count) ?? 0,
              icon: category.icon,
              color: category.color,
            );
          }(),
      ];
      // Por nombre sin tildes: SQLite ordena por bytes.
      return own..sort(
        (a, b) =>
            normalizeForSearch(a.name).compareTo(normalizeForSearch(b.name)),
      );
    });
  }

  @override
  Future<void> upsert(SyncedCategory category) => _db
      .into(_db.localCategories)
      .insertOnConflictUpdate(
        LocalCategoriesCompanion.insert(
          id: category.id,
          userId: Value(category.userId),
          slug: Value(category.slug),
          name: category.name,
          icon: Value(category.icon),
          color: Value(category.color),
          fiscalTag: category.fiscalTag,
          isSystem: category.isSystem,
        ),
      );

  @override
  Future<void> remove(String id) => _db.transaction(() async {
    final uncategorized = await (_db.select(
      _db.localCategories,
    )..where((c) => c.slug.equals(_uncategorizedSlug))).getSingleOrNull();
    await (_db.update(
      _db.localTransactions,
    )..where((t) => t.categoryId.equals(id))).write(
      LocalTransactionsCompanion(categoryId: Value(uncategorized?.id)),
    );
    await (_db.delete(
      _db.localCategories,
    )..where((c) => c.id.equals(id))).go();
  });
}
