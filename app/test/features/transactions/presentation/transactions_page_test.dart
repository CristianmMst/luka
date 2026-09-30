import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/app_theme.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/application/transaction_actions.dart';
import 'package:luka/features/transactions/application/transactions_list_controller.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/domain/transaction_filter.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';
import 'package:luka/features/transactions/domain/transactions_repository.dart';
import 'package:luka/features/transactions/presentation/transactions_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _Repository extends Mock implements TransactionsRepository {}

class _Actions extends Mock implements TransactionActions {}

class _FixedCoordinator extends SyncCoordinator {
  _FixedCoordinator(this._status);

  final SyncStatus _status;

  @override
  SyncStatus build() => _status;
}

/// 2026-09-23 18:00 en Bogotá.
final _now = DateTime.utc(2026, 9, 23, 23);

/// Hora de Bogotá del día [day] de septiembre de 2026, como instante UTC.
DateTime _at(int day, int hour, int minute) =>
    DateTime.utc(2026, 9, day, hour + 5, minute);

const _categories = [
  CategoryOption(
    id: 'mercado',
    name: 'Mercado y supermercado',
    isSystem: true,
    slug: 'mercado',
  ),
  CategoryOption(
    id: 'restaurantes',
    name: 'Restaurantes y domicilios',
    isSystem: true,
    slug: 'restaurantes',
  ),
  CategoryOption(
    id: 'salud',
    name: 'Salud y farmacia',
    isSystem: true,
    slug: 'salud',
  ),
  CategoryOption(id: 'mascotas', name: 'Mascotas', isSystem: false),
];

TransactionView _tx(
  String id, {
  required String? merchant,
  required int pesos,
  required DateTime at,
  TxKind kind = TxKind.expense,
  Set<TxChannel> channels = const {TxChannel.notification},
  String? categoryId = 'mercado',
  String? categoryName = 'Mercado y supermercado',
  String? categorySlug = 'mercado',
  SyncMark sync = SyncMark.none,
}) => TransactionView(
  id: id,
  amount: Cop.pesos(pesos),
  direction: kind == TxKind.income ? TxDirection.credit : TxDirection.debit,
  kind: kind,
  occurredAt: at,
  channels: channels,
  sync: sync,
  merchant: merchant,
  categoryId: categoryId,
  categoryName: categoryName,
  categorySlug: categorySlug,
);

final TransactionView _exito = _tx(
  'exito',
  merchant: 'Éxito Calle 80',
  pesos: 126400,
  at: _at(23, 12, 41),
  channels: const {TxChannel.notification, TxChannel.email},
);

List<TransactionView> _sample() => [
  _exito,
  _tx(
    'rappi',
    merchant: 'Rappi',
    pesos: 38900,
    at: _at(23, 10, 15),
    channels: const {TxChannel.email},
    categoryId: 'restaurantes',
    categoryName: 'Restaurantes y domicilios',
    categorySlug: 'restaurantes',
    sync: SyncMark.pending,
  ),
  _tx(
    'nequi',
    merchant: 'A tu cuenta Nequi',
    pesos: 50000,
    at: _at(23, 9, 2),
    kind: TxKind.transfer,
    categoryId: 'transferencias',
    categoryName: 'Transferencias entre cuentas propias',
    categorySlug: 'transferencias',
  ),
  _tx(
    'tostao',
    merchant: 'Tostao’ Café',
    pesos: 19000,
    at: _at(23, 8, 10),
    channels: const {TxChannel.manual},
    categoryId: 'restaurantes',
    categoryName: 'Restaurantes y domicilios',
    categorySlug: 'restaurantes',
  ),
  _tx(
    'nomina',
    merchant: 'Pago de nómina',
    pesos: 3500000,
    at: _at(22, 18, 30),
    kind: TxKind.income,
    channels: const {TxChannel.email},
    categoryId: 'nomina',
    categoryName: 'Nómina y salario',
    categorySlug: 'nomina',
  ),
  _tx(
    'cruz-verde',
    merchant: 'Droguería Cruz Verde',
    pesos: 58200,
    at: _at(22, 17, 5),
    categoryId: 'salud',
    categoryName: 'Salud y farmacia',
    categorySlug: 'salud',
  ),
  _tx(
    'd1',
    merchant: 'D1 Chapinero',
    pesos: 42700,
    at: _at(22, 13, 20),
    channels: const {TxChannel.notification, TxChannel.email},
  ),
];

