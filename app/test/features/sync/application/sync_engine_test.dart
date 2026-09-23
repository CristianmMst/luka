import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/sync/application/sync_engine.dart';
import 'package:finanzia/features/sync/domain/outbox_operation.dart';
import 'package:finanzia/features/sync/domain/sync_ports.dart';
import 'package:finanzia/features/sync/domain/sync_rules.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Store extends Mock implements SyncStore {}

class _Remote extends Mock implements SyncRemote {}

void main() {
  late _Store store;
  late _Remote remote;
  late SyncEngine engine;
  final now = DateTime.utc(2026, 9, 23, 12);
  final epoch = DateTime.utc(1970);

  OutboxEntry entry(int seq, OutboxOperation op) =>
      OutboxEntry(seq: seq, op: op, idempotencyKey: 'k$seq', attempts: 0);
  SyncedTransaction tx(String id, DateTime updatedAt) => SyncedTransaction(
    id: id,
    amount: Cop.pesos(1000),
    currency: 'COP',
    direction: TxDirection.debit,
    kind: TxKind.expense,
    occurredAt: updatedAt,
    categoryId: 'c',
    fiscalTag: 'no_deducible',
    transferAuto: false,
    parsedBy: 'manual',
    createdAt: updatedAt,
    updatedAt: updatedAt,
  );
  NewTransaction newTx() => NewTransaction(
    amount: Cop.pesos(1000),
    direction: TxDirection.debit,
    occurredAt: now,
  );

  setUpAll(() {
    registerFallbackValue(
      entry(0, const OutboxOperation.deleteTransaction(id: 'x')),
    );
    registerFallbackValue(<SyncedTransaction>[]);
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(tx('fallback', DateTime(2000)));
  });

  setUp(() {
    store = _Store();
    remote = _Remote();
    engine = SyncEngine(store: store, remote: remote, now: () => now);
    when(() => store.rejectedCreates()).thenAnswer((_) async => {});
    when(() => store.pendingOutbox()).thenAnswer((_) async => []);
    when(() => store.transactionsCursor()).thenAnswer((_) async => null);
    when(
      () => remote.transactionsSince(any(), cursor: any(named: 'cursor')),
    ).thenAnswer(
      (_) async => (items: <SyncedTransaction>[], nextCursor: null),
    );
    when(() => remote.categories()).thenAnswer((_) async => []);
    when(() => remote.accounts()).thenAnswer((_) async => []);
    when(() => remote.openReview()).thenAnswer((_) async => []);
    for (final stub in [
      () => store.complete(any(), any()),
      () => store.reject(any(), any()),
      () => store.recordAttempt(any(), any()),
      () => store.applyTransactions(any(), cursor: any(named: 'cursor')),
      () => store.replaceCategories(any()),
      () => store.replaceAccounts(any()),
      () => store.replaceReview(any()),
      () => store.markSynced(any()),
    ]) {
      when(stub).thenAnswer((_) async {});
    }
  });

  test(
    'push drena en orden FIFO antes del pull y marca sincronizado',
    () async {
      final e1 = entry(1, const OutboxOperation.deleteTransaction(id: 'a'));
      final e2 = entry(2, const OutboxOperation.deleteTransaction(id: 'b'));
      final serverTx1 = tx('a', now);
      final serverTx2 = tx('b', now);
      when(() => store.pendingOutbox()).thenAnswer((_) async => [e1, e2]);
      when(() => remote.send(e1)).thenAnswer((_) async => serverTx1);
      when(() => remote.send(e2)).thenAnswer((_) async => serverTx2);

      final result = await engine.run();

      expect(result, SyncRunResult.synced);
      verifyInOrder([
        () => remote.send(e1),
        () => store.complete(e1, serverTx1),
        () => remote.send(e2),
        () => store.complete(e2, serverTx2),
        () => remote.transactionsSince(epoch),
        () => store.markSynced(now),
      ]);
    },
  );

  test(
    'sin red: registra intento, no envía lo siguiente y devuelve offline',
    () async {
      final e1 = entry(1, const OutboxOperation.deleteTransaction(id: 'a'));
      final e2 = entry(2, const OutboxOperation.deleteTransaction(id: 'b'));
      when(() => store.pendingOutbox()).thenAnswer((_) async => [e1, e2]);
      when(() => remote.send(e1)).thenThrow(const RemoteFailure.network());

      final result = await engine.run();

      expect(result, SyncRunResult.offline);
      verify(() => store.recordAttempt(e1, 'network')).called(1);
      verifyNever(() => remote.send(e2));
      verifyNever(() => store.markSynced(any()));
    },
  );

  test(
    'rechazo de un crear arrastra a sus dependientes sin enviarlos',
    () async {
      final e1 = entry(
        1,
        OutboxOperation.createTransaction(localId: 'l1', data: newTx()),
      );
      final e2 = entry(
        2,
        const OutboxOperation.patchTransaction(
          id: 'l1',
          patch: TransactionPatch(),
        ),
      );
      when(() => store.pendingOutbox()).thenAnswer((_) async => [e1, e2]);
      when(
        () => remote.send(e1),
      ).thenThrow(const RemoteFailure(statusCode: 400, code: 'invalid'));

      final result = await engine.run();

      expect(result, SyncRunResult.synced);
      verify(() => store.reject(e1, 'invalid')).called(1);
      verify(() => store.reject(e2, 'dependency_rejected')).called(1);
      verifyNever(() => remote.send(e2));
    },
  );

  test(
    'dependientes de una creación rechazada antes tampoco se envían',
    () async {
      final e2 = entry(
        2,
        const OutboxOperation.patchTransaction(
          id: 'l1',
          patch: TransactionPatch(),
        ),
      );
      when(() => store.rejectedCreates()).thenAnswer((_) async => {'l1'});
      when(() => store.pendingOutbox()).thenAnswer((_) async => [e2]);

      final result = await engine.run();

      expect(result, SyncRunResult.synced);
      verify(() => store.reject(e2, 'dependency_rejected')).called(1);
      verifyNever(() => remote.send(e2));
    },
  );

  test('404 al borrar transacción se marca como hecho', () async {
    final e1 = entry(1, const OutboxOperation.deleteTransaction(id: 'a'));
    when(() => store.pendingOutbox()).thenAnswer((_) async => [e1]);
    when(() => remote.send(e1)).thenThrow(const RemoteFailure(statusCode: 404));

    final result = await engine.run();

    expect(result, SyncRunResult.synced);
    verify(() => store.complete(e1, null)).called(1);
  });

  test('401 corta el ciclo sin pull', () async {
    final e1 = entry(1, const OutboxOperation.deleteTransaction(id: 'a'));
    when(() => store.pendingOutbox()).thenAnswer((_) async => [e1]);
    when(() => remote.send(e1)).thenThrow(const RemoteFailure(statusCode: 401));

    final result = await engine.run();

    expect(result, SyncRunResult.sessionEnded);
    verifyNever(
      () => remote.transactionsSince(any(), cursor: any(named: 'cursor')),
    );
    verifyNever(() => store.markSynced(any()));
  });

  test(
    'pull paginado: mismo updated_since en todas las páginas, '
    'cursor = máximo updated_at',
    () async {
      final t1 = DateTime.utc(2026, 9, 20);
      final t2 = DateTime.utc(2026, 9, 22);
      final txA = tx('a', t2);
      final txB = tx('b', t1);
      when(
        () => remote.transactionsSince(epoch),
      ).thenAnswer((_) async => (items: [txA, txB], nextCursor: 'c1'));
      when(
        () => remote.transactionsSince(epoch, cursor: 'c1'),
      ).thenAnswer((_) async => (items: [txB], nextCursor: null));

      final result = await engine.run();

      expect(result, SyncRunResult.synced);
      verify(() => remote.transactionsSince(epoch)).called(1);
      verify(() => remote.transactionsSince(epoch, cursor: 'c1')).called(1);
      verify(
        () => store.applyTransactions([txA, txB], cursor: t2),
      ).called(1);
      verify(() => store.applyTransactions([txB], cursor: t1)).called(1);
    },
  );

  test('primer pull usa epoch UTC como updated_since', () async {
    when(() => store.transactionsCursor()).thenAnswer((_) async => null);

    final result = await engine.run();

    expect(result, SyncRunResult.synced);
    verify(() => remote.transactionsSince(epoch)).called(1);
  });

  test('fallo de red en el pull devuelve offline sin markSynced', () async {
    when(
      () => remote.transactionsSince(any(), cursor: any(named: 'cursor')),
    ).thenThrow(const RemoteFailure.network());

    final result = await engine.run();

    expect(result, SyncRunResult.offline);
    verifyNever(() => store.markSynced(any()));
  });
}
