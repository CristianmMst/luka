import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/day_group.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';

TransactionView _tx({
  required String id,
  required DateTime occurredAt,
  required int cents,
  TxKind kind = TxKind.expense,
  TxDirection direction = TxDirection.debit,
}) => TransactionView(
  id: id,
  amount: Cop(cents),
  direction: direction,
  kind: kind,
  occurredAt: occurredAt,
  channels: const {},
  sync: SyncMark.none,
);

void main() {
  group('groupByDay', () {
    // now: UTC 2026-09-23T17:00 == 2026-09-23T12:00 en Bogota (hoy).
    final now = DateTime.utc(2026, 9, 23, 17);

    test('etiqueta hoy y ayer segun Bogota, incluida la compra de 23:30', () {
      final items = [
        _tx(
          id: 'today-expense',
          // UTC 2026-09-23T15:00 == 2026-09-23T10:00 local.
          occurredAt: DateTime.utc(2026, 9, 23, 15),
          cents: 50000,
        ),
        _tx(
          id: 'late-night-purchase',
          // Local 2026-09-22T23:30 ya es 2026-09-23T04:30 en UTC.
          occurredAt: DateTime.utc(2026, 9, 23, 4, 30),
          cents: 20000,
        ),
        _tx(
          id: 'other-day',
          // UTC 2026-09-21T15:00 == 2026-09-21T10:00 local.
          occurredAt: DateTime.utc(2026, 9, 21, 15),
          cents: 7000,
        ),
      ];

      final groups = groupByDay(items, now);

      expect(groups, hasLength(3));
      expect(groups[0].label, DayLabel.today);
      expect(groups[0].day, DateTime.utc(2026, 9, 23));
      expect(groups[0].items.map((t) => t.id), ['today-expense']);

      expect(groups[1].label, DayLabel.yesterday);
      expect(groups[1].day, DateTime.utc(2026, 9, 22));
      expect(groups[1].items.map((t) => t.id), ['late-night-purchase']);

      expect(groups[2].label, DayLabel.other);
      expect(groups[2].day, DateTime.utc(2026, 9, 21));
    });

    test('los grupos quedan en orden descendente por dia', () {
      final items = [
        _tx(id: 'a', occurredAt: DateTime.utc(2026, 9, 21, 15), cents: 1000),
        _tx(id: 'b', occurredAt: DateTime.utc(2026, 9, 23, 15), cents: 1000),
        _tx(id: 'c', occurredAt: DateTime.utc(2026, 9, 22, 15), cents: 1000),
      ];

      final groups = groupByDay(items, now);

      expect(groups.map((g) => g.day), [
        DateTime.utc(2026, 9, 23),
        DateTime.utc(2026, 9, 22),
        DateTime.utc(2026, 9, 21),
      ]);
    });

    test(
      'expenses solo suma gastos; ingresos y transferencias no cuentan '
      '(AC-9.1)',
      () {
        final items = [
          _tx(
            id: 'expense',
            occurredAt: DateTime.utc(2026, 9, 23, 15),
            cents: 50000,
          ),
          _tx(
            id: 'income',
            occurredAt: DateTime.utc(2026, 9, 23, 14),
            cents: 999999,
            kind: TxKind.income,
            direction: TxDirection.credit,
          ),
          _tx(
            id: 'transfer',
            occurredAt: DateTime.utc(2026, 9, 23, 13),
            cents: 123456,
            kind: TxKind.transfer,
          ),
        ];

        final groups = groupByDay(items, now);

        expect(groups, hasLength(1));
        expect(groups.single.expenses, const Cop(50000));
        expect(groups.single.items, hasLength(3));
      },
    );

    test('lista vacia produce cero grupos', () {
      expect(groupByDay(const [], now), isEmpty);
    });
  });
}
