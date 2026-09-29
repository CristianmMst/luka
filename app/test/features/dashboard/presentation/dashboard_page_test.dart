import 'dart:async';

import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/app_theme.dart';
import 'package:finanzia/core/time/colombia_month.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/dashboard/application/dashboard_providers.dart';
import 'package:finanzia/features/dashboard/domain/insights_repository.dart';
import 'package:finanzia/features/dashboard/domain/monthly_summary.dart';
import 'package:finanzia/features/dashboard/presentation/dashboard_page.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/application/sync_engine.dart';
import 'package:finanzia/features/transactions/application/transactions_list_controller.dart';
import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/domain/category_option.dart';
import 'package:finanzia/features/transactions/domain/transaction_filter.dart';
import 'package:finanzia/features/transactions/domain/transactions_repository.dart';
import 'package:finanzia/features/transactions/presentation/transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/capture_health.dart';
import '../../../helpers/pump_app.dart';

class _Insights extends Mock implements InsightsRepository {}

class _Transactions extends Mock implements TransactionsRepository {}

class _Auth extends AuthController {
  @override
  Future<AuthState> build() async => const Authenticated(_ana);
}

class _FixedCoordinator extends SyncCoordinator {
  _FixedCoordinator(this._status);

  final SyncStatus _status;
  int syncs = 0;

  @override
  SyncStatus build() => _status;

  @override
  Future<SyncRunResult> sync() async {
    syncs++;
    return SyncRunResult.synced;
  }
}

const _ana = User(
  id: 'u-1',
  email: 'ana@example.com',
  displayName: 'Ana Gómez',
  status: UserStatus.active,
);

/// 2026-09-23 12:00 en Bogotá.
final _now = DateTime.utc(2026, 9, 23, 17);
final _september = ColombiaMonth(2026, 9);
final _august = ColombiaMonth(2026, 8);
final _synced = SyncStatus(lastSyncedAt: DateTime.utc(2026, 9, 23, 16));

CategorySpend _spend(String slug, String name, int pesos) => CategorySpend(
  categoryId: slug,
  slug: slug,
  name: name,
  amount: Cop.pesos(pesos),
);

/// El mes del diseño A: gasto −9 % vs agosto, ingreso igual.
MonthlySummary _full(ColombiaMonth month) => MonthlySummary(
  month: month,
  totals: MonthlyTotals(
    expenses: Cop.pesos(1284600),
    income: Cop.pesos(3503000),
  ),
  previousTotals: MonthlyTotals(
    expenses: Cop.pesos(1411600),
    income: Cop.pesos(3503000),
  ),
  topCategories: [
    _spend('mercado', 'Mercado', 412300),
    _spend('restaurantes', 'Restaurantes', 236800),
    _spend('transporte', 'Transporte', 184500),
    _spend('domicilios', 'Domicilios', 152900),
    _spend('salud', 'Salud', 98200),
  ],
  otherAmount: Cop.pesos(199900),
);

MonthlySummary _empty(ColombiaMonth month) => MonthlySummary(
  month: month,
  totals: const MonthlyTotals(),
  previousTotals: const MonthlyTotals(),
  topCategories: const [],
  otherAmount: const Cop(0),
);

