import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/domain/outbox_operation.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/application/transaction_actions.dart';
import 'package:finanzia/features/transactions/domain/manual_draft.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Coordinator extends Mock implements SyncCoordinator {}

TransactionView _tx({
  String? merchant = 'Éxito',
  TxDirection direction = TxDirection.debit,
  TxKind kind = TxKind.expense,
}) => TransactionView(
  id: 't1',
  amount: Cop.pesos(1000),
  direction: direction,
  kind: kind,
  occurredAt: DateTime.utc(2026, 9, 23),
  channels: const {},
  sync: SyncMark.none,
  merchant: merchant,
  notes: 'antes',
);

void main() {
  late _Coordinator coordinator;
  late TransactionActions actions;

  setUpAll(() {
    registerFallbackValue(const OutboxOperation.deleteTransaction(id: 'f'));
  });

  setUp(() {
    coordinator = _Coordinator();
    actions = TransactionActions(coordinator);
    when(() => coordinator.enqueue(any())).thenAnswer((_) async {});
    when(() => coordinator.retryRejected(any())).thenAnswer((_) async {});
    when(() => coordinator.discardRejected(any())).thenAnswer((_) async {});
  });

  OutboxOperation patch(TransactionPatch patch) =>
      OutboxOperation.patchTransaction(id: 't1', patch: patch);

  group('changeCategory', () {
    test('con comercio y "siempre" aprende la regla', () async {
      await actions.changeCategory(_tx(), 'c2', always: true);

      verify(
        () => coordinator.enqueue(
          patch(const TransactionPatch(categoryId: 'c2')),
        ),
      ).called(1);
    });

    test('"solo esta" no aprende la regla', () async {
      await actions.changeCategory(_tx(), 'c2', always: false);

      verify(
        () => coordinator.enqueue(
          patch(
            const TransactionPatch(categoryId: 'c2', learnMerchantRule: false),
          ),
        ),
      ).called(1);
    });

    for (final merchant in [null, '', '   ']) {
      test('sin comercio ("$merchant") no aprende la regla', () async {
        await actions.changeCategory(
          _tx(merchant: merchant),
          'c2',
          always: true,
        );

        verify(
          () => coordinator.enqueue(
            patch(
              const TransactionPatch(
                categoryId: 'c2',
                learnMerchantRule: false,
              ),
            ),
          ),
        ).called(1);
      });
    }
  });

  group('setTransfer', () {
    test('marcar como transferencia envía kind transfer', () async {
      await actions.setTransfer(_tx(), isTransfer: true);

      verify(
        () => coordinator.enqueue(
          patch(
            const TransactionPatch(
              kind: TxKind.transfer,
              learnMerchantRule: false,
            ),
          ),
        ),
      ).called(1);
    });

    test('desmarcar un débito lo deja como gasto', () async {
      await actions.setTransfer(_tx(kind: TxKind.transfer), isTransfer: false);

      verify(
        () => coordinator.enqueue(
          patch(
            const TransactionPatch(
              kind: TxKind.expense,
              learnMerchantRule: false,
            ),
          ),
        ),
      ).called(1);
    });

    test('desmarcar un crédito lo deja como ingreso', () async {
      await actions.setTransfer(
        _tx(direction: TxDirection.credit, kind: TxKind.transfer),
        isTransfer: false,
      );

      verify(
        () => coordinator.enqueue(
          patch(
            const TransactionPatch(
              kind: TxKind.income,
              learnMerchantRule: false,
            ),
          ),
        ),
      ).called(1);
    });
  });

  group('saveNotes', () {
    test('guarda la nota sin espacios de sobra', () async {
      await actions.saveNotes(_tx(), '  Almuerzo con el equipo ');

      verify(
        () => coordinator.enqueue(
          patch(
            const TransactionPatch(
              notes: (value: 'Almuerzo con el equipo'),
              learnMerchantRule: false,
            ),
          ),
        ),
      ).called(1);
    });

    for (final blank in ['', '  \n ']) {
      test('una nota vacía la borra (${blank.length} caracteres)', () async {
        await actions.saveNotes(_tx(), blank);

        verify(
          () => coordinator.enqueue(
            patch(
              const TransactionPatch(
                notes: (value: null),
                learnMerchantRule: false,
              ),
            ),
          ),
        ).called(1);
      });
    }
  });

  test('retryRejected delega en el coordinador', () async {
    await actions.retryRejected('t1');

    verify(() => coordinator.retryRejected('t1')).called(1);
  });

  test('discardRejected delega en el coordinador', () async {
    await actions.discardRejected('t1');

    verify(() => coordinator.discardRejected('t1')).called(1);
  });

  group('create', () {
    final at = DateTime.utc(2026, 9, 25, 20);

    test('encola la creación con un id local nuevo y lo devuelve', () async {
      when(() => coordinator.newLocalId()).thenReturn('local-1');

      final id = await actions.create(
        ManualDraft(
          occurredAt: at,
          amount: Cop.pesos(12500),
          merchant: ' Panadería ',
          categoryId: 'c-1',
        ),
      );

      expect(id, 'local-1');
      verify(
        () => coordinator.enqueue(
          OutboxOperation.createTransaction(
            localId: 'local-1',
            data: NewTransaction(
              amount: Cop.pesos(12500),
              direction: TxDirection.debit,
              occurredAt: at,
              merchant: 'Panadería',
              categoryId: 'c-1',
            ),
          ),
        ),
      ).called(1);
    });

    test('un borrador sin monto no se encola', () async {
      when(() => coordinator.newLocalId()).thenReturn('local-1');

      await expectLater(
        actions.create(ManualDraft(occurredAt: at)),
        throwsA(isA<InvalidManualDraft>()),
      );
      verifyNever(() => coordinator.enqueue(any()));
    });
  });

  test('resolveId delega en el coordinador', () {
    when(() => coordinator.resolveId('local-1')).thenReturn('srv-1');
    expect(actions.resolveId('local-1'), 'srv-1');
  });

  group('delete', () {
    test('encola el borrado con el id local si no se ha canjeado', () async {
      when(() => coordinator.resolveId('local-1')).thenReturn('local-1');

      await actions.delete('local-1');

      verify(
        () => coordinator.enqueue(
          const OutboxOperation.deleteTransaction(id: 'local-1'),
        ),
      ).called(1);
    });

    test('con el id ya canjeado borra el del servidor', () async {
      when(() => coordinator.resolveId('local-1')).thenReturn('srv-1');

      await actions.delete('local-1');

      verify(
        () => coordinator.enqueue(
          const OutboxOperation.deleteTransaction(id: 'srv-1'),
        ),
      ).called(1);
    });
  });
}
