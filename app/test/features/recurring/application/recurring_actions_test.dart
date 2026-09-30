import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/recurring/application/recurring_actions.dart';
import 'package:luka/features/recurring/domain/recurring_draft.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/recurring_ports.dart';
import 'package:luka/features/sync/domain/sync_rules.dart';
import 'package:mocktail/mocktail.dart';

class _Remote extends Mock implements RecurringRemote {}

class _Store extends Mock implements RecurringStore {}

const _expense = RecurringExpense(
  id: 'e-1',
  name: 'Spotify',
  merchantKeyword: 'spotify',
  expectedAmount: Cop(1690000),
  tolerancePct: 10,
  dayOfMonth: 22,
  remindDaysBefore: 1,
  active: true,
);

final _occurrence = RecurringOccurrence(
  id: 'o-1',
  expenseId: 'e-1',
  name: 'Spotify',
  expectedAmount: const Cop(1690000),
  period: '2026-10',
  dueDate: DateTime.utc(2026, 10, 22),
  status: OccurrenceStatus.paid,
);

const _draft = RecurringDraft(
  name: '  Spotify ',
  merchantKeyword: ' spotify ',
  expectedAmount: Cop(1690000),
  dayOfMonth: 22,
);

void main() {
  late _Remote remote;
  late _Store store;
  late int syncs;
  late RecurringActions actions;

  setUpAll(() {
    registerFallbackValue(_draft);
    registerFallbackValue(_expense);
    registerFallbackValue(_occurrence);
    registerFallbackValue(ColombiaMonth(2026, 10));
  });

  setUp(() {
    remote = _Remote();
    store = _Store();
    syncs = 0;
    actions = RecurringActions(
      remote: remote,
      store: store,
      requestSync: () => syncs++,
    );
    when(() => store.upsertExpense(any())).thenAnswer((_) async {});
    when(() => store.upsertOccurrence(any())).thenAnswer((_) async {});
    when(() => store.removeExpense(any())).thenAnswer((_) async {});
  });

  test('crear envía el borrador limpio, guarda en local y pide sync', () async {
    when(() => remote.create(any())).thenAnswer((_) async => _expense);

    final created = await actions.create(_draft);

    expect(created, _expense);
    final sent = verify(() => remote.create(captureAny())).captured.single;
    expect((sent as RecurringDraft).name, 'Spotify');
    expect(sent.merchantKeyword, 'spotify');
    verify(() => store.upsertExpense(_expense)).called(1);
    expect(syncs, 1);
  });

  test('un borrador inválido no llega al servidor', () async {
    await expectLater(
      actions.create(_draft.copyWith(name: '')),
      throwsA(isA<InvalidRecurringDraft>()),
    );
    verifyNever(() => remote.create(any()));
  });

  test('editar, pausar y borrar', () async {
    when(() => remote.update(any(), any())).thenAnswer((_) async => _expense);
    when(
      () => remote.setActive(any(), active: any(named: 'active')),
    ).thenAnswer((_) async => _expense.copyWith(active: false));
    when(() => remote.delete(any())).thenAnswer((_) async {});

    await actions.update('e-1', _draft);
    final paused = await actions.setActive('e-1', active: false);
    await actions.delete('e-1');

    expect(paused.active, isFalse);
    verify(() => store.removeExpense('e-1')).called(1);
    expect(syncs, 2);
  });

  test('marcar, deshacer y omitir actualizan la ocurrencia local', () async {
    when(
      () => remote.markPaid(any(), transactionId: any(named: 'transactionId')),
    ).thenAnswer((_) async => _occurrence);
    when(() => remote.unmark(any())).thenAnswer((_) async => _occurrence);
    when(() => remote.skip(any())).thenAnswer((_) async => _occurrence);

    await actions.markPaid('o-1', transactionId: 't-1');
    await actions.unmark('o-1');
    await actions.skip('o-1');

    verify(() => remote.markPaid('o-1', transactionId: 't-1')).called(1);
    verify(() => store.upsertOccurrence(_occurrence)).called(3);
  });

  test('un fallo del servidor no toca la copia local', () async {
    when(() => remote.unmark(any())).thenThrow(const RecurringConflict());

    await expectLater(
      actions.unmark('o-1'),
      throwsA(isA<RecurringConflict>()),
    );
    verifyNever(() => store.upsertOccurrence(any()));
  });

  group('RecurringSnapshot', () {
    RecurringSnapshot snapshot() => RecurringSnapshot(
      remote: remote,
      store: store,
      now: () => DateTime.utc(2026, 10, 15, 12),
    );

    test(
      'trae los gastos y las ocurrencias del mes anterior al siguiente',
      () async {
        when(() => remote.expenses()).thenAnswer((_) async => [_expense]);
        when(
          () => remote.occurrences(any(), any()),
        ).thenAnswer((_) async => [_occurrence]);
        when(() => store.replaceAll(any(), any())).thenAnswer((_) async {});

        await snapshot().refresh();

        verify(
          () => remote.occurrences(
            ColombiaMonth(2026, 9),
            ColombiaMonth(2026, 11),
          ),
        ).called(1);
        verify(() => store.replaceAll([_expense], [_occurrence])).called(1);
      },
    );

    test('sin red lanza RemoteFailure.network para el motor de sync', () async {
      when(() => remote.expenses()).thenThrow(const RecurringOffline());

      await expectLater(
        snapshot().refresh(),
        throwsA(
          isA<RemoteFailure>().having((f) => f.isNetwork, 'isNetwork', isTrue),
        ),
      );
    });

    test('un 401 conserva el status para cerrar la sesión', () async {
      when(
        () => remote.expenses(),
      ).thenThrow(const RecurringUnexpected(statusCode: 401));

      await expectLater(
        snapshot().refresh(),
        throwsA(
          isA<RemoteFailure>().having((f) => f.statusCode, 'status', 401),
        ),
      );
      verifyNever(() => store.replaceAll(any(), any()));
    });
  });
}
