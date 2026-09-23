import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/domain/outbox_operation.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/application/transaction_actions.dart';
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
}
