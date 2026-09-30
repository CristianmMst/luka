import 'package:drift/drift.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/features/nfc/domain/nfc_ports.dart';
import 'package:luka/features/transactions/domain/search.dart';

/// [NfcTagStore] sobre la base local Drift. Se vacía al cerrar sesión con el
/// resto de la base (`DriftSyncStore.clearAll`, P6).
class DriftNfcTagStore implements NfcTagStore {
  DriftNfcTagStore(this._db);

  final AppDatabase _db;

  static NfcTagTemplate _toDomain(LocalNfcTagRow row) => NfcTagTemplate(
    id: row.id,
    name: row.name,
    categoryId: row.categoryId,
    accountId: row.accountId,
    note: row.note,
  );

  @override
  Stream<List<NfcTagTemplate>> watchAll() => _db
      .select(_db.localNfcTags)
      .watch()
      .map(
        (rows) =>
            // Por nombre sin tildes: SQLite ordena por bytes.
            rows.map(_toDomain).toList()..sort(
              (a, b) => normalizeForSearch(
                a.name,
              ).compareTo(normalizeForSearch(b.name)),
            ),
      );

  @override
  Future<NfcTagTemplate?> get(String id) async {
    final row = await (_db.select(
      _db.localNfcTags,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> upsert(NfcTagTemplate template) => _db
      .into(_db.localNfcTags)
      .insertOnConflictUpdate(
        LocalNfcTagsCompanion.insert(
          id: template.id,
          name: template.name,
          categoryId: Value(template.categoryId),
          accountId: Value(template.accountId),
          note: Value(template.note),
        ),
      );

  @override
  Future<void> remove(String id) =>
      (_db.delete(_db.localNfcTags)..where((t) => t.id.equals(id))).go();
}
