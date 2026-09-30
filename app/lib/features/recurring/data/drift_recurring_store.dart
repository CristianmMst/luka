import 'package:drift/drift.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/recurring_ports.dart';

/// [RecurringStore] sobre Drift (spec 004 §5).
class DriftRecurringStore implements RecurringStore {
  DriftRecurringStore(this._db);

  final AppDatabase _db;

  @override
  Stream<List<RecurringExpense>> watchExpenses() {
    final query = _db.select(_db.localRecurringExpenses)
      ..orderBy([
        (e) => OrderingTerm.asc(e.dayOfMonth),
        (e) => OrderingTerm.asc(e.name.collate(Collate.noCase)),
      ]);
    return query.watch().map((rows) => [for (final r in rows) _expense(r)]);
  }

  @override
  Stream<List<RecurringOccurrence>> watchOccurrences(ColombiaMonth month) {
    final period = '${month.year}-${'${month.month}'.padLeft(2, '0')}';
    final occ = _db.localRecurringOccurrences;
    final exp = _db.localRecurringExpenses;
    final query =
        _db.select(occ).join([innerJoin(exp, exp.id.equalsExp(occ.expenseId))])
          ..where(occ.period.equals(period))
          ..orderBy([
            OrderingTerm.asc(occ.dueDate),
            OrderingTerm.asc(exp.name.collate(Collate.noCase)),
          ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          _occurrence(row.readTable(occ), row.readTable(exp)),
      ],
    );
  }

  @override
  Future<void> replaceAll(
    List<RecurringExpense> expenses,
    List<RecurringOccurrence> occurrences,
  ) => _db.transaction(() async {
    await _db.delete(_db.localRecurringOccurrences).go();
    await _db.delete(_db.localRecurringExpenses).go();
    await _db.batch((b) {
      b
        ..insertAll(_db.localRecurringExpenses, [
          for (final e in expenses) _expenseCompanion(e),
        ])
        ..insertAll(_db.localRecurringOccurrences, [
          for (final o in occurrences) _occurrenceCompanion(o),
        ]);
    });
  });

  @override
  Future<void> upsertExpense(RecurringExpense expense) => _db
      .into(_db.localRecurringExpenses)
      .insertOnConflictUpdate(_expenseCompanion(expense));

  @override
  Future<void> removeExpense(String id) => _db.transaction(() async {
    await (_db.delete(
      _db.localRecurringOccurrences,
    )..where((o) => o.expenseId.equals(id))).go();
    await (_db.delete(
      _db.localRecurringExpenses,
    )..where((e) => e.id.equals(id))).go();
  });

  @override
  Future<void> upsertOccurrence(RecurringOccurrence occurrence) => _db
      .into(_db.localRecurringOccurrences)
      .insertOnConflictUpdate(_occurrenceCompanion(occurrence));

  @override
  Future<List<PaymentCandidate>> candidates(
    DateTime dueDate,
    Cop expected,
  ) async {
    // La ventana es de días de Colombia: de las 00:00 de `due - 5` a las
    // 24:00 de `due + 5`, en UTC.
    const window = Duration(days: detectionWindowDays);
    final from = dueDate.subtract(window).add(colombiaOffset);
    final to = dueDate
        .add(window)
        .add(const Duration(days: 1))
        .add(colombiaOffset);
    final t = _db.localTransactions;
    final rows =
        await (_db.select(t)..where(
              (row) =>
                  row.kind.equals('expense') &
                  row.direction.equals('debit') &
                  row.occurredAt.isBiggerOrEqualValue(from) &
                  row.occurredAt.isSmallerThanValue(to),
            ))
            .get();
    final candidates = [
      for (final r in rows)
        PaymentCandidate(
          id: r.id,
          amount: Cop(r.amountCents),
          occurredAt: r.occurredAt,
          merchant: r.merchant,
        ),
    ];
    int gap(PaymentCandidate c) => (c.amount.cents - expected.cents).abs();
    return candidates..sort((a, b) {
      final byGap = gap(a).compareTo(gap(b));
      return byGap != 0 ? byGap : b.occurredAt.compareTo(a.occurredAt);
    });
  }

  RecurringExpense _expense(LocalRecurringExpenseRow r) => RecurringExpense(
    id: r.id,
    name: r.name,
    merchantKeyword: r.merchantKeyword,
    expectedAmount: Cop(r.expectedAmountCents),
    tolerancePct: r.tolerancePct,
    dayOfMonth: r.dayOfMonth,
    remindDaysBefore: r.remindDaysBefore,
    active: r.active,
    categoryId: r.categoryId,
    accountId: r.accountId,
  );

  RecurringOccurrence _occurrence(
    LocalRecurringOccurrenceRow o,
    LocalRecurringExpenseRow e,
  ) {
    final due = DateTime.parse(o.dueDate);
    return RecurringOccurrence(
      id: o.id,
      expenseId: o.expenseId,
      name: e.name,
      expectedAmount: Cop(e.expectedAmountCents),
      categoryId: e.categoryId,
      period: o.period,
      dueDate: DateTime.utc(due.year, due.month, due.day),
      status: OccurrenceStatus.fromWire(o.status),
      matchedBy: o.matchedBy,
      paidAt: o.paidAt,
      transactionId: o.transactionId,
      transactionMerchant: o.transactionMerchant,
      transactionAmount: switch (o.transactionAmountCents) {
        final cents? => Cop(cents),
        null => null,
      },
      transactionOccurredAt: o.transactionOccurredAt,
    );
  }

  LocalRecurringExpensesCompanion _expenseCompanion(RecurringExpense e) =>
      LocalRecurringExpensesCompanion.insert(
        id: e.id,
        name: e.name,
        merchantKeyword: e.merchantKeyword,
        expectedAmountCents: e.expectedAmount.cents,
        tolerancePct: e.tolerancePct,
        dayOfMonth: e.dayOfMonth,
        remindDaysBefore: e.remindDaysBefore,
        active: e.active,
        categoryId: Value(e.categoryId),
        accountId: Value(e.accountId),
      );

  LocalRecurringOccurrencesCompanion _occurrenceCompanion(
    RecurringOccurrence o,
  ) => LocalRecurringOccurrencesCompanion.insert(
    id: o.id,
    expenseId: o.expenseId,
    period: o.period,
    dueDate: _isoDate(o.dueDate),
    status: o.status.name,
    matchedBy: Value(o.matchedBy),
    paidAt: Value(o.paidAt),
    transactionId: Value(o.transactionId),
    transactionMerchant: Value(o.transactionMerchant),
    transactionAmountCents: Value(o.transactionAmount?.cents),
    transactionOccurredAt: Value(o.transactionOccurredAt),
  );

  static String _isoDate(DateTime d) =>
      '${d.year}-${'${d.month}'.padLeft(2, '0')}-${'${d.day}'.padLeft(2, '0')}';
}
