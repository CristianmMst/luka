import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/application/transactions_list_controller.dart';
import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/domain/transaction_filter.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:finanzia/features/transactions/domain/transactions_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements TransactionsRepository {}

TransactionView _tx(String id, DateTime occurredAt) => TransactionView(
  id: id,
  amount: Cop.pesos(1000),
  direction: TxDirection.debit,
  kind: TxKind.expense,
  occurredAt: occurredAt,
  channels: const {},
  sync: SyncMark.none,
);

void main() {
  // 2026-09-23 12:00 en Bogota.
  final now = DateTime.utc(2026, 9, 23, 17);
  late _Repository repository;
  late StreamController<List<TransactionView>> rows;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(const TransactionFilter()));

  setUp(() {
    repository = _Repository();
    rows = StreamController<List<TransactionView>>.broadcast();
    when(
      () => repository.watch(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) => rows.stream);
    container = ProviderContainer(
      overrides: [
        transactionsRepositoryProvider.overrideWithValue(repository),
        transactionsClockProvider.overrideWithValue(() => now),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await rows.close();
  });

  TransactionsListController controller() =>
      container.read(transactionsListControllerProvider.notifier);
  TransactionsListState state() =>
      container.read(transactionsListControllerProvider);

  void start() =>
      container.listen(transactionsListControllerProvider, (_, _) {});

  test('arranca con el mes en curso, 50 filas y cargando', () {
    start();

    expect(state().filter, const TransactionFilter());
    expect(state().limit, 50);
    expect(state().groups, isA<AsyncLoading<Object?>>());
    verify(
      () => repository.watch(const TransactionFilter(), limit: 50),
    ).called(1);
  });

  test('agrupa lo que emite el repositorio por día', () async {
    start();

    rows.add([_tx('a', now), _tx('b', now.subtract(const Duration(days: 1)))]);
    await pumpEventQueue();

    final groups = state().groups.requireValue;
    expect(groups, hasLength(2));
    expect(groups.first.items.single.id, 'a');
    expect(state().hasMore, isFalse);
  });

  test('hasMore cuando llegan tantas filas como el límite', () async {
    start();

    rows.add([for (var i = 0; i < 50; i++) _tx('t$i', now)]);
    await pumpEventQueue();

    expect(state().hasMore, isTrue);
  });

  test('un error del stream queda en groups', () async {
    start();

    rows.addError(StateError('db'));
    await pumpEventQueue();

    expect(state().groups, isA<AsyncError<Object?>>());
  });

  test('setFilter vuelve a consultar con el filtro y reinicia el límite', () {
    start();
    controller().loadMore();

    const filter = TransactionFilter(
      period: PeriodPreset.lastMonth,
      kinds: {TxKind.income},
    );
    controller().setFilter(filter);

    expect(state().filter, filter);
    expect(state().limit, 50);
    verify(() => repository.watch(filter, limit: 50)).called(1);
  });

  test('loadMore sube el límite de 50 en 50 con el mismo filtro', () {
    start();

    controller()
      ..loadMore()
      ..loadMore();

    expect(state().limit, 150);
    verifyInOrder([
      () => repository.watch(const TransactionFilter(), limit: 50),
      () => repository.watch(const TransactionFilter(), limit: 100),
      () => repository.watch(const TransactionFilter(), limit: 150),
    ]);
  });

  test('loadMore conserva los grupos mientras llega la página', () async {
    start();
    rows.add([_tx('a', now)]);
    await pumpEventQueue();

    controller().loadMore();

    expect(state().groups.requireValue.single.items.single.id, 'a');
  });

  test('setText espera 250 ms sin teclear antes de filtrar', () {
    fakeAsync((async) {
      start();
      clearInteractions(repository);

      controller().setText('ex');
      async.elapse(const Duration(milliseconds: 200));
      controller().setText('exito');
      async.elapse(const Duration(milliseconds: 249));
      verifyNever(() => repository.watch(any(), limit: any(named: 'limit')));

      async.elapse(const Duration(milliseconds: 1));
      verify(
        () => repository.watch(
          const TransactionFilter(text: 'exito'),
          limit: 50,
        ),
      ).called(1);
      verifyNoMoreInteractions(repository);
      expect(state().filter.text, 'exito');
    });
  });

  test('clearFilters vuelve al filtro por defecto y cancela el texto', () {
    fakeAsync((async) {
      start();
      controller()
        ..setFilter(const TransactionFilter(kinds: {TxKind.transfer}))
        ..setText('nequi')
        ..clearFilters();
      async.elapse(const Duration(seconds: 1));

      expect(state().filter, const TransactionFilter());
      verify(
        () => repository.watch(const TransactionFilter(), limit: 50),
      ).called(2);
      verifyNever(
        () => repository.watch(
          any(
            that: isA<TransactionFilter>().having(
              (f) => f.text,
              'text',
              'nequi',
            ),
          ),
          limit: any(named: 'limit'),
        ),
      );
    });
  });
}
