import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/data/outbox_requests.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/synced_models.dart';

void main() {
  final full = NewTransaction(
    amount: Cop.pesos(45000),
    direction: TxDirection.debit,
    occurredAt: DateTime.utc(2026, 9, 22, 15),
    kind: TxKind.expense,
    categoryId: 'c1',
    merchant: 'Éxito',
    description: 'mercado',
    accountId: 'a1',
    notes: 'nota',
    nfcTagId: 'tag-1',
  );
  const newTxKeys = {
    'amount',
    'direction',
    'occurred_at',
    'kind',
    'category_id',
    'merchant',
    'description',
    'account_id',
    'notes',
  };

  final table = <(String, OutboxOperation, String, String, Set<String>?)>[
    (
      'crear',
      OutboxOperation.createTransaction(localId: 'l1', data: full),
      'POST',
      '/v1/transactions',
      {...newTxKeys, 'nfc_tag_id'},
    ),
    (
      'patch',
      const OutboxOperation.patchTransaction(
        id: 't1',
        patch: TransactionPatch(categoryId: 'c2', kind: TxKind.income),
      ),
      'PATCH',
      '/v1/transactions/t1',
      {'category_id', 'kind', 'learn_merchant_rule'},
    ),
    (
      'emparejar',
      const OutboxOperation.setTransferPair(id: 't1', pairId: 't2'),
      'POST',
      '/v1/transactions/t1/transfer-pair',
      {'pair_id'},
    ),
    (
      'desemparejar',
      const OutboxOperation.unsetTransferPair(id: 't1'),
      'DELETE',
      '/v1/transactions/t1/transfer-pair',
      null,
    ),
    (
      'borrar',
      const OutboxOperation.deleteTransaction(id: 't1'),
      'DELETE',
      '/v1/transactions/t1',
      null,
    ),
    (
      'convertir (sin nfc_tag_id)',
      OutboxOperation.convertReview(
        rawMessageId: 'r1',
        localId: 'l2',
        data: full,
      ),
      'POST',
      '/v1/review/r1/convert',
      newTxKeys,
    ),
    (
      'descartar',
      const OutboxOperation.discardReview(rawMessageId: 'r1'),
      'POST',
      '/v1/review/r1/discard',
      null,
    ),
  ];

  for (final (name, op, method, path, keys) in table) {
    test('requestFor $name → $method $path', () {
      final request = requestFor(op);

      expect(request.method, method);
      expect(request.path, path);
      expect(request.body?.keys.toSet(), keys);
    });
  }

  test('crear sin opcionales solo envía los campos obligatorios', () {
    final request = requestFor(
      OutboxOperation.createTransaction(
        localId: 'l1',
        data: NewTransaction(
          amount: Cop.pesos(1000),
          direction: TxDirection.credit,
          occurredAt: DateTime.utc(2026, 9, 22, 15),
        ),
      ),
    );

    expect(request.body, {
      'amount': '1000.00',
      'direction': 'credit',
      'occurred_at': '2026-09-22T15:00:00.000Z',
    });
  });

  test('PATCH con notes y merchant en null los envía como null', () {
    final request = requestFor(
      const OutboxOperation.patchTransaction(
        id: 't1',
        patch: TransactionPatch(
          notes: (value: null),
          merchant: (value: null),
          learnMerchantRule: false,
        ),
      ),
    );

    expect(request.body, {
      'notes': null,
      'merchant': null,
      'learn_merchant_rule': false,
    });
  });

  test('PATCH de la edición envía monto, dirección, fecha y cuenta', () {
    final request = requestFor(
      OutboxOperation.patchTransaction(
        id: 't1',
        patch: TransactionPatch(
          amount: Cop.pesos(45900),
          direction: TxDirection.credit,
          occurredAt: DateTime.utc(2026, 10, 4, 20, 31),
          accountId: (value: 'acc-2'),
          learnMerchantRule: false,
        ),
      ),
    );

    expect(request.body, {
      'amount': '45900.00',
      'direction': 'credit',
      'occurred_at': '2026-10-04T20:31:00.000Z',
      'account_id': 'acc-2',
      'learn_merchant_rule': false,
    });
  });
}
