import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';

/// Un aviso local de gasto fijo (iPhone, spec 011 §5.1).
@immutable
final class LocalReminder {
  const LocalReminder({
    required this.id,
    required this.occurrenceId,
    required this.fireAt,
    required this.title,
    required this.body,
  });

  /// Id del aviso en el sistema: hash estable del `occurrence_id`.
  final int id;
  final String occurrenceId;

  /// Instante del aviso, en UTC.
  final DateTime fireAt;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is LocalReminder &&
      other.id == id &&
      other.occurrenceId == occurrenceId &&
      other.fireAt == fireAt &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, occurrenceId, fireAt, title, body);
}

/// Programa en el teléfono los avisos de gastos fijos. En Android no hace
/// nada (el servidor envía FCM). Interfaz y no typedef: la implementa el
/// servicio de avisos de iPhone junto con `PushService`.
// ignore: one_member_abstracts
abstract interface class ReminderScheduler {
  /// Cancela los avisos anteriores y programa [reminders].
  Future<void> replaceAll(List<LocalReminder> reminders);
}

/// Sin avisos locales (Android y tests).
final class NoReminderScheduler implements ReminderScheduler {
  const NoReminderScheduler();

  @override
  Future<void> replaceAll(List<LocalReminder> reminders) async {}
}

/// 09:00 en Colombia = 14:00 UTC (UTC−5 fijo, sin horario de verano).
const _reminderHourUtc = 14;

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Los avisos que deben quedar programados ahora (spec 011 §5.1): uno por
/// ocurrencia pendiente de un gasto fijo activo, a las 09:00 de Colombia del
/// día `vencimiento − días de aviso`. Los que ya pasaron no se programan.
List<LocalReminder> plannedReminders({
  required List<RecurringOccurrence> occurrences,
  required List<RecurringExpense> expenses,
  required DateTime now,
}) {
  final byId = {for (final e in expenses) e.id: e};
  final seen = <String>{};
  final reminders = <LocalReminder>[];
  for (final occurrence in occurrences) {
    final expense = byId[occurrence.expenseId];
    if (expense == null || !expense.active) continue;
    if (occurrence.status != OccurrenceStatus.pending) continue;
    if (!seen.add(occurrence.id)) continue;
    final due = occurrence.dueDate;
    final fireDay = due.subtract(Duration(days: expense.remindDaysBefore));
    final fireAt = DateTime.utc(
      fireDay.year,
      fireDay.month,
      fireDay.day,
      _reminderHourUtc,
    );
    if (!fireAt.isAfter(now)) continue;
    reminders.add(
      LocalReminder(
        id: reminderIdFor(occurrence.id),
        occurrenceId: occurrence.id,
        fireAt: fireAt,
        title: 'Se acerca tu pago de ${occurrence.name}',
        body: reminderBody(
          amount: occurrence.expectedAmount,
          dueDate: due,
          daysBefore: expense.remindDaysBefore,
        ),
      ),
    );
  }
  reminders.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return reminders;
}

/// El mismo cuerpo que el push del servidor (spec 011 §5).
String reminderBody({
  required Cop amount,
  required DateTime dueDate,
  required int daysBefore,
}) {
  final day = '${dueDate.day} de ${_months[dueDate.month - 1]}';
  final money = formatCop(amount);
  return daysBefore == 1
      ? 'Mañana, $day, se te descontarán $money de tu cuenta.'
      : 'El $day se te descontarán $money de tu cuenta.';
}

/// Hash FNV-1a de 31 bits: estable entre ejecuciones (a diferencia de
/// `String.hashCode`) y positivo, como exige el id de un aviso.
int reminderIdFor(String occurrenceId) {
  var hash = 0x811c9dc5;
  for (final unit in occurrenceId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
