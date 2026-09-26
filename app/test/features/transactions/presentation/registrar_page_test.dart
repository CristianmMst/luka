import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/app_theme.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/application/transaction_actions.dart';
import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/domain/category_option.dart';
import 'package:finanzia/features/transactions/domain/manual_draft.dart';
import 'package:finanzia/features/transactions/domain/transactions_repository.dart';
import 'package:finanzia/features/transactions/presentation/registrar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _Actions extends Mock implements TransactionActions {}

class _Transactions extends Mock implements TransactionsRepository {}

class _Coordinator extends SyncCoordinator {
  _Coordinator({required this.offline});

  final bool offline;

  @override
  SyncStatus build() => SyncStatus(offline: offline);
}

/// 3:42 p. m. en Bogotá.
final _now = DateTime.utc(2026, 9, 25, 20, 42);

void main() {
  late _Actions actions;
  late _Transactions transactions;

  setUpAll(() => registerFallbackValue(ManualDraft(occurredAt: _now)));

  setUp(() {
    actions = _Actions();
    transactions = _Transactions();
    when(() => actions.create(any())).thenAnswer((_) async => 'local-1');
    when(() => actions.delete(any())).thenAnswer((_) async {});
    when(() => transactions.watchCategories()).thenAnswer(
      (_) => Stream.value(const [
        CategoryOption(
          id: 'c-mer',
          name: 'Mercado',
          isSystem: true,
          slug: 'mercado',
        ),
      ]),
    );
  });

  Future<void> pumpRegistrar(
    WidgetTester tester, {
    bool offline = false,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 1200) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const RegistrarPage()),
        GoRoute(
          path: '/movimientos/:id',
          builder: (_, state) =>
              Scaffold(body: Text('detalle ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionActionsProvider.overrideWithValue(actions),
          transactionsRepositoryProvider.overrideWithValue(transactions),
          transactionsClockProvider.overrideWithValue(() => _now),
          syncCoordinatorProvider.overrideWith(
            () => _Coordinator(offline: offline),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('es', 'CO'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin monto avisa y no guarda', (tester) async {
    await pumpRegistrar(tester);

    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();

    expect(find.text(r'Escribe un monto mayor a $0.'), findsOneWidget);
    verifyNever(() => actions.create(any()));
  });

  testWidgets('guarda un gasto de ahora, avisa y limpia el formulario', (
    tester,
  ) async {
    await pumpRegistrar(tester);

    await tester.enterText(find.byType(TextField).at(0), '12500');
    await tester.enterText(find.byType(TextField).at(1), ' Panadería ');
    await tester.enterText(find.byType(TextField).at(2), 'con Ana');
    await tester.tap(find.text('Sin categoría'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mercado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();

    final draft =
        verify(() => actions.create(captureAny())).captured.single
            as ManualDraft;
    expect(draft.amount, Cop.pesos(12500));
    expect(draft.direction, TxDirection.debit);
    expect(draft.occurredAt, _now);
    expect(draft.categoryId, 'c-mer');
    expect(draft.toNewTransaction().merchant, 'Panadería');
    expect(draft.toNewTransaction().notes, 'con Ana');

    expect(find.text('Movimiento guardado'), findsOneWidget);
    expect(find.text('Sin categoría'), findsOneWidget);
    final amount = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(amount.controller!.text, isEmpty);
  });

  testWidgets('un ingreso se guarda como crédito', (tester) async {
    await pumpRegistrar(tester);

    await tester.enterText(find.byType(TextField).at(0), '2000000');
    await tester.tap(find.text('Ingreso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();

    final draft =
        verify(() => actions.create(captureAny())).captured.single
            as ManualDraft;
    expect(draft.direction, TxDirection.credit);
  });

  testWidgets('"Deshacer" elimina lo recién guardado', (tester) async {
    await pumpRegistrar(tester);

    await tester.enterText(find.byType(TextField).at(0), '5000');
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();

    verify(() => actions.delete('local-1')).called(1);
    expect(find.text('Movimiento deshecho'), findsOneWidget);
  });

  testWidgets('sin conexión lo dice y guarda igual', (tester) async {
    await pumpRegistrar(tester, offline: true);

    expect(
      find.text('Sin conexión. Lo que registres se envía al volver.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).at(0), '5000');
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();

    expect(
      find.text('Movimiento guardado. Se enviará cuando haya conexión.'),
      findsOneWidget,
    );
  });

  testWidgets('si no se pudo encolar, avisa y conserva el formulario', (
    tester,
  ) async {
    when(() => actions.create(any())).thenThrow(StateError('db'));
    await pumpRegistrar(tester);

    await tester.enterText(find.byType(TextField).at(0), '5000');
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos guardar el movimiento. Intenta de nuevo.'),
      findsOneWidget,
    );
    final amount = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(amount.controller!.text, isNotEmpty);
  });
}
