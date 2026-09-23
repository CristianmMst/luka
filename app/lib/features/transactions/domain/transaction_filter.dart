import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_filter.freezed.dart';

enum PeriodPreset { thisMonth, lastMonth, thisYear, custom }

/// Colombia no tiene horario de verano: hora local = UTC−5 siempre.
const _colombiaOffset = Duration(hours: 5);

/// Instante local (America/Bogota) de un instante UTC, representado como un
/// `DateTime` UTC con los mismos campos de calendario que la hora local.
DateTime _toColombiaLocal(DateTime instant) =>
    instant.toUtc().subtract(_colombiaOffset);

/// Instante UTC de la medianoche local de [year]-[month]-01. Acepta [month]
/// fuera de 1-12: `DateTime.utc` normaliza el desborde (diciembre → enero y
/// viceversa).
DateTime _monthStartUtc(int year, int month) =>
    DateTime.utc(year, month).add(_colombiaOffset);

@freezed
abstract class TransactionFilter with _$TransactionFilter {
  const factory TransactionFilter({
    @Default(PeriodPreset.thisMonth) PeriodPreset period,
    DateTime? from,
    DateTime? to,
    @Default(<TxKind>{}) Set<TxKind> kinds,
    @Default(<String>{}) Set<String> banks,
    @Default(<TxChannel>{}) Set<TxChannel> channels,
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
    if (categoryId != null) count++;
    if (period != PeriodPreset.thisMonth) count++;
    return count;
  }

  /// Rango `[from, to)` en hora de Colombia para el periodo (`custom` usa
  /// `from`/`to`, y cae al mes en curso si faltan).
  ({DateTime from, DateTime to}) range(DateTime now) {
    final local = _toColombiaLocal(now);
    return switch (period) {
      PeriodPreset.thisMonth => (
        from: _monthStartUtc(local.year, local.month),
        to: _monthStartUtc(local.year, local.month + 1),
      ),
      PeriodPreset.lastMonth => (
        from: _monthStartUtc(local.year, local.month - 1),
        to: _monthStartUtc(local.year, local.month),
      ),
      PeriodPreset.thisYear => (
        from: _monthStartUtc(local.year, 1),
        to: _monthStartUtc(local.year + 1, 1),
      ),
      PeriodPreset.custom => (
        from: from ?? _monthStartUtc(local.year, local.month),
        to: to ?? _monthStartUtc(local.year, local.month + 1),
      ),
    };
  }
}
