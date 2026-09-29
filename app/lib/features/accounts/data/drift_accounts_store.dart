import 'package:drift/drift.dart';
import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/features/accounts/domain/accounts_ports.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';

/// [AccountsStore] sobre la base local Drift (spec 004 §5). El pull de cada
/// sync sigue siendo la verdad: `replaceAccounts` reemplaza todo.
class DriftAccountsStore implements AccountsStore {
  DriftAccountsStore(this._db);

  final AppDatabase _db;

  @override
  Stream<List<LinkedAccount>> watchAll() {
    final a = _db.localAccounts;
    final t = _db.localTransactions;
    final count = t.id.count();
    final query =
        _db.select(a).join([
            leftOuterJoin(t, t.accountId.equalsExp(a.id), useColumns: false),
          ])
          ..addColumns([count])
          ..groupBy([a.id])
          ..orderBy([OrderingTerm.asc(a.bank), OrderingTerm.asc(a.last4)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          () {
            final account = row.readTable(a);
            return LinkedAccount(
              id: account.id,
              bank: account.bank,
              kind: account.kind,
              last4: account.last4,
              alias: account.alias,
              transactionCount: row.read(count) ?? 0,
            );
          }(),
      ],
    );
  }

  @override
  Future<void> upsert(SyncedAccount account) => _db
      .into(_db.localAccounts)
      .insertOnConflictUpdate(
        LocalAccountsCompanion.insert(
          id: account.id,
          bank: account.bank,
          kind: account.kind,
          last4: Value(account.last4),
          alias: Value(account.alias),
        ),
      );

  @override
  Future<void> remove(String id) => _db.transaction(() async {
    await (_db.update(_db.localTransactions)
          ..where((t) => t.accountId.equals(id)))
        .write(const LocalTransactionsCompanion(accountId: Value(null)));
    await (_db.delete(_db.localAccounts)..where((a) => a.id.equals(id))).go();
  });
}
