import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/reminder_plan.dart';

const _spotify = RecurringExpense(
  id: 'e-1',
  name: 'Spotify',
  merchantKeyword: 'spotify',
  expectedAmount: Cop(1690000),
  tolerancePct: 10,
  dayOfMonth: 22,
  remindDaysBefore: 1,
  active: true,
);

RecurringOccurrence _occ({
  String id = 'o-1',
  String expenseId = 'e-1',
  DateTime? due,
  OccurrenceStatus status = OccurrenceStatus.pending,
}) => RecurringOccurrence(
  id: id,
  expenseId: expenseId,
  name: 'Spotify',
  expectedAmount: const Cop(1690000),
  period: '2026-10',
  dueDate: due ?? DateTime.utc(2026, 10, 22),
  status: status,
);

void main() {
  final now = DateTime.utc(2026, 10, 15, 12);

  test(
    'avisa a las 09:00 de Colombia del día anterior, con el texto del push',
    () {
      final [reminder] = plannedReminders(
        occurrences: [_occ()],
        expenses: const [_spotify],
        now: now,
      );

      expect(reminder.fireAt, DateTime.utc(2026, 10, 21, 14));
      expect(reminder.occurrenceId, 'o-1');
      expect(reminder.title, 'Se acerca tu pago de Spotify');
      expect(
        reminder.body,
        r'Mañana, 22 de octubre, se te descontarán $16.900 de tu cuenta.',
      );
    },
  );

  test('con 2 días de aviso usa "El 22 de octubre"', () {
    final [reminder] = plannedReminders(
      occurrences: [_occ()],
      expenses: [_spotify.copyWith(remindDaysBefore: 2)],
      now: now,
    );

    expect(reminder.fireAt, DateTime.utc(2026, 10, 20, 14));
    expect(reminder.body, startsWith('El 22 de octubre se te descontarán'));
  });

  test('omite pagadas, omitidas, pausadas, sin gasto y las que ya pasaron', () {
    final planned = plannedReminders(
      occurrences: [
        _occ(id: 'pagada', status: OccurrenceStatus.paid),
        _occ(id: 'omitida', status: OccurrenceStatus.skipped),
        _occ(id: 'huerfana', expenseId: 'nadie'),
        _occ(id: 'pasada', due: DateTime.utc(2026, 10, 16)),
        _occ(id: 'justo', due: DateTime.utc(2026, 10, 17)),
      ],
      expenses: const [_spotify],
      now: DateTime.utc(2026, 10, 16, 13, 59),
    );

    expect(planned.map((r) => r.occurrenceId), ['justo']);
    expect(
      plannedReminders(
        occurrences: [_occ()],
        expenses: [_spotify.copyWith(active: false)],
        now: now,
      ),
      isEmpty,
    );
  });

  test('ordena por hora y no repite una ocurrencia', () {
    final planned = plannedReminders(
      occurrences: [
        _occ(id: 'b', due: DateTime.utc(2026, 11, 22)),
        _occ(id: 'a'),
        _occ(id: 'a'),
      ],
      expenses: const [_spotify],
      now: now,
    );

    expect(planned.map((r) => r.occurrenceId), ['a', 'b']);
  });

  test('el id del aviso es estable, positivo y distinto por ocurrencia', () {
    expect(reminderIdFor('o-1'), reminderIdFor('o-1'));
    expect(reminderIdFor('o-1'), isNot(reminderIdFor('o-2')));
    expect(reminderIdFor('7f3c1a2e-0000-4000-8000-000000000000'), isPositive);
  });

  test('NoReminderScheduler no hace nada', () async {
    await const NoReminderScheduler().replaceAll([]);
  });
}
