import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/sync/data/outbox_codec.dart';
import 'package:finanzia/features/sync/domain/outbox_operation.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ida y vuelta de cada operación sin ids en el payload', () {
    final data = NewTransaction(
      amount: Cop.pesos(45000),
      direction: TxDirection.debit,
      occurredAt: DateTime.utc(2026, 9, 22, 15),
      merchant: 'Éxito',
    );
    final ops = <OutboxOperation>[
      OutboxOperation.createTransaction(localId: 'l1', data: data),
      const OutboxOperation.patchTransaction(
        id: 't1',
        patch: TransactionPatch(categoryId: 'c1', notes: (value: null)),
      ),
      const OutboxOperation.setTransferPair(id: 't1', pairId: 't2'),
      const OutboxOperation.unsetTransferPair(id: 't1'),
      const OutboxOperation.deleteTransaction(id: 't1'),
      OutboxOperation.convertReview(
        rawMessageId: 'r1',
        localId: 'l2',
        data: data,
      ),
      const OutboxOperation.discardReview(rawMessageId: 'r1'),
    ];
    for (final op in ops) {
      final e = OutboxCodec.encode(op);
      expect(e.payload, isNot(contains(op.targetId)));
      expect(
        OutboxCodec.decode(
          kind: e.kind,
          targetId: e.targetId,
          relatedId: e.relatedId,
          payload: e.payload,
        ),
        op,
      );
    }
  });

  test('los kind quedan fijos por variante', () {
    const patch = TransactionPatch();
    final expected = <String, OutboxOperation>{
      'create_transaction': OutboxOperation.createTransaction(
        localId: 'l1',
        data: NewTransaction(
          amount: Cop.pesos(1),
          direction: TxDirection.credit,
          occurredAt: DateTime.utc(2026),
        ),
      ),
      'patch_transaction': const OutboxOperation.patchTransaction(
        id: 't1',
        patch: patch,
      ),
      'set_transfer_pair': const OutboxOperation.setTransferPair(
        id: 't1',
        pairId: 't2',
      ),
      'unset_transfer_pair': const OutboxOperation.unsetTransferPair(id: 't1'),
      'delete_transaction': const OutboxOperation.deleteTransaction(id: 't1'),
      'convert_review': OutboxOperation.convertReview(
        rawMessageId: 'r1',
        localId: 'l2',
        data: NewTransaction(
          amount: Cop.pesos(1),
          direction: TxDirection.credit,
          occurredAt: DateTime.utc(2026),
        ),
      ),
      'discard_review': const OutboxOperation.discardReview(
        rawMessageId: 'r1',
      ),
    };
    for (final MapEntry(key: kind, value: op) in expected.entries) {
      expect(OutboxCodec.encode(op).kind, kind);
    }
  });
}
