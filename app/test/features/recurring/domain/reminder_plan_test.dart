import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/reminder_plan.dart';

const _spotify = RecurringExpense(
  id: 'e-1',
  name: 'Spotify',
  merchantKeyword: 'spotify',
  expectedAmount: Cop(1690000),
  tolerancePct: 0,
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
  // 15 de octubre, 07:00 en Colombia: antes del aviso de 7 días (09:00).
  final now = DateTime.utc(2026, 10, 15, 12);

  test('programa 3 avisos a las 09:00 de Colombia: 7, 2 y 1 días antes', () {
    final planned = plannedReminders(
      occurrences: [_occ()],
      expenses: const [_spotify],
      now: now,
    );

    expect(planned.map((r) => r.fireAt), [
      DateTime.utc(2026, 10, 15, 14),
      DateTime.utc(2026, 10, 20, 14),
      DateTime.utc(2026, 10, 21, 14),
    ]);
    expect(planned.first.title, 'Se acerca tu pago de Spotify');
    expect(planned.map((r) => r.body), [
      r'El 22 de octubre se te descontarán $16.900 de tu cuenta.',
      r'Pasado mañana, 22 de octubre, se te descontarán $16.900 de tu cuenta.',
      r'Mañana, 22 de octubre, se te descontarán $16.900 de tu cuenta.',
    ]);
    expect(planned.map((r) => r.id).toSet(), hasLength(3));
  });

  test('solo quedan los avisos que no han pasado', () {
    final planned = plannedReminders(
      occurrences: [_occ()],
      expenses: const [_spotify],
      now: DateTime.utc(2026, 10, 20, 15),
    );

    expect(planned.map((r) => r.fireAt), [DateTime.utc(2026, 10, 21, 14)]);
  });

  test('omite pagadas, omitidas, pausadas y sin gasto', () {
    final planned = plannedReminders(
      occurrences: [
        _occ(id: 'pagada', status: OccurrenceStatus.paid),
        _occ(id: 'omitida', status: OccurrenceStatus.skipped),
        _occ(id: 'huerfana', expenseId: 'nadie'),
      ],
      expenses: const [_spotify],
      now: now,
    );

    expect(planned, isEmpty);
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

    expect(planned.map((r) => r.occurrenceId), [
      'a',
      'a',
      'a',
      'b',
      'b',
      'b',
    ]);
  });

  test('el id del aviso es estable, positivo y distinto por clave', () {
    expect(reminderIdFor('o-1:7'), reminderIdFor('o-1:7'));
    expect(reminderIdFor('o-1:7'), isNot(reminderIdFor('o-1:2')));
    expect(reminderIdFor('7f3c1a2e-0000-4000-8000-000000000000:1'), isPositive);
  });

  test('NoReminderScheduler no hace nada', () async {
    await const NoReminderScheduler().replaceAll([]);
  });
}
