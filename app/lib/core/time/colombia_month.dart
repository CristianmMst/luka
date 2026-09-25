// `freezed_annotation` reexporta `package:meta` (`@immutable`).
import 'package:freezed_annotation/freezed_annotation.dart';

/// Colombia no tiene horario de verano: hora local = UTC−5 siempre.
const colombiaOffset = Duration(hours: 5);

/// Instante local (America/Bogota) de un instante UTC, representado como un
/// `DateTime` UTC con los mismos campos de calendario que la hora local.
DateTime toColombiaLocal(DateTime instant) =>
    instant.toUtc().subtract(colombiaOffset);

/// Mes calendario en hora de Colombia (UTC−5 fijo).
///
/// Va de las 00:00 del día 1 a las 00:00 del día 1 del mes siguiente, hora
/// local; [range] lo da como instantes UTC en un intervalo `[from, to)`.
@immutable
class ColombiaMonth implements Comparable<ColombiaMonth> {
  /// Acepta [month] fuera de 1-12 y lo normaliza (13 → enero del año
  /// siguiente, 0 → diciembre del anterior).
  factory ColombiaMonth(int year, int month) {
    final normalized = DateTime.utc(year, month);
    return ColombiaMonth._(normalized.year, normalized.month);
  }

  /// El mes local que contiene [instant].
  factory ColombiaMonth.containing(DateTime instant) {
    final local = toColombiaLocal(instant);
    return ColombiaMonth._(local.year, local.month);
  }

  const ColombiaMonth._(this.year, this.month);

  final int year;

  /// 1-12.
  final int month;

  /// Instante UTC de la medianoche local del día 1.
  DateTime get start => DateTime.utc(year, month).add(colombiaOffset);

  ColombiaMonth get previous => ColombiaMonth(year, month - 1);

  ColombiaMonth get next => ColombiaMonth(year, month + 1);

  /// `[from, to)` en UTC.
  ({DateTime from, DateTime to}) range() => (from: start, to: next.start);

  bool isAfter(ColombiaMonth other) => compareTo(other) > 0;

  bool isBefore(ColombiaMonth other) => compareTo(other) < 0;

  @override
  int compareTo(ColombiaMonth other) =>
      year != other.year ? year - other.year : month - other.month;

  @override
  bool operator ==(Object other) =>
      other is ColombiaMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'ColombiaMonth($year-${'$month'.padLeft(2, '0')})';
}
