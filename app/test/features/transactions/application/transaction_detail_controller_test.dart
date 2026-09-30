import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/application/transaction_detail_controller.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';
import 'package:luka/features/transactions/domain/transactions_repository.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements TransactionsRepository {}

final _at = DateTime.utc(2026, 9, 23, 17);

final _view = TransactionView(
  id: 't1',
  amount: Cop.pesos(126400),
  direction: TxDirection.debit,
  kind: TxKind.expense,
  occurredAt: _at,
  channels: const {TxChannel.email},
  sync: SyncMark.none,
);

void main() {
  late _Repository repository;
  late StreamController<TransactionView?> one;
  late ProviderContainer container;

  setUp(() {
    repository = _Repository();
    one = StreamController<TransactionView?>.broadcast();
    when(() => repository.watchOne('t1')).thenAnswer((_) => one.stream);
    container = ProviderContainer(
      overrides: [transactionsRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() async {
    container.dispose();
    await one.close();
  });

  TransactionDetailState state() =>
      container.read(transactionDetailControllerProvider('t1'));

  void start() =>
      container.listen(transactionDetailControllerProvider('t1'), (_, _) {});

  test('arranca cargando la transacción y las fuentes', () {
    final pending = Completer<List<TxSource>?>();
    when(() => repository.fetchSources('t1')).thenAnswer((_) => pending.future);

    start();

    expect(state().tx, isA<AsyncLoading<Object?>>());
    expect(state().sources, const SourcesState.loading());
  });

  test('sigue la transacción del repositorio (también si se borra)', () async {
    when(() => repository.fetchSources('t1')).thenAnswer((_) async => []);
    start();

    one.add(_view);
    await pumpEventQueue();
    expect(state().tx.value, _view);

    one.add(null);
    await pumpEventQueue();
    expect(state().tx, const AsyncData<TransactionView?>(null));
  });

  test('un error del stream queda en tx', () async {
    when(() => repository.fetchSources('t1')).thenAnswer((_) async => []);
    start();

    one.addError(StateError('db'));
    await pumpEventQueue();

    expect(state().tx, isA<AsyncError<Object?>>());
  });

  test('sin red las fuentes quedan offline', () async {
    when(() => repository.fetchSources('t1')).thenAnswer((_) async => null);

    start();
    await pumpEventQueue();

    expect(state().sources, const SourcesState.offline());
  });

  test('con red las fuentes quedan cargadas', () async {
    final sources = [(channel: TxChannel.email, receivedAt: _at)];
    when(
      () => repository.fetchSources('t1'),
    ).thenAnswer((_) async => sources);

    start();
    await pumpEventQueue();

    expect(state().sources, SourcesState.loaded(sources));
  });

  test('refreshSources reintenta tras quedar offline', () async {
    when(() => repository.fetchSources('t1')).thenAnswer((_) async => null);
    start();
    await pumpEventQueue();

    final sources = [(channel: TxChannel.nfc, receivedAt: _at)];
    when(
      () => repository.fetchSources('t1'),
    ).thenAnswer((_) async => sources);
    final refresh = container
        .read(transactionDetailControllerProvider('t1').notifier)
        .refreshSources();
    expect(state().sources, const SourcesState.loading());
    await refresh;

    expect(state().sources, SourcesState.loaded(sources));
  });

  test('liberar el detalle antes de pedir las fuentes no falla', () async {
    when(() => repository.fetchSources('t1')).thenAnswer((_) async => []);
    final disposable = ProviderContainer(
      overrides: [transactionsRepositoryProvider.overrideWithValue(repository)],
    );
    final controller = disposable.read(
      transactionDetailControllerProvider('t1').notifier,
    );

    // Se libera antes de que corra la microtarea de build().
    disposable.dispose();
    await pumpEventQueue();

    verifyNever(() => repository.fetchSources('t1'));
    await expectLater(controller.refreshSources(), completes);
    verifyNever(() => repository.fetchSources('t1'));
  });
}
