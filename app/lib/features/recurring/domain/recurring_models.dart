import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/core/format/money.dart';

part 'recurring_models.freezed.dart';

/// Estado guardado de una ocurrencia (spec 004 §2.13).
enum OccurrenceStatus {
  pending,
  paid,
  skipped;

  static OccurrenceStatus fromWire(String value) => switch (value) {
    'paid' => paid,
    'skipped' => skipped,
    _ => pending,
  };
}

/// Cómo se ve una ocurrencia hoy (spec 011 §2).
enum OccurrenceState {
  /// Pendiente y todavía no vence.
  upcoming,

  /// Venció, pero aún está dentro de los 5 días de la ventana.
  late,

  /// Pasaron los 5 días y no se detectó el pago.
  undetected,

  /// Pagada: se muestra tachada.
  paid,

  /// Omitida este mes.
  skipped,
}

/// Días de la ventana de detección después del vencimiento (spec 011 §2).
const detectionWindowDays = 5;

/// Un gasto fijo mensual (spec 004 §2.12).
@freezed
abstract class RecurringExpense with _$RecurringExpense {
  const factory RecurringExpense({
    required String id,
    required String name,
    required String merchantKeyword,
    required Cop expectedAmount,
    required int tolerancePct,
    required int dayOfMonth,
    required int remindDaysBefore,
    required bool active,
    String? categoryId,
    String? accountId,
  }) = _RecurringExpense;
}

/// Un gasto fijo en un mes, con el movimiento que lo pagó si lo hay.
///
/// [dueDate] es una fecha sin hora (`DateTime.utc(año, mes, día)`) en el
/// calendario de Colombia.
@freezed
abstract class RecurringOccurrence with _$RecurringOccurrence {
  const factory RecurringOccurrence({
    required String id,
    required String expenseId,
    required String name,
    required Cop expectedAmount,
    required String period,
    required DateTime dueDate,
    required OccurrenceStatus status,
    String? categoryId,
    String? matchedBy,
    DateTime? paidAt,
    String? transactionId,
    String? transactionMerchant,
    Cop? transactionAmount,
    DateTime? transactionOccurredAt,
  }) = _RecurringOccurrence;
}

/// Un gasto local que podría haber pagado una ocurrencia ("Elegir
/// movimiento", spec 008 §3.8).
@freezed
abstract class PaymentCandidate with _$PaymentCandidate {
  const factory PaymentCandidate({
    required String id,
    required Cop amount,
    required DateTime occurredAt,
    String? merchant,
  }) = _PaymentCandidate;
}

/// Fecha de hoy en Colombia, sin hora.
DateTime colombiaToday(DateTime now) {
  final local = now.toUtc().subtract(const Duration(hours: 5));
  return DateTime.utc(local.year, local.month, local.day);
}

/// Estado visible de [occurrence] el día [today] (fecha sin hora).
OccurrenceState occurrenceStateOf(
  RecurringOccurrence occurrence,
  DateTime today,
) {
  switch (occurrence.status) {
    case OccurrenceStatus.paid:
      return OccurrenceState.paid;
    case OccurrenceStatus.skipped:
      return OccurrenceState.skipped;
    case OccurrenceStatus.pending:
      if (!today.isAfter(occurrence.dueDate)) return OccurrenceState.upcoming;
      final windowEnd = occurrence.dueDate.add(
        const Duration(days: detectionWindowDays),
      );
      return today.isAfter(windowEnd)
          ? OccurrenceState.undetected
          : OccurrenceState.late;
  }
}

/// `2026-10` del mes de [dueDate]; es el `period` del backend.
String periodOf(DateTime dueDate) =>
    '${dueDate.year}-${'${dueDate.month}'.padLeft(2, '0')}';
