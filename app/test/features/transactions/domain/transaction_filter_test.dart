import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/domain/transaction_filter.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activeCount', () {
    test('sin filtros activos (periodo por defecto y texto no cuentan)', () {
      const filter = TransactionFilter(text: 'exito');
      expect(filter.activeCount, 0);
    });

    test('cada dimension no vacia suma uno', () {
      expect(
        const TransactionFilter(kinds: {TxKind.expense}).activeCount,
        1,
      );
      expect(
        const TransactionFilter(banks: {'Bancolombia'}).activeCount,
        1,
      );
      expect(
        const TransactionFilter(channels: {TxChannel.manual}).activeCount,
        1,
      );
      expect(const TransactionFilter(accountIds: {'a-1'}).activeCount, 1);
      expect(
        const TransactionFilter(categoryId: 'c1').activeCount,
        1,
      );
    });

    test('un periodo distinto de thisMonth cuenta como uno', () {
      expect(
        const TransactionFilter(period: PeriodPreset.lastMonth).activeCount,
        1,
      );
      expect(
        const TransactionFilter(period: PeriodPreset.thisYear).activeCount,
        1,
      );
      expect(
        const TransactionFilter(period: PeriodPreset.custom).activeCount,
        1,
      );
    });

    test('se acumulan todas las dimensiones activas', () {
      const filter = TransactionFilter(
        period: PeriodPreset.lastMonth,
        kinds: {TxKind.expense},
        banks: {'Bancolombia'},
        channels: {TxChannel.manual},
        categoryId: 'c1',
        text: 'algo',
      );
      expect(filter.activeCount, 5);
    });
  });

  group('range', () {
    const filter = TransactionFilter();

    test('thisMonth: limites del mes en curso en hora de Colombia', () {
      final now = DateTime.utc(2026, 9, 15, 12);
      final r = filter.range(now);
      expect(r.from, DateTime.utc(2026, 9, 1, 5));
      expect(r.to, DateTime.utc(2026, 10, 1, 5));
    });

    test('thisMonth cerca de medianoche usa el dia local, no el UTC', () {
      // UTC 2026-09-01T03:00 es 2026-08-31T22:00 en Bogota.
      final now = DateTime.utc(2026, 9, 1, 3);
      final r = const TransactionFilter().range(now);
      expect(r.from, DateTime.utc(2026, 8, 1, 5));
      expect(r.to, DateTime.utc(2026, 9, 1, 5));
    });

    test('lastMonth', () {
      final now = DateTime.utc(2026, 9, 15, 12);
      final r = const TransactionFilter(
        period: PeriodPreset.lastMonth,
      ).range(now);
      expect(r.from, DateTime.utc(2026, 8, 1, 5));
      expect(r.to, DateTime.utc(2026, 9, 1, 5));
    });

    test('thisYear', () {
      final now = DateTime.utc(2026, 9, 15, 12);
      final r = const TransactionFilter(
        period: PeriodPreset.thisYear,
      ).range(now);
      expect(r.from, DateTime.utc(2026, 1, 1, 5));
      expect(r.to, DateTime.utc(2027, 1, 1, 5));
    });

    test('thisMonth en diciembre cruza a enero del ano siguiente', () {
      final now = DateTime.utc(2026, 12, 10, 12);
      final r = const TransactionFilter().range(now);
      expect(r.from, DateTime.utc(2026, 12, 1, 5));
      expect(r.to, DateTime.utc(2027, 1, 1, 5));
    });

    test('lastMonth en enero retrocede a diciembre del ano anterior', () {
      final now = DateTime.utc(2026, 1, 10, 12);
      final r = const TransactionFilter(
        period: PeriodPreset.lastMonth,
      ).range(now);
      expect(r.from, DateTime.utc(2025, 12, 1, 5));
      expect(r.to, DateTime.utc(2026, 1, 1, 5));
    });

    test('custom usa from/to del filtro, sin importar el mes en curso', () {
      final now = DateTime.utc(2026, 9, 15, 12);
      final r = TransactionFilter(
        period: PeriodPreset.custom,
        from: DateTime.utc(2026, 3, 5, 5),
        to: DateTime.utc(2026, 3, 20, 5),
      ).range(now);
      expect(r.from, DateTime.utc(2026, 3, 5, 5));
      expect(r.to, DateTime.utc(2026, 3, 20, 5));
    });

    test('custom sin from/to cae de vuelta al mes en curso', () {
      final now = DateTime.utc(2026, 9, 15, 12);
      final r = const TransactionFilter(period: PeriodPreset.custom).range(now);
      expect(r.from, DateTime.utc(2026, 9, 1, 5));
      expect(r.to, DateTime.utc(2026, 10, 1, 5));
    });
  });
}