void main() {
  late _Repository repository;
  late _Actions actions;
  late List<TransactionView> Function(TransactionFilter filter) rows;

  setUpAll(() => registerFallbackValue(const TransactionFilter()));

  setUp(() {
    repository = _Repository();
    actions = _Actions();
    rows = (_) => _sample();
    when(() => repository.watch(any(), limit: any(named: 'limit'))).thenAnswer(
      (invocation) => Stream.value(
        rows(invocation.positionalArguments.first as TransactionFilter),
      ),
    );
    when(
      () => repository.watchCategories(),
    ).thenAnswer((_) => Stream.value(_categories));
    when(
      () => actions.changeCategory(any(), any(), always: any(named: 'always')),
    ).thenAnswer((_) async {});
    when(() => actions.retryRejected(any())).thenAnswer((_) async {});
    when(() => actions.discardRejected(any())).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(_exito);
  });

  List<Override> overrides(SyncStatus status) => [
    transactionsRepositoryProvider.overrideWithValue(repository),
    transactionsClockProvider.overrideWithValue(() => _now),
    transactionActionsProvider.overrideWithValue(actions),
    syncCoordinatorProvider.overrideWith(() => _FixedCoordinator(status)),
  ];

  Future<void> pumpPage(
    WidgetTester tester, {
    SyncStatus status = const SyncStatus(),
    ThemeMode themeMode = ThemeMode.light,
    bool settle = true,
  }) async {
    await tester.pumpApp(
      const TransactionsPage(),
      overrides: overrides(status),
      themeMode: themeMode,
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  /// La página dentro de un GoRouter con el detalle y "Registrar".
  Future<void> pumpRouted(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/movimientos',
      routes: [
        GoRoute(
          path: '/movimientos',
          builder: (_, _) => const TransactionsPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  Text('detalle ${state.pathParameters['id']}'),
            ),
          ],
        ),
        GoRoute(path: '/registrar', builder: (_, _) => const Text('registrar')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(const SyncStatus()),
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

  testWidgets('pinta las tarjetas por día con montos formateados', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPage(tester);

    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Septiembre 2026'), findsOneWidget);
    expect(find.text('Este mes'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('martes'), findsOneWidget);
    expect(find.text('Ayer'), findsOneWidget);
    expect(find.text(r'−$184.300'), findsOneWidget);
    expect(find.text('Éxito Calle 80'), findsOneWidget);
    expect(find.text(r'−$126.400'), findsOneWidget);
    expect(find.text(r'$50.000'), findsOneWidget);
    expect(find.text(r'+$3.500.000'), findsOneWidget);
    expect(find.text('12:41'), findsOneWidget);
    expect(find.text('Por enviar'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('gasto de 126.400 pesos')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Cambiar categoría: Mercado y supermercado'),
      findsNWidgets(2),
    );
    handle.dispose();
  });

  testWidgets('las áreas táctiles del chip y del botón miden 48 dp', (
    tester,
  ) async {
    await pumpPage(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  group('cambio de categoría', () {
    Future<void> pickSalud(WidgetTester tester) async {
      await tester.tap(
        find
            .bySemanticsLabel('Cambiar categoría: Mercado y supermercado')
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text(r'Éxito Calle 80 · −$126.400'), findsOneWidget);
      expect(find.text('+ Nueva categoría'), findsOneWidget);
      await tester.tap(find.text('Salud y farmacia').last);
      await tester.pumpAndSettle();
    }

    testWidgets('con comercio pregunta y aprende la regla', (tester) async {
      await pumpPage(tester);

      await pickSalud(tester);
      expect(find.text('¿Aplicar siempre a Éxito Calle 80?'), findsOneWidget);
      await tester.tap(find.text('Siempre para Éxito Calle 80'));
      await tester.pumpAndSettle();

      verify(
        () => actions.changeCategory(_exito, 'salud', always: true),
      ).called(1);
    });

    testWidgets('"Solo este movimiento" no aprende la regla', (tester) async {
      await pumpPage(tester);

      await pickSalud(tester);
      await tester.tap(find.text('Solo este movimiento'));
      await tester.pumpAndSettle();

      verify(
        () => actions.changeCategory(_exito, 'salud', always: false),
      ).called(1);
    });

    testWidgets('sin comercio cambia sin preguntar', (tester) async {
      final anonymous = _tx('anon', merchant: null, pesos: 5000, at: _now);
      rows = (_) => [anonymous];
      await pumpPage(tester);
      expect(find.text('Sin comercio'), findsOneWidget);

      await tester.tap(
        find.bySemanticsLabel('Cambiar categoría: Mercado y supermercado'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mascotas'));
      await tester.pumpAndSettle();

      expect(find.textContaining('¿Aplicar siempre'), findsNothing);
      verify(
        () => actions.changeCategory(anonymous, 'mascotas', always: false),
      ).called(1);
    });

    testWidgets('cerrar el diálogo no cambia nada', (tester) async {
      await pumpPage(tester);

      await pickSalud(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      verifyNever(
        () =>
            actions.changeCategory(any(), any(), always: any(named: 'always')),
      );
    });
  });

  testWidgets('los filtros aplicados se cuentan en el botón', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPage(tester);
    expect(find.bySemanticsLabel('Filtros'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Ver 7 movimientos'), findsOneWidget);
    await tester.tap(find.text('Gastos'));
    await tester.tap(find.text('Nequi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver 7 movimientos'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Filtros, 2 activos'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Este mes · Solo gastos · Nequi'), findsOneWidget);
    verify(
      () => repository.watch(
        const TransactionFilter(kinds: {TxKind.expense}, banks: {'nequi'}),
        limit: 50,
      ),
    ).called(1);
    handle.dispose();
  });

  testWidgets('una categoría fuera de la lista se lee "Sin categoría"', (
    tester,
  ) async {
    // `sin_categoria` no está en la lista de categorías (no se asigna a
    // mano), pero el Inicio puede filtrar por ella.
    await pumpPage(tester);
    ProviderScope.containerOf(tester.element(find.byType(TransactionsPage)))
        .read(transactionsListControllerProvider.notifier)
        .setFilter(const TransactionFilter(categoryId: 'cat-sin'));
    await tester.pumpAndSettle();

    expect(find.text('Este mes · Sin categoría'), findsOneWidget);

    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Sin categoría'), findsOneWidget);
    expect(find.text('Categoría'), findsOneWidget);
  });

  testWidgets('"Limpiar" vuelve el borrador al filtro por defecto', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ingresos'));
    await tester.tap(find.text('Limpiar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver 7 movimientos'));
    await tester.pumpAndSettle();

    expect(find.text('Este mes'), findsOneWidget);
  });

  testWidgets('sin movimientos muestra el vacío con su CTA', (tester) async {
    rows = (_) => [];
    await pumpRouted(tester);

    expect(find.text('Aún no hay movimientos'), findsOneWidget);
    await tester.tap(find.text('Registrar un gasto'));
    await tester.pumpAndSettle();

    expect(find.text('registrar'), findsOneWidget);
  });

  testWidgets('tocar la fila abre el detalle', (tester) async {
    await pumpRouted(tester);

    await tester.tap(find.text('Éxito Calle 80'));
    await tester.pumpAndSettle();

    expect(find.text('detalle exito'), findsOneWidget);
  });

  group('mes vacío con movimientos anteriores', () {
    // Solo la consulta de "hay alguno" (periodo propio, 2000-3000) trae filas.
    List<TransactionView> onlyOlder(TransactionFilter filter) =>
        filter.period == PeriodPreset.custom ? _sample() : [];

    testWidgets('no dice que no hay movimientos', (tester) async {
      rows = onlyOlder;
      await pumpPage(tester);

      expect(find.text('Aún no hay movimientos'), findsNothing);
      expect(find.text('Sin movimientos este mes'), findsOneWidget);
      expect(find.text('Quitar filtros'), findsNothing);
    });

    testWidgets('"Ver mes pasado" cambia el periodo', (tester) async {
      rows = onlyOlder;
      await pumpPage(tester);

      await tester.tap(find.text('Ver mes pasado'));
      await tester.pumpAndSettle();

      verify(
        () => repository.watch(
          const TransactionFilter(period: PeriodPreset.lastMonth),
          limit: 50,
        ),
      ).called(1);
      expect(find.text('Agosto 2026'), findsOneWidget);
    });

    testWidgets('"Cambiar filtros" abre la hoja de filtros', (tester) async {
      rows = onlyOlder;
      await pumpPage(tester);

      await tester.tap(find.text('Cambiar filtros'));
      await tester.pumpAndSettle();

      expect(find.text('Limpiar'), findsOneWidget);
    });
  });

  testWidgets('una búsqueda sin resultados ofrece quitar filtros', (
    tester,
  ) async {
    rows = (filter) => filter.text.isEmpty ? _sample() : [];
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'Terpel');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Nada coincide con “Terpel”'), findsOneWidget);
    expect(find.text('Con los filtros: Este mes.'), findsOneWidget);

    await tester.tap(find.text('Quitar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('Éxito Calle 80'), findsOneWidget);
    expect(find.text('Terpel'), findsNothing);
  });

  testWidgets('si otra pantalla reemplaza el filtro, el buscador se limpia', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'Terpel');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    ProviderScope.containerOf(tester.element(find.byType(TransactionsPage)))
        .read(transactionsListControllerProvider.notifier)
        .setFilter(const TransactionFilter(categoryId: 'cat-mercado'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('sin conexión muestra el aviso', (tester) async {
    await pumpPage(tester, status: const SyncStatus(offline: true));

    expect(find.text('Sin conexión · ves tus datos guardados'), findsOneWidget);
  });

  testWidgets('la primera sincronización muestra el esqueleto', (tester) async {
    rows = (_) => [];
    await pumpPage(
      tester,
      status: const SyncStatus(running: true),
      settle: false,
    );
    await tester.pump();

    expect(find.text('Trayendo tus movimientos…'), findsOneWidget);
    expect(find.text('Aún no hay movimientos'), findsNothing);
  });

  testWidgets('un cambio rechazado se reintenta o se descarta', (
    tester,
  ) async {
    rows = (_) => [
      _tx(
        'd1',
        merchant: 'D1 Chapinero',
        pesos: 42700,
        at: _now,
        sync: SyncMark.rejected,
      ),
    ];
    await pumpPage(tester);

    expect(find.text('No enviado'), findsOneWidget);
    expect(find.text('No se guardó un cambio'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    verify(() => actions.retryRejected('d1')).called(1);
    await tester.tap(find.text('Dejar como estaba'));
    verify(() => actions.discardRejected('d1')).called(1);
  });

  testWidgets('al acercarse al final pide la página siguiente', (
    tester,
  ) async {
    final many = [
      for (var i = 0; i < 50; i++)
        _tx(
          'tx$i',
          merchant: 'Comercio $i',
          pesos: 1000,
          at: _now.subtract(Duration(hours: i * 5)),
        ),
    ];
    rows = (_) => many;
    await pumpPage(tester, settle: false);
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pump();

    verify(
      () => repository.watch(const TransactionFilter(), limit: 100),
    ).called(1);
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('movimientos ${mode.name}', tags: ['golden'], (tester) async {
        await pumpPage(tester, themeMode: mode);
        await expectLater(
          find.byType(TransactionsPage),
          matchesGoldenFile('goldens/transactions_${mode.name}.png'),
        );
      });
    }
  });
}
