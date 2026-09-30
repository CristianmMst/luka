import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/dashboard/domain/monthly_summary.dart';

final _month = ColombiaMonth(2026, 9);

CategorySpend _spend(String id, int pesos, {String? name, String? slug}) =>
    CategorySpend(
      categoryId: id,
      amount: Cop.pesos(pesos),
      name: name ?? id,
      slug: slug,
    );

MonthlySummary _build(
  List<CategorySpend> spends, {
  UncategorizedCategory? uncategorized,
}) => buildSummary(
  month: _month,
  totals: const MonthlyTotals(),
  previousTotals: const MonthlyTotals(),
  spends: spends,
  uncategorized: uncategorized,
);

void main() {
  group('buildSummary', () {
    test('sin gastos: top vacio y Otras en 0', () {
      final summary = _build(const []);
      expect(summary.month, _month);
      expect(summary.topCategories, isEmpty);
      expect(summary.otherAmount, const Cop(0));
    });

    test('top 5 de mayor a menor y el resto suma en Otras', () {
      final summary = _build([
        _spend('a', 10),
        _spend('b', 70),
        _spend('c', 30),
        _spend('d', 50),
        _spend('e', 20),
        _spend('f', 60),
        _spend('g', 40),
      ]);
      expect(
        summary.topCategories.map((s) => s.categoryId),
        ['b', 'f', 'd', 'g', 'c'],
      );
      expect(summary.otherAmount, Cop.pesos(30));
    });

    test('con 5 o menos categorias no hay Otras', () {
      final summary = _build([_spend('a', 10), _spend('b', 20)]);
      expect(summary.topCategories.map((s) => s.categoryId), ['b', 'a']);
      expect(summary.otherAmount, const Cop(0));
    });

    test('empate de monto: por nombre sin importar mayusculas', () {
      final summary = _build([
        _spend('1', 10, name: 'mercado'),
        _spend('2', 10, name: 'Arriendo'),
        _spend('3', 10, name: 'Transporte'),
      ]);
      expect(
        summary.topCategories.map((s) => s.name),
        ['Arriendo', 'mercado', 'Transporte'],
      );
    });

    test('empate de monto y nombre: por id; sin nombre al final', () {
      final summary = _build([
        const CategorySpend(categoryId: 'z', amount: Cop(100)),
        const CategorySpend(categoryId: 'y', amount: Cop(100), name: 'M'),
        const CategorySpend(categoryId: null, amount: Cop(100)),
        const CategorySpend(categoryId: 'x', amount: Cop(100), name: 'M'),
        const CategorySpend(categoryId: 'w', amount: Cop(100)),
      ]);
      expect(
        summary.topCategories.map((s) => s.categoryId),
        ['x', 'y', null, 'w', 'z'],
      );
    });

    test('el corte del top 5 respeta el empate por nombre', () {
      final summary = _build([
        for (final name in ['F', 'E', 'D', 'C', 'B', 'A'])
          _spend(name, 10, name: name),
      ]);
      expect(
        summary.topCategories.map((s) => s.name),
        ['A', 'B', 'C', 'D', 'E'],
      );
      expect(summary.otherAmount, Cop.pesos(10));
    });

    test('los montos en 0 no entran al top', () {
      final summary = _build([_spend('a', 0), _spend('b', 5)]);
      expect(summary.topCategories.map((s) => s.categoryId), ['b']);
    });

    test('sin categoria es su propio grupo si no hay fila sin_categoria', () {
      final summary = _build([
        const CategorySpend(categoryId: null, amount: Cop(500)),
        _spend('a', 1),
      ]);
      expect(summary.topCategories.first.categoryId, isNull);
      expect(summary.topCategories.first.amount, const Cop(500));
    });

    test('lo sin categoria se suma a la fila sin_categoria si existe', () {
      final summary = _build(
        [
          const CategorySpend(categoryId: null, amount: Cop(50)),
          _spend('a', 3),
          _spend('sc', 2, name: 'Sin categoria', slug: uncategorizedSlug),
        ],
        uncategorized: (id: 'sc', name: 'Sin categoria'),
      );
      expect(summary.topCategories, [
        CategorySpend(categoryId: 'a', amount: Cop.pesos(3), name: 'a'),
        const CategorySpend(
          categoryId: 'sc',
          amount: Cop(250),
          name: 'Sin categoria',
          slug: uncategorizedSlug,
        ),
      ]);
    });

    test('sin fila previa, lo sin categoria toma id y nombre de la fila', () {
      final summary = _build(
        [const CategorySpend(categoryId: null, amount: Cop(500))],
        uncategorized: (id: 'sc', name: 'Sin categoria'),
      );
      expect(
        summary.topCategories.single,
        const CategorySpend(
          categoryId: 'sc',
          amount: Cop(500),
          slug: uncategorizedSlug,
          name: 'Sin categoria',
        ),
      );
    });

    test('filas repetidas de una categoria se suman', () {
      final summary = _build([
        const CategorySpend(categoryId: 'a', amount: Cop(100)),
        const CategorySpend(categoryId: 'a', amount: Cop(50), name: 'Mercado'),
      ]);
      expect(
        summary.topCategories.single,
        const CategorySpend(categoryId: 'a', amount: Cop(150), name: 'Mercado'),
      );
    });

    test('el top es inmodificable', () {
      final summary = _build([_spend('a', 1)]);
      expect(
        () => summary.topCategories.add(_spend('b', 1)),
        throwsUnsupportedError,
      );
    });
  });

  group('MonthlyTotals', () {
    test('por defecto en 0', () {
      const totals = MonthlyTotals();
      expect(totals.expenses, const Cop(0));
      expect(totals.income, const Cop(0));
      expect(totals.balance, const Cop(0));
    });

    test('balance = ingresos - gastos, negativo si se gasta mas', () {
      final totals = MonthlyTotals(
        expenses: Cop.pesos(300),
        income: Cop.pesos(100),
      );
      expect(totals.balance, Cop.pesos(-200));
    });
  });

  group('AmountDelta.between', () {
    test('mes anterior en 0: diferencia sin porcentaje', () {
      final delta = AmountDelta.between(Cop.pesos(1000), const Cop(0));
      expect(delta.difference, Cop.pesos(1000));
      expect(delta.percent, isNull);
    });

    test('ambos en 0', () {
      final delta = AmountDelta.between(const Cop(0), const Cop(0));
      expect(delta, const AmountDelta(difference: Cop(0)));
    });

    test('subida', () {
      final delta = AmountDelta.between(Cop.pesos(150), Cop.pesos(100));
      expect(delta, AmountDelta(difference: Cop.pesos(50), percent: 50));
    });

    test('bajada: diferencia y porcentaje negativos', () {
      final delta = AmountDelta.between(Cop.pesos(75), Cop.pesos(100));
      expect(delta, AmountDelta(difference: Cop.pesos(-25), percent: -25));
    });

    test('bajada a 0 es -100 %', () {
      final delta = AmountDelta.between(const Cop(0), Cop.pesos(100));
      expect(delta.percent, -100);
    });

    test('redondea al entero mas cercano, mitad lejos de cero', () {
      // 1/3 = 33,3 %; 2/3 = 66,7 %; 1/8 = 12,5 %.
      expect(AmountDelta.between(const Cop(4), const Cop(3)).percent, 33);
      expect(AmountDelta.between(const Cop(5), const Cop(3)).percent, 67);
      expect(AmountDelta.between(const Cop(9), const Cop(8)).percent, 13);
      expect(AmountDelta.between(const Cop(7), const Cop(8)).percent, -13);
      expect(AmountDelta.between(const Cop(1), const Cop(3)).percent, -67);
    });

    test('base negativa (balance): el porcentaje usa el valor absoluto', () {
      // De −100 a −50 mejora: +50 % sobre |−100|.
      final delta = AmountDelta.between(Cop.pesos(-50), Cop.pesos(-100));
      expect(delta, AmountDelta(difference: Cop.pesos(50), percent: 50));
    });
  });

  group('MonthlySummary', () {
    final summary = buildSummary(
      month: _month,
      totals: MonthlyTotals(expenses: Cop.pesos(120), income: Cop.pesos(200)),
      previousTotals: MonthlyTotals(
        expenses: Cop.pesos(100),
        income: Cop.pesos(250),
      ),
      spends: const [],
    );

    test('balance del mes', () {
      expect(summary.balance, Cop.pesos(80));
    });

    test('deltas de gastos, ingresos y balance', () {
      expect(
        summary.expensesDelta,
        AmountDelta(difference: Cop.pesos(20), percent: 20),
      );
      expect(
        summary.incomeDelta,
        AmountDelta(difference: Cop.pesos(-50), percent: -20),
      );
      // 80 vs 150: −70, −46,7 % → −47.
      expect(
        summary.balanceDelta,
        AmountDelta(difference: Cop.pesos(-70), percent: -47),
      );
    });

    test('mes anterior sin datos: todos los porcentajes en null', () {
      final first = buildSummary(
        month: _month,
        totals: MonthlyTotals(expenses: Cop.pesos(1), income: Cop.pesos(2)),
        previousTotals: const MonthlyTotals(),
        spends: const [],
      );
      expect(first.expensesDelta.percent, isNull);
      expect(first.incomeDelta.percent, isNull);
      expect(first.balanceDelta.percent, isNull);
    });
  });
}
