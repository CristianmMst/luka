import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/manual_draft.dart';
import 'package:luka/features/transactions/domain/transaction_edit.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';

final _at = DateTime.utc(2026, 10, 4, 20, 31);

TransactionView _tx({String? merchant = 'FRISBY I 24', String? accountId}) =>
    TransactionView(
      id: 'tx-1',
      amount: Cop.pesos(99000),
      direction: TxDirection.debit,
      kind: TxKind.expense,
      occurredAt: _at,
      channels: const {TxChannel.email},
      sync: SyncMark.none,
      merchant: merchant,
      categoryId: 'mercado',
      accountId: accountId,
    );

void main() {
  group('TransactionEdit', () {
    test('sale prellenado con el movimiento', () {
      final edit = TransactionEdit.from(_tx(accountId: 'acc-1'));

      expect(edit.amount, Cop.pesos(99000));
      expect(edit.direction, TxDirection.debit);
      expect(edit.occurredAt, _at);
      expect(edit.merchant, 'FRISBY I 24');
      expect(edit.categoryId, 'mercado');
      expect(edit.accountId, 'acc-1');
    });

    test('sin cambios no hay patch', () {
      final tx = _tx();
      expect(TransactionEdit.from(tx).patchFrom(tx), isNull);
    });

    test('el patch solo lleva lo que cambió', () {
      final tx = _tx(accountId: 'acc-1');
      final edit = TransactionEdit.from(tx).copyWith(
        amount: Cop.pesos(45900),
        direction: TxDirection.credit,
        occurredAt: _at.add(const Duration(hours: 1)),
        merchant: '  Frisby  ',
        accountId: 'acc-2',
      );

      expect(
        edit.patchFrom(tx),
        TransactionPatch(
          amount: Cop.pesos(45900),
          direction: TxDirection.credit,
          occurredAt: _at.add(const Duration(hours: 1)),
          merchant: (value: 'Frisby'),
          accountId: (value: 'acc-2'),
          learnMerchantRule: false,
        ),
      );
    });

    test('vaciar el comercio o la cuenta los borra', () {
      final tx = _tx(accountId: 'acc-1');
      final edit = TransactionEdit.from(
        tx,
      ).copyWith(merchant: '   ', accountId: null);

      expect(
        edit.patchFrom(tx),
        const TransactionPatch(
          merchant: (value: null),
          accountId: (value: null),
          learnMerchantRule: false,
        ),
      );
    });

    test('la categoría nueva aprende la regla solo si se pide', () {
      final tx = _tx();
      final edit = TransactionEdit.from(
        tx,
      ).copyWith(categoryId: 'restaurantes');

      expect(edit.categoryChanged(tx), isTrue);
      expect(
        edit.patchFrom(tx, learnMerchantRule: true),
        const TransactionPatch(categoryId: 'restaurantes'),
      );
    });

    test('sin monto o en cero no es válido', () {
      final edit = TransactionEdit.from(_tx());
      expect(edit.copyWith(amount: null).validate(), {
        ManualDraftError.amountRequired,
      });
      expect(edit.copyWith(amount: const Cop(0)).validate(), {
        ManualDraftError.amountRequired,
      });
      expect(edit.validate(), isEmpty);
    });
  });
}
