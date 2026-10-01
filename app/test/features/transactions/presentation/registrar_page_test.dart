import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/app_theme.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/application/transaction_actions.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/domain/manual_draft.dart';
import 'package:luka/features/transactions/domain/transactions_repository.dart';
import 'package:luka/features/transactions/presentation/registrar_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _Actions extends Mock implements TransactionActions {}

class _Accounts extends Mock implements AccountsStore {}

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
  late _Accounts accounts;

  setUpAll(() => registerFallbackValue(ManualDraft(occurredAt: _now)));

  setUp(() {
    actions = _Actions();
    transactions = _Transactions();
    accounts = _Accounts();
    when(() => accounts.watchAll()).thenAnswer(
      (_) => Stream.value(const [
        LinkedAccount(
          id: 'a-1',
          bank: 'bancolombia',
          kind: 'savings',
          last4: '8761',
          alias: 'Nómina',
          transactionCount: 0,
        ),
      ]),
    );
    when(() => actions.create(any())).thenAnswer((_) async => 'local-1');
    when(() => actions.delete(any())).thenAnswer((_) async {});
    when(() => transactions.watchCategories()).thenAnswer(
      (_) => Stream.value(const [
        CategoryOption(
          id: 'c-mer',
          name: 'Mercado',
          isSystem: true,
          slug: 'mercado',
          fiscalTag: 'no_deducible',
        ),
        CategoryOption(
          id: 'c-sal',
          name: 'Salud y farmacia',
          isSystem: true,
          slug: 'salud',
          fiscalTag: 'no_deducible',
        ),
        CategoryOption(
          id: 'c-nom',
          name: 'Nómina y salario',
          isSystem: true,
          slug: 'nomina',
          fiscalTag: 'ingreso_laboral',
        ),
      ]),
    );
  });

  Future<void> pumpRegistrar(
    WidgetTester tester, {
    bool offline = false,
    ThemeMode themeMode = ThemeMode.light,
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
          accountsStoreProvider.overrideWithValue(accounts),
          transactionsClockProvider.overrideWithValue(() => _now),
          syncCoordinatorProvider.overrideWith(
            () => _Coordinator(offline: offline),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: const Locale('es', 'CO'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el tipo cambia la pregunta y el signo del monto', (
    tester,
  ) async {
    await pumpRegistrar(tester);
    expect(find.text('¿Cuánto gastaste?'), findsOneWidget);
    expect(find.text(r'−$'), findsOneWidget);

    await tester.tap(find.text('Ingreso'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cuánto recibiste?'), findsOneWidget);
    expect(find.text(r'+$'), findsOneWidget);
    expect(find.text('Guardar movimiento'), findsOneWidget);
  });

  testWidgets('la hoja solo ofrece las categorías del tipo y busca', (
    tester,
  ) async {
    await pumpRegistrar(tester);
    await tester.tap(find.text('Sin categoría'));
    await tester.pumpAndSettle();

    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Salud y farmacia'), findsOneWidget);
    expect(find.text('Nómina y salario'), findsNothing);

    final search = find.widgetWithText(TextField, 'Buscar categoría');
    await tester.enterText(search, 'SALUD');
    await tester.pump();
    expect(find.text('Mercado'), findsNothing);
    expect(find.text('Salud y farmacia'), findsOneWidget);

    await tester.enterText(search, 'xyz');
    await tester.pump();
    expect(find.text('Ninguna categoría con «xyz».'), findsOneWidget);
  });

  testWidgets('pasar a ingreso suelta una categoría de gasto', (tester) async {
    await pumpRegistrar(tester);
    await tester.tap(find.text('Sin categoría'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mercado'));
    await tester.pumpAndSettle();
    expect(find.text('Mercado'), findsOneWidget);

    await tester.tap(find.text('Ingreso'));
    await tester.pumpAndSettle();

    expect(find.text('Mercado'), findsNothing);
    expect(find.text('Sin categoría'), findsOneWidget);
  });

  testWidgets('al guardar aterriza "Quedó registrado" y se va solo', (
    tester,
  ) async {
    await pumpRegistrar(tester);
    await tester.enterText(find.byType(TextField).at(0), '38450');
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Quedó registrado'), findsOneWidget);
    expect(find.text(r'−$38.450'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Quedó registrado'), findsNothing);
  });

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

  testWidgets('la cuenta elegida viaja en el borrador', (tester) async {
    await pumpRegistrar(tester);

    await tester.enterText(find.byType(TextField).at(0), '45900');
    await tester.tap(find.text('Sin cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('¿De qué cuenta?'), findsOneWidget);
    await tester.tap(find.text('Nómina'));
    await tester.pumpAndSettle();
    expect(find.text('Nómina'), findsOneWidget);
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();

    final draft =
        verify(() => actions.create(captureAny())).captured.single
            as ManualDraft;
    expect(draft.accountId, 'a-1');
    // El formulario queda limpio, también la cuenta.
    expect(find.text('Sin cuenta'), findsOneWidget);
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

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('hoja de categorias ${mode.name}', tags: ['golden'], (
        tester,
      ) async {
        await pumpRegistrar(tester, themeMode: mode);
        await tester.tap(find.text('Sin categoría'));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/category_sheet_${mode.name}.png'),
        );
      });

      testWidgets('registrar ${mode.name}', tags: ['golden'], (tester) async {
        await pumpRegistrar(tester, themeMode: mode);
        await expectLater(
          find.byType(RegistrarPage),
          matchesGoldenFile('goldens/registrar_${mode.name}.png'),
        );
      });
    }
  });
}
