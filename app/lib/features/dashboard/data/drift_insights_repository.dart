import 'package:drift/drift.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/dashboard/domain/insights_repository.dart';
import 'package:luka/features/dashboard/domain/monthly_summary.dart';

/// [InsightsRepository] sobre la base local Drift (F4.6).
///
/// Una sola consulta agregada cubre el mes y el anterior:
///
/// ```sql
/// SELECT t.kind, t.occurred_at >= :from AS in_month, t.category_id,
///        c.slug, c.name, SUM(t.amount_cents),
///        (SELECT id   FROM local_categories WHERE slug = 'sin_categoria'),
///        (SELECT name FROM local_categories WHERE slug = 'sin_categoria')
/// FROM local_transactions t LEFT JOIN local_categories c
///   ON c.id = t.category_id
/// WHERE t.kind != 'transfer'
///   AND t.occurred_at >= :previousFrom AND t.occurred_at < :to
/// GROUP BY t.kind, in_month, t.category_id
/// ```
///
/// Las fechas se guardan como texto ISO-8601 (`store_date_time_values_as_text`)
/// y Drift compara los `DateTime` con `julianday(...)`, no como texto, así
/// que el desfase de zona no altera el orden. Los totales se suman en Dart
/// sobre los grupos (enteros); las categorías salen de los grupos `expense`
/// del mes. Como la consulta lee `local_transactions` y `local_categories`
/// (también en las subconsultas), el stream se reemite si cambia cualquiera.
class DriftInsightsRepository implements InsightsRepository {
  DriftInsightsRepository(this._db);

  final AppDatabase _db;

  static const _transfer = 'transfer';
  static const _expense = 'expense';
  static const _income = 'income';

  @override
  Stream<MonthlySummary> watchMonth(ColombiaMonth month) {
    final t = _db.localTransactions;
    final c = _db.localCategories;
    final u = _db.alias(c, 'uncategorized');
    final current = month.range();
    final previous = month.previous.range();

    final inMonth = t.occurredAt.isBiggerOrEqualValue(current.from);
    final total = t.amountCents.sum();
    final uncategorizedId = subqueryExpression<String>(
      _db.selectOnly(u)
        ..addColumns([u.id])
        ..where(u.slug.equals(uncategorizedSlug))
        ..limit(1),
    );
    final uncategorizedName = subqueryExpression<String>(
      _db.selectOnly(u)
        ..addColumns([u.name])
        ..where(u.slug.equals(uncategorizedSlug))
        ..limit(1),
    );

    final query =
        _db.selectOnly(t).join([
            leftOuterJoin(c, c.id.equalsExp(t.categoryId), useColumns: false),
          ])
          ..addColumns([
            t.kind,
            inMonth,
            t.categoryId,
            c.slug,
            c.name,
            total,
            uncategorizedId,
            uncategorizedName,
          ])
          ..where(
            t.kind.isNotValue(_transfer) &
                t.occurredAt.isBiggerOrEqualValue(previous.from) &
                t.occurredAt.isSmallerThanValue(current.to),
          )
          ..groupBy([t.kind, inMonth, t.categoryId]);

    return query.watch().map((rows) {
      var expenses = 0;
      var income = 0;
      var previousExpenses = 0;
      var previousIncome = 0;
      final spends = <CategorySpend>[];
      UncategorizedCategory? uncategorized;

      for (final row in rows) {
        final kind = row.read(t.kind);
        final isCurrent = row.read(inMonth) ?? false;
        final cents = row.read(total) ?? 0;
        switch ((kind, isCurrent)) {
          case (_expense, true):
            expenses += cents;
            spends.add(
              CategorySpend(
                categoryId: row.read(t.categoryId),
                amount: Cop(cents),
                slug: row.read(c.slug),
                name: row.read(c.name),
              ),
            );
          case (_expense, false):
            previousExpenses += cents;
          case (_income, true):
            income += cents;
          case (_income, false):
            previousIncome += cents;
        }
        final id = row.read(uncategorizedId);
        final name = row.read(uncategorizedName);
        if (id != null && name != null) uncategorized = (id: id, name: name);
      }

      return buildSummary(
        month: month,
        totals: MonthlyTotals(expenses: Cop(expenses), income: Cop(income)),
        previousTotals: MonthlyTotals(
          expenses: Cop(previousExpenses),
          income: Cop(previousIncome),
        ),
        spends: spends,
        uncategorized: uncategorized,
      );
    });
  }
}
