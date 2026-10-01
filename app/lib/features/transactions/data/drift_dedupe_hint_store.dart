import 'package:luka/core/db/app_database.dart';
import 'package:luka/features/transactions/domain/dedupe_hint_store.dart';

/// La marca del aviso "Sin duplicados" en `sync_state`. Cerrar sesión vacía
/// la tabla y el aviso vuelve a aparecer.
class DriftDedupeHintStore implements DedupeHintStore {
  DriftDedupeHintStore(this._db);

  final AppDatabase _db;

  static const key = 'dedupe_hint_dismissed';

  @override
  Future<bool> wasDismissed() async {
    final row = await (_db.select(
      _db.syncState,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> dismiss() => _db
      .into(_db.syncState)
      .insertOnConflictUpdate(SyncStateCompanion.insert(key: key, value: '1'));
}
