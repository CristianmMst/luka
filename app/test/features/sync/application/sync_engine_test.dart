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
      () => store.markSending(any()),
      () => store.restoreFromServer(any(), any()),
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
    'relee el outbox tras cada operación: el canje de id llega al envío',
    () async {
      final create = entry(
        1,
        OutboxOperation.createTransaction(localId: 'l1', data: newTx()),
      );
      const patch = TransactionPatch(categoryId: 'c2');
      final stalePatch = entry(
        2,
        const OutboxOperation.patchTransaction(id: 'l1', patch: patch),
      );
      final swappedPatch = entry(
        2,
        const OutboxOperation.patchTransaction(id: 'srv-1', patch: patch),
      );
      final reads = [
        [create, stalePatch],
        [swappedPatch],
        <OutboxEntry>[],
      ];
      when(
        () => store.pendingOutbox(),
      ).thenAnswer((_) async => reads.removeAt(0));
      when(() => remote.send(create)).thenAnswer((_) async => tx('srv-1', now));
      when(
        () => remote.send(swappedPatch),
      ).thenAnswer((_) async => tx('srv-1', now));

      final result = await engine.run();

      expect(result, SyncRunResult.synced);
      verify(() => remote.send(swappedPatch)).called(1);
      verifyNever(() => remote.send(stalePatch));
    },
  );

  test('una operación cancelada durante el ciclo no se envía', () async {
    final e1 = entry(1, const OutboxOperation.deleteTransaction(id: 'a'));
    final e2 = entry(2, const OutboxOperation.deleteTransaction(id: 'b'));
    final reads = [
      [e1, e2],
      <OutboxEntry>[],
    ];
    when(
      () => store.pendingOutbox(),
    ).thenAnswer((_) async => reads.removeAt(0));
    when(() => remote.send(e1)).thenAnswer((_) async => null);

    await engine.run();

    verify(() => remote.send(e1)).called(1);
    verifyNever(() => remote.send(e2));
  });

  test('marca el envío antes de mandar la operación', () async {
    final e1 = entry(
      1,
      OutboxOperation.createTransaction(localId: 'l1', data: newTx()),
    );
    when(() => store.pendingOutbox()).thenAnswer((_) async => [e1]);
    when(() => remote.send(e1)).thenThrow(const RemoteFailure.network());

    await engine.run();

    verifyInOrder([
      () => store.markSending(e1),
      () => remote.send(e1),
      () => store.recordAttempt(e1, 'network'),
    ]);
  });

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

  test(
    'pull incremental se solapa 5 min con el cursor, sin bajar de epoch',
    () async {
      final cursor = DateTime.utc(2026, 9, 23, 11, 3);
      when(() => store.transactionsCursor()).thenAnswer((_) async => cursor);

      await engine.run();

      verify(
        () => remote.transactionsSince(DateTime.utc(2026, 9, 23, 10, 58)),
      ).called(1);

      when(
        () => store.transactionsCursor(),
      ).thenAnswer((_) async => DateTime.utc(1970, 1, 1, 0, 2));

      await engine.run();

      verify(() => remote.transactionsSince(epoch)).called(1);
    },
  );

  test('fallo de red en el pull devuelve offline sin markSynced', () async {
    when(
      () => remote.transactionsSince(any(), cursor: any(named: 'cursor')),
    ).thenThrow(const RemoteFailure.network());

    final result = await engine.run();

    expect(result, SyncRunResult.offline);
    verifyNever(() => store.markSynced(any()));
  });

  group('rechazo: restaura la verdad del servidor', () {
    const forbidden = RemoteFailure(statusCode: 403, code: 'forbidden');

    test('patch rechazado trae y restaura la transacción objetivo', () async {
      final e1 = entry(
        1,
        const OutboxOperation.patchTransaction(
          id: 't1',
          patch: TransactionPatch(categoryId: 'c2'),
        ),
      );
      final server = tx('t1', now);
      when(() => store.pendingOutbox()).thenAnswer((_) async => [e1]);
      when(() => remote.send(e1)).thenThrow(forbidden);
      when(() => remote.fetchTransaction('t1')).thenAnswer((_) async => server);

      final result = await engine.run();

      expect(result, SyncRunResult.synced);
      verifyInOrder([
        () => store.reject(e1, 'forbidden'),
        () => remote.fetchTransaction('t1'),
        () => store.restoreFromServer('t1', server),
      ]);
    });

    test('emparejar rechazado restaura las dos transacciones', () async {
      final e1 = entry(
        1,
        const OutboxOperation.setTransferPair(id: 'a', pairId: 'b'),
      );
      when(() => store.pendingOutbox()).thenAnswer((_) async => [e1]);
      when(() => remote.send(e1)).thenThrow(forbidden);
      when(
        () => remote.fetchTransaction(any()),
      ).thenAnswer((i) async => tx(i.positionalArguments.first as String, now));

      await engine.run();

      verify(() => store.restoreFromServer('a', tx('a', now))).called(1);
      verify(() => store.restoreFromServer('b', tx('b', now))).called(1);
    });

    test(
      'borrado rechazado que el servidor ya no tiene restaura null',
      () async {
        final e1 = entry(1, const OutboxOperation.deleteTransaction(id: 'a'));
        when(() => store.pendingOutbox()).thenAnswer((_) async => [e1]);
        when(() => remote.send(e1)).thenThrow(forbidden);
        when(() => remote.fetchTransaction('a')).thenAnswer((_) async => null);

        await engine.run();

        verify(() => store.restoreFromServer('a', null)).called(1);
      },
    );

    test('un fallo al traer la transacción no rompe el ciclo', () async {
      final e1 = entry(1, const OutboxOperation.unsetTransferPair(id: 'a'));
      final e2 = entry(2, const OutboxOperation.deleteTransaction(id: 'b'));
      when(() => store.pendingOutbox()).thenAnswer((_) async => [e1, e2]);
      when(() => remote.send(e1)).thenThrow(forbidden);
      when(() => remote.send(e2)).thenAnswer((_) async => null);
      when(
        () => remote.fetchTransaction('a'),
      ).thenThrow(const RemoteFailure.network());

      final result = await engine.run();

      expect(result, SyncRunResult.synced);
      verifyNever(() => store.restoreFromServer(any(), any()));
      verify(() => remote.send(e2)).called(1);
      verify(() => store.markSynced(now)).called(1);
    });

    test(
      'dependiente de una creación rechazada restaura solo los ids del '
      'servidor',
      () async {
        final e2 = entry(
          2,
          const OutboxOperation.setTransferPair(id: 'srv', pairId: 'l1'),
        );
        when(() => store.rejectedCreates()).thenAnswer((_) async => {'l1'});
        when(() => store.pendingOutbox()).thenAnswer((_) async => [e2]);
        when(
          () => remote.fetchTransaction('srv'),
        ).thenAnswer((_) async => tx('srv', now));

        await engine.run();

        verify(() => store.reject(e2, 'dependency_rejected')).called(1);
        verify(() => store.restoreFromServer('srv', tx('srv', now))).called(1);
        verifyNever(() => remote.fetchTransaction('l1'));
      },
    );

    test('crear o convertir rechazado no consulta el servidor', () async {
      final e1 = entry(
        1,
        OutboxOperation.createTransaction(localId: 'l1', data: newTx()),
      );
      final e2 = entry(
        2,
        OutboxOperation.convertReview(
          rawMessageId: 'r1',
          localId: 'l2',
          data: newTx(),
        ),
      );
      when(() => store.pendingOutbox()).thenAnswer((_) async => [e1, e2]);
      when(() => remote.send(any())).thenThrow(
        const RemoteFailure(statusCode: 422, code: 'invalid'),
      );

      final result = await engine.run();

      expect(result, SyncRunResult.synced);
      verifyNever(() => remote.fetchTransaction(any()));
      verifyNever(() => store.restoreFromServer(any(), any()));
    });
  });
}
