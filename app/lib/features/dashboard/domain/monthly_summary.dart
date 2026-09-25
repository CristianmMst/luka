import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/core/time/colombia_month.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'monthly_summary.freezed.dart';

/// Gastos e ingresos de un mes; las transferencias nunca suman (AC-6.2).
@freezed
abstract class MonthlyTotals with _$MonthlyTotals {
  const factory MonthlyTotals({
    @Default(Cop(0)) Cop expenses,
    @Default(Cop(0)) Cop income,
  }) = _MonthlyTotals;

  const MonthlyTotals._();

  /// Ingresos menos gastos; negativo si se gastó más de lo que entró.
  Cop get balance => Cop(income.cents - expenses.cents);
}

/// Gasto de un mes en una categoría. [categoryId] es null para lo que no
/// tiene categoría y no hay fila `sin_categoria` a la cual asignarlo;
/// [name] es null si la categoría no está en la base local.
@freezed
abstract class CategorySpend with _$CategorySpend {
  const factory CategorySpend({
    required String? categoryId,
    required Cop amount,
    String? slug,
    String? name,
  }) = _CategorySpend;
}

/// Cambio frente al mes anterior. [percent] va redondeado al entero más
/// cercano y es null si el mes anterior fue 0 (sin división por cero).
@freezed
abstract class AmountDelta with _$AmountDelta {
  const factory AmountDelta({required Cop difference, int? percent}) =
      _AmountDelta;

  /// El porcentaje se mide sobre el valor absoluto de [previous], así un
  /// balance anterior negativo no invierte el signo.
  factory AmountDelta.between(Cop current, Cop previous) {
    final difference = current.cents - previous.cents;
    final base = previous.cents.abs();
    return AmountDelta(
      difference: Cop(difference),
      percent: base == 0 ? null : _roundedPercent(difference, base),
    );
  }
}

/// `round(numerator * 100 / base)`, mitad lejos de cero, sin `double`.
int _roundedPercent(int numerator, int base) {
  final scaled = numerator.abs() * 100;
  final rounded = (scaled * 2 + base) ~/ (base * 2);
  return numerator < 0 ? -rounded : rounded;
}

/// Resumen del Inicio para un mes (AC-9.1).
@freezed
abstract class MonthlySummary with _$MonthlySummary {
  const factory MonthlySummary({
    required ColombiaMonth month,
    required MonthlyTotals totals,
    required MonthlyTotals previousTotals,

    /// Hasta [topCategoriesCount] categorías de gasto, de mayor a menor.
    required List<CategorySpend> topCategories,

    /// Gasto del resto de categorías ("Otras categorías").
    required Cop otherAmount,
  }) = _MonthlySummary;

  const MonthlySummary._();

  Cop get balance => totals.balance;

  AmountDelta get expensesDelta =>
      AmountDelta.between(totals.expenses, previousTotals.expenses);

  AmountDelta get incomeDelta =>
      AmountDelta.between(totals.income, previousTotals.income);

  AmountDelta get balanceDelta =>
      AmountDelta.between(totals.balance, previousTotals.balance);
}

const topCategoriesCount = 5;

/// Fila `sin_categoria` de la base local, a la que va el gasto sin
/// categoría.
typedef UncategorizedCategory = ({String id, String name});

/// Arma el resumen: agrupa [spends] por categoría (lo que no tiene categoría
/// va a [uncategorized] si existe, o a un grupo con `categoryId` null),
/// descarta montos en 0, ordena por monto descendente con empate por nombre
/// y deja el top [topCategoriesCount]; el resto suma en `otherAmount`.
MonthlySummary buildSummary({
  required ColombiaMonth month,
  required MonthlyTotals totals,
  required MonthlyTotals previousTotals,
  required Iterable<CategorySpend> spends,
  UncategorizedCategory? uncategorized,
}) {
  final byCategory = <String?, CategorySpend>{};
  for (final spend in spends) {
    final assigned = spend.categoryId == null && uncategorized != null
        ? CategorySpend(
            categoryId: uncategorized.id,
            amount: spend.amount,
            slug: uncategorizedSlug,
            name: uncategorized.name,
          )
        : spend;
    final current = byCategory[assigned.categoryId];
    byCategory[assigned.categoryId] = current == null
        ? assigned
        : current.copyWith(
            amount: Cop(current.amount.cents + assigned.amount.cents),
            slug: current.slug ?? assigned.slug,
            name: current.name ?? assigned.name,
          );
  }

  final ranked = byCategory.values.where((s) => s.amount.cents > 0).toList()
    ..sort(_byAmountThenName);
  final top = ranked.take(topCategoriesCount).toList();
  final other = ranked
      .skip(topCategoriesCount)
      .fold(0, (sum, s) => sum + s.amount.cents);

  return MonthlySummary(
    month: month,
    totals: totals,
    previousTotals: previousTotals,
    topCategories: List.unmodifiable(top),
    otherAmount: Cop(other),
  );
}

const uncategorizedSlug = 'sin_categoria';

/// Monto descendente; en empate, nombre ascendente (sin nombre al final) y
/// luego id, para un orden estable.
int _byAmountThenName(CategorySpend a, CategorySpend b) {
  final byAmount = b.amount.cents.compareTo(a.amount.cents);
  if (byAmount != 0) return byAmount;
  final byName = switch ((a.name, b.name)) {
    (null, null) => 0,
    (null, _) => 1,
    (_, null) => -1,
    (final x?, final y?) => x.toLowerCase().compareTo(y.toLowerCase()),
  };
  if (byName != 0) return byName;
  return (a.categoryId ?? '').compareTo(b.categoryId ?? '');
}
