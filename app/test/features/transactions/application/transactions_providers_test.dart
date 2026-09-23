import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/domain/category_option.dart';
import 'package:finanzia/features/transactions/domain/transaction_filter.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:finanzia/features/transactions/domain/transactions_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements TransactionsRepository {}

TransactionView _tx(String id) => TransactionView(
  id: id,
  amount: Cop.pesos(1000),
  direction: TxDirection.debit,
  kind: TxKind.expense,
  occurredAt: DateTime.utc(2026, 9, 23, 17),
  channels: const {},
  sync: SyncMark.none,
);

void main() {
  late _Repository repository;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(const TransactionFilter()));

  setUp(() {
    repository = _Repository();
    container = ProviderContainer(
      overrides: [transactionsRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('las categorías salen del repositorio', () async {
    const mercado = CategoryOption(
      id: 'c1',
      name: 'Mercado',
      isSystem: true,
      slug: 'mercado',
    );
    when(
      () => repository.watchCategories(),
    ).thenAnswer((_) => Stream.value(const [mercado]));

    container.listen(transactionCategoriesProvider, (_, _) {});
    final categories = await container.read(
      transactionCategoriesProvider.future,
    );

    expect(categories, const [mercado]);
  });

  test('el conteo del filtro pide hasta el tope y cuenta las filas', () async {
    const filter = TransactionFilter(kinds: {TxKind.expense});
    when(
      () => repository.watch(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) => Stream.value([_tx('a'), _tx('b')]));

    container.listen(filteredCountProvider(filter), (_, _) {});
    final count = await container.read(
      filteredCountProvider(filter).future,
    );

    expect(count, 2);
    verify(
      () => repository.watch(filter, limit: filteredCountCap),
    ).called(1);
  });

  test('la otra parte de una transferencia sale del repositorio', () async {
    final pair = _tx('pair');
    when(
      () => repository.watchOne('pair'),
    ).thenAnswer((_) => Stream.value(pair));

    container.listen(transactionByIdProvider('pair'), (_, _) {});

    expect(await container.read(transactionByIdProvider('pair').future), pair);
  });
}
