import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/synced_models.dart';

void main() {
  final data = NewTransaction(
    amount: Cop.pesos(45000),
    direction: TxDirection.debit,
    occurredAt: DateTime.utc(2026, 9, 22, 15),
  );

  test('targetId y relatedId por operación', () {
    expect(
      OutboxOperation.createTransaction(localId: 'l1', data: data).targetId,
      'l1',
    );
    const pair = OutboxOperation.setTransferPair(id: 't1', pairId: 't2');
    expect((pair.targetId, pair.relatedId), ('t1', 't2'));
    final convert = OutboxOperation.convertReview(
      rawMessageId: 'r1',
      localId: 'l2',
      data: data,
    );
    expect((convert.targetId, convert.relatedId), ('l2', 'r1'));
    expect(
      const OutboxOperation.discardReview(rawMessageId: 'r1').targetId,
      'r1',
    );
  });

  test('createsRecord solo en crear y convertir', () {
    expect(
      OutboxOperation.createTransaction(
        localId: 'l1',
        data: data,
      ).createsRecord,
      isTrue,
    );
    expect(
      OutboxOperation.convertReview(
        rawMessageId: 'r',
        localId: 'l',
        data: data,
      ).createsRecord,
      isTrue,
    );
    expect(
      const OutboxOperation.deleteTransaction(id: 't').createsRecord,
      isFalse,
    );
  });
}
