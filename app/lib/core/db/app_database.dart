import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/db/tables.dart';

part 'app_database.g.dart';

/// Base local real del teléfono (spec 004 §5).
@DriftDatabase(
  tables: [
    LocalTransactions,
    LocalCategories,
    LocalAccounts,
    LocalReview,
    Outbox,
    SyncState,
    LocalNfcTags,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'luka'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 era una base vacía (F0.6): no hay datos que migrar.
      if (from < 2) {
        await m.createAll();
        return;
      }
      if (from == 2) {
        await m.addColumn(localTransactions, localTransactions.channels);
        // Reiniciar el cursor fuerza un pull completo que rellena los
        // canales (F4.2).
        await (delete(
          syncState,
        )..where((s) => s.key.equals('transactions_cursor'))).go();
      }
      // v4: plantillas de tags NFC (F4.5b).
      if (from < 4) await m.createTable(localNfcTags);
    },
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
