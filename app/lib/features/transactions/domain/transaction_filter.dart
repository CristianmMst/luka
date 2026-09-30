import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';

part 'transaction_filter.freezed.dart';

enum PeriodPreset { thisMonth, lastMonth, thisYear, custom }

@freezed
abstract class TransactionFilter with _$TransactionFilter {
  const factory TransactionFilter({
    @Default(PeriodPreset.thisMonth) PeriodPreset period,
    DateTime? from,
    DateTime? to,
    @Default(<TxKind>{}) Set<TxKind> kinds,
    @Default(<String>{}) Set<String> banks,
    @Default(<TxChannel>{}) Set<TxChannel> channels,

    /// Cuentas vinculadas (ids); vacío = todas.
    @Default(<String>{}) Set<String> accountIds,
    String? categoryId,
    @Default('') String text,
  }) = _TransactionFilter;

  const TransactionFilter._();

  /// Filtros activos para el contador del botón (el periodo por defecto y el
  /// texto no cuentan).
  int get activeCount {
    var count = 0;
    if (kinds.isNotEmpty) count++;
    if (banks.isNotEmpty) count++;
    if (channels.isNotEmpty) count++;
    if (accountIds.isNotEmpty) count++;
    if (categoryId != null) count++;
    if (period != PeriodPreset.thisMonth) count++;
    return count;
  }

  /// Rango `[from, to)` en hora de Colombia para el periodo (`custom` usa
  /// `from`/`to`, y cae al mes en curso si faltan).
  ({DateTime from, DateTime to}) range(DateTime now) {
    final month = ColombiaMonth.containing(now);
    return switch (period) {
      PeriodPreset.thisMonth => month.range(),
      PeriodPreset.lastMonth => month.previous.range(),
      PeriodPreset.thisYear => (
        from: ColombiaMonth(month.year, 1).start,
        to: ColombiaMonth(month.year + 1, 1).start,
      ),
      PeriodPreset.custom => (
        from: from ?? month.start,
        to: to ?? month.next.start,
      ),
    };
  }
}
