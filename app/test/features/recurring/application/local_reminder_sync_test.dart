import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/recurring/application/local_reminder_sync.dart';
import 'package:luka/features/recurring/application/recurring_actions.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/recurring_ports.dart';
import 'package:luka/features/recurring/domain/reminder_plan.dart';
import 'package:mocktail/mocktail.dart';

class _Store extends Mock implements RecurringStore {}

class _Scheduler implements ReminderScheduler {
  final calls = <List<LocalReminder>>[];

  @override
  Future<void> replaceAll(List<LocalReminder> reminders) async =>
      calls.add(reminders);
}

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

RecurringOccurrence _occ(OccurrenceStatus status) => RecurringOccurrence(
  id: 'o-1',
  expenseId: 'e-1',
  name: 'Spotify',
  expectedAmount: const Cop(1690000),
  period: '2026-10',
  dueDate: DateTime.utc(2026, 10, 22),
  status: status,
);

void main() {
  late _Store store;
  late _Scheduler scheduler;
  late StreamController<List<RecurringExpense>> expenses;
  late StreamController<List<RecurringOccurrence>> october;
  late StreamController<List<RecurringOccurrence>> november;

  setUpAll(() => registerFallbackValue(ColombiaMonth(2026, 10)));

  setUp(() {
    store = _Store();
    scheduler = _Scheduler();
    expenses = StreamController.broadcast();
    october = StreamController.broadcast();
    november = StreamController.broadcast();
    when(() => store.watchExpenses()).thenAnswer((_) => expenses.stream);
    when(
      () => store.watchOccurrences(ColombiaMonth(2026, 10)),
    ).thenAnswer((_) => october.stream);
    when(
      () => store.watchOccurrences(ColombiaMonth(2026, 11)),
    ).thenAnswer((_) => november.stream);
  });

  ProviderContainer build({ReminderScheduler? custom}) {
    final c = ProviderContainer(
      overrides: [
        recurringStoreProvider.overrideWithValue(store),
        reminderSchedulerProvider.overrideWithValue(custom ?? scheduler),
        recurringClockProvider.overrideWithValue(
          () => DateTime.utc(2026, 10, 15, 12),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.listen(localReminderSyncProvider, (_, _) {});
    return c;
  }

  Future<void> emit(ProviderContainer c, OccurrenceStatus status) async {
    expenses.add(const [_spotify]);
    october.add([_occ(status)]);
    november.add(const []);
    await pumpEventQueue();
    await c.read(localReminderSyncProvider.notifier).settle();
  }

  test('programa el aviso cuando llegan gastos y ocurrencias', () async {
    final c = build();

    await emit(c, OccurrenceStatus.pending);

    final [reminders] = scheduler.calls;
    // Faltan 7 días a las 09:00 del 15: se programan los tres avisos.
    expect(reminders.map((r) => r.fireAt), [
      DateTime.utc(2026, 10, 15, 14),
      DateTime.utc(2026, 10, 20, 14),
      DateTime.utc(2026, 10, 21, 14),
    ]);
  });

  test('un pago tachado por el sync cancela el aviso', () async {
    final c = build();
    await emit(c, OccurrenceStatus.pending);

    october.add([_occ(OccurrenceStatus.paid)]);
    await pumpEventQueue();
    await c.read(localReminderSyncProvider.notifier).settle();

    expect(scheduler.calls.last, isEmpty);
  });

  test('sin cambios no vuelve a programar', () async {
    final c = build();
    await emit(c, OccurrenceStatus.pending);

    october.add([_occ(OccurrenceStatus.pending)]);
    await pumpEventQueue();

    expect(scheduler.calls, hasLength(1));
  });

  test('en Android (NoReminderScheduler) no observa nada', () async {
    build(custom: const NoReminderScheduler());
    await pumpEventQueue();

    verifyNever(() => store.watchExpenses());
  });
}