void main() {
  late _Insights insights;
  late _Transactions transactions;
  late MonthlySummary Function(ColombiaMonth month) summaryFor;

  setUpAll(() {
    registerFallbackValue(ColombiaMonth(2000, 1));
    registerFallbackValue(const TransactionFilter());
  });

  setUp(() {
    insights = _Insights();
    transactions = _Transactions();
    summaryFor = _full;
    when(() => insights.watchMonth(any())).thenAnswer(
      (i) => Stream.value(
        summaryFor(i.positionalArguments.single as ColombiaMonth),
      ),
    );
    when(
      () => transactions.watch(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) => Stream.value(const []));
  });

  List<Override> overrides(SyncStatus status) => [
    captureHealthOk(),
    insightsRepositoryProvider.overrideWithValue(insights),
    dashboardClockProvider.overrideWithValue(() => _now),
    authControllerProvider.overrideWith(_Auth.new),
    syncCoordinatorProvider.overrideWith(() => _FixedCoordinator(status)),
    transactionsRepositoryProvider.overrideWithValue(transactions),
    transactionsClockProvider.overrideWithValue(() => _now),
  ];

  Future<void> pumpPage(
    WidgetTester tester, {
    SyncStatus? status,
    ThemeMode themeMode = ThemeMode.light,
    bool settle = true,
  }) async {
    await tester.pumpApp(
      const DashboardPage(),
      overrides: overrides(status ?? _synced),
      themeMode: themeMode,
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }
  }

  IconButton iconButton(WidgetTester tester, String tooltip) =>
      tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );

  testWidgets('deslizar hacia abajo sincroniza', (tester) async {
    await pumpPage(tester);
    final coordinator =
        ProviderScope.containerOf(
              tester.element(find.byType(DashboardPage)),
            ).read(syncCoordinatorProvider.notifier)
            as _FixedCoordinator;

    await tester.fling(
      find.text('Balance del mes'),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(coordinator.syncs, 1);
  });

  testWidgets('pinta el balance, las tarjetas y el top del mes', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Sincronizado · al día'), findsOneWidget);
    expect(find.text('Septiembre 2026'), findsOneWidget);
    expect(find.text('Balance del mes'), findsOneWidget);
    expect(find.text(r'+$2.218.400'), findsOneWidget);
    expect(find.text(r'−$1.284.600'), findsOneWidget);
    expect(find.text(r'+$3.503.000'), findsOneWidget);
    expect(find.text('↓ 9 % vs agosto'), findsOneWidget);
    expect(find.text('= igual que agosto'), findsOneWidget);
    expect(find.text('En qué se fue'), findsOneWidget);
    for (final name in [
      'Mercado',
      'Restaurantes',
      'Transporte',
      'Domicilios',
      'Salud',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text(r'$412.300'), findsOneWidget);
    expect(find.text('32 %'), findsOneWidget);
    expect(find.text('8 %'), findsOneWidget);
    expect(find.text('Otras categorías'), findsOneWidget);
    expect(find.text(r'$199.900 · 16 %'), findsOneWidget);
    expect(find.text('Sin conexión — datos locales'), findsNothing);
  });

  testWidgets('las filas y las cifras se anuncian con su resumen', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPage(tester);

    expect(
      find.bySemanticsLabel(r'Mercado, 32 % del gasto, $412.300'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(r'Otras categorías, 16 % del gasto, $199.900'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Balance del mes: más 2.218.400 pesos'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Gastos: 1.284.600 pesos. 9 % menos que agosto',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Ingresos: 3.503.000 pesos. Igual que agosto'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('en el mes en curso "Mes siguiente" está deshabilitado', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(iconButton(tester, 'Mes siguiente').onPressed, isNull);
    expect(iconButton(tester, 'Mes anterior').onPressed, isNotNull);
  });

  testWidgets('"Mes anterior" muestra agosto y habilita el siguiente', (
    tester,
  ) async {
    summaryFor = (month) => month == _september
        ? _full(month)
        : MonthlySummary(
            month: month,
            totals: MonthlyTotals(
              expenses: Cop.pesos(1411600),
              income: Cop.pesos(1000000),
            ),
            previousTotals: MonthlyTotals(income: Cop.pesos(500000)),
            topCategories: [_spend('mercado', 'Mercado', 1411600)],
            otherAmount: const Cop(0),
          );
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();

    verify(() => insights.watchMonth(_august)).called(1);
    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.text(r'−$411.600'), findsOneWidget);
    expect(find.text('Sin datos de julio'), findsOneWidget);
    expect(find.text('↑ 100 % vs julio'), findsOneWidget);
    expect(find.text('100 %'), findsOneWidget);
    expect(find.text('Otras categorías'), findsNothing);
    expect(iconButton(tester, 'Mes siguiente').onPressed, isNotNull);

    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Septiembre 2026'), findsOneWidget);
    expect(iconButton(tester, 'Mes siguiente').onPressed, isNull);
  });

  testWidgets('balance negativo y categoría sin nombre', (tester) async {
    summaryFor = (month) => MonthlySummary(
      month: month,
      totals: MonthlyTotals(expenses: Cop.pesos(50000)),
      previousTotals: const MonthlyTotals(),
      topCategories: [
        CategorySpend(categoryId: null, amount: Cop.pesos(50000)),
      ],
      otherAmount: const Cop(0),
    );
    await pumpPage(tester);

    expect(find.text(r'−$50.000'), findsNWidgets(2));
    expect(find.text('Sin categoría'), findsOneWidget);
    expect(find.text('Sin datos de agosto'), findsNWidgets(2));
  });

  testWidgets('un mes solo con ingresos dice que no hubo gastos', (
    tester,
  ) async {
    summaryFor = (month) => MonthlySummary(
      month: month,
      totals: MonthlyTotals(income: Cop.pesos(3500000)),
      previousTotals: MonthlyTotals(income: Cop.pesos(3500000)),
      topCategories: const [],
      otherAmount: const Cop(0),
    );
    await pumpPage(tester);

    expect(find.text(r'+$3.500.000'), findsNWidgets(2));
    expect(find.text('Sin gastos en septiembre.'), findsOneWidget);
  });

  testWidgets('mes vacío: "Sin movimientos" y volver al mes en curso', (
    tester,
  ) async {
    summaryFor = _empty;
    await pumpPage(tester);

    expect(find.text('Sin movimientos en septiembre'), findsOneWidget);
    expect(find.text('Balance del mes'), findsNothing);
    expect(find.text('Volver a septiembre'), findsNothing);

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Sin movimientos en julio'), findsOneWidget);

    await tester.tap(find.text('Volver a septiembre'));
    await tester.pumpAndSettle();
    expect(find.text('Septiembre 2026'), findsOneWidget);
    expect(find.text('Sin movimientos en septiembre'), findsOneWidget);
  });

  testWidgets('primera sincronización: "Trayendo tus movimientos"', (
    tester,
  ) async {
    summaryFor = _empty;
    await pumpPage(
      tester,
      status: const SyncStatus(running: true),
      settle: false,
    );

    expect(find.text('Trayendo tus movimientos'), findsOneWidget);
    expect(find.text('Sincronizando…'), findsOneWidget);
    expect(find.text('Sin movimientos en septiembre'), findsNothing);
  });

  testWidgets('con datos, la primera sincronización no tapa el resumen', (
    tester,
  ) async {
    await pumpPage(
      tester,
      status: const SyncStatus(running: true),
      settle: false,
    );

    expect(find.text('En qué se fue'), findsOneWidget);
    expect(find.text('Trayendo tus movimientos'), findsNothing);
  });

  testWidgets('mientras carga muestra el esqueleto', (tester) async {
    when(
      () => insights.watchMonth(any()),
    ).thenAnswer((_) => const Stream.empty());
    await pumpPage(tester);

    expect(find.text('Septiembre 2026'), findsOneWidget);
    expect(find.text('Balance del mes'), findsNothing);
    expect(find.text('Sin movimientos en septiembre'), findsNothing);
  });

  testWidgets('sin conexión: banner y las cifras locales', (tester) async {
    await pumpPage(
      tester,
      status: _synced.copyWith(offline: true),
    );

    expect(find.text('Sin conexión — datos locales'), findsOneWidget);
    expect(
      find.text('Sin conexión · los cambios se enviarán al volver'),
      findsOneWidget,
    );
    expect(find.text(r'+$2.218.400'), findsOneWidget);
  });

  testWidgets('error local: reintentar vuelve a leer el mes', (tester) async {
    var failing = true;
    when(() => insights.watchMonth(any())).thenAnswer(
      (_) => failing
          ? Stream.error(StateError('db'))
          : Stream.value(_full(_september)),
    );
    await pumpPage(tester);

    expect(
      find.text('No pudimos leer el resumen guardado en el teléfono.'),
      findsOneWidget,
    );
    failing = false;
    clearInteractions(insights);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    verify(() => insights.watchMonth(_september)).called(1);
    expect(find.text('En qué se fue'), findsOneWidget);
  });

  testWidgets('tocar una categoría abre Movimientos con ese mes y categoría', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: overrides(_synced));
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
        GoRoute(
          path: '/movimientos',
          builder: (_, _) => const Text('movimientos'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
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
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restaurantes'));
    await tester.pumpAndSettle();

    expect(find.text('movimientos'), findsOneWidget);
    final range = _august.range();
    expect(
      container.read(transactionsListControllerProvider).filter,
      TransactionFilter(
        period: PeriodPreset.custom,
        from: range.from,
        to: range.to,
        categoryId: 'restaurantes',
      ),
    );
  });

  testWidgets('mientras llega el mes nuevo las categorías no se abren', (
    tester,
  ) async {
    final august = StreamController<MonthlySummary>();
    addTearDown(august.close);
    when(() => insights.watchMonth(_august)).thenAnswer((_) => august.stream);
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pump();
    expect(find.text('Agosto 2026'), findsOneWidget);
    // Las cifras siguen siendo las de septiembre, con su comparación.
    expect(find.text('Restaurantes'), findsOneWidget);
    expect(find.textContaining('agosto'), findsWidgets);
    expect(find.textContaining('julio'), findsNothing);

    await tester.tap(find.text('Restaurantes'));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DashboardPage)),
    );
    expect(
      container.read(transactionsListControllerProvider).filter,
      const TransactionFilter(),
    );
  });

  testWidgets('tocar "Sin categoría" abre Movimientos con ese filtro legible', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    summaryFor = (month) => MonthlySummary(
      month: month,
      totals: MonthlyTotals(expenses: Cop.pesos(60000)),
      previousTotals: const MonthlyTotals(),
      topCategories: [
        _spend('mercado', 'Mercado', 40000),
        const CategorySpend(
          categoryId: 'cat-sin',
          slug: uncategorizedSlug,
          name: 'Sin categoría',
          amount: Cop(2000000),
        ),
      ],
      otherAmount: const Cop(0),
    );
    // La lista de categorías de Movimientos no trae `sin_categoria`.
    when(() => transactions.watchCategories()).thenAnswer(
      (_) => Stream.value(const [
        CategoryOption(
          id: 'mercado',
          name: 'Mercado',
          isSystem: true,
          slug: 'mercado',
        ),
      ]),
    );
    final container = ProviderContainer(overrides: overrides(_synced));
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
        GoRoute(
          path: '/movimientos',
          builder: (_, _) => const TransactionsPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
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

    await tester.tap(find.text('Sin categoría'));
    await tester.pumpAndSettle();

    final range = _september.range();
    expect(
      container.read(transactionsListControllerProvider).filter,
      TransactionFilter(
        period: PeriodPreset.custom,
        from: range.from,
        to: range.to,
        categoryId: 'cat-sin',
      ),
    );
    expect(find.byType(TransactionsPage), findsOneWidget);
    expect(find.textContaining('· Sin categoría'), findsOneWidget);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('áreas táctiles y contraste (${mode.name})', (tester) async {
      await pumpPage(tester, themeMode: mode);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }

  testWidgets('estados vacío y sin conexión cumplen contraste', (
    tester,
  ) async {
    summaryFor = _empty;
    await pumpPage(tester, status: _synced.copyWith(offline: true));
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('inicio ${mode.name}', tags: ['golden'], (tester) async {
        await pumpPage(tester, themeMode: mode);
        await expectLater(
          find.byType(DashboardPage),
          matchesGoldenFile('goldens/dashboard_${mode.name}.png'),
        );
      });
    }
  });
}
