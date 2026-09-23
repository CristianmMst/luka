import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_group.freezed.dart';

/// Colombia no tiene horario de verano: hora local = UTC−5 siempre.
const _colombiaOffset = Duration(hours: 5);

/// Día local (America/Bogota) de [instant], como un `DateTime` UTC con hora
/// 00:00 (solo se usa como llave de calendario, no como instante real).
DateTime _colombiaDay(DateTime instant) {
  final local = instant.toUtc().subtract(_colombiaOffset);
  return DateTime.utc(local.year, local.month, local.day);
}

enum DayLabel { today, yesterday, other }

@freezed
abstract class DayGroup with _$DayGroup {
  const factory DayGroup({
    required DateTime day,
    required DayLabel label,
    required Cop expenses,
    required List<TransactionView> items,
  }) = _DayGroup;
}

/// Agrupa por día local (America/Bogota, UTC−5 fijo, sin horario de
/// verano), en orden descendente. `expenses` suma solo `kind == expense`
/// (excluye transferencias e ingresos, AC-9.1).
List<DayGroup> groupByDay(List<TransactionView> items, DateTime now) {
  final today = _colombiaDay(now);
  final yesterday = today.subtract(const Duration(days: 1));

  final byDay = <DateTime, List<TransactionView>>{};
  for (final item in items) {
    byDay.putIfAbsent(_colombiaDay(item.occurredAt), () => []).add(item);
  }

  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

  return [
    for (final day in days)
      DayGroup(
        day: day,
        label: switch (day) {
          _ when day == today => DayLabel.today,
          _ when day == yesterday => DayLabel.yesterday,
          _ => DayLabel.other,
        },
        expenses: Cop(
          byDay[day]!
              .where((t) => t.kind == TxKind.expense)
              .fold(0, (sum, t) => sum + t.amount.cents),
        ),
        items: byDay[day]!,
      ),
  ];
}
