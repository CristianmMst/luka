import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/app_theme.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/application/transaction_actions.dart';
import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/domain/category_option.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:finanzia/features/transactions/domain/transactions_repository.dart';
import 'package:finanzia/features/transactions/presentation/transaction_detail_page.dart';
import 'package:finanzia/features/transactions/presentation/widgets/transaction_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _Repository extends Mock implements TransactionsRepository {}

class _Actions extends Mock implements TransactionActions {}

class _Coordinator extends SyncCoordinator {
  @override
  SyncStatus build() => const SyncStatus();

  // ignore: use_setters_to_change_properties, en tests es más legible.
  void emit(SyncStatus status) => state = status;
}

/// Hora de Bogotá del día [day] de septiembre de 2026, como instante UTC.
DateTime _at(int day, int hour, int minute) =>
    DateTime.utc(2026, 9, day, hour + 5, minute);

const _categories = [
  CategoryOption(
    id: 'mercado',
    name: 'Mercado',
    isSystem: true,
    slug: 'mercado',
  ),
  CategoryOption(
    id: 'restaurantes',
    name: 'Restaurantes',
    isSystem: true,
    slug: 'restaurantes',
  ),
];

final _exito = TransactionView(
  id: 'exito',
  amount: Cop.pesos(126400),
  direction: TxDirection.debit,
  kind: TxKind.expense,
  occurredAt: _at(23, 12, 41),
  channels: const {TxChannel.notification, TxChannel.email},
  sync: SyncMark.none,
  merchant: 'Éxito Calle 80',
  categoryId: 'mercado',
  categoryName: 'Mercado',
  categorySlug: 'mercado',
  bank: 'bancolombia',
  accountBank: 'bancolombia',
  accountKind: 'savings',
  accountLast4: '4821',
  parsedBy: 'rule:bancolombia:compra_v1',
);

final _toNequi = TransactionView(
  id: 'to-nequi',
  amount: Cop.pesos(50000),
  direction: TxDirection.debit,
  kind: TxKind.transfer,
  occurredAt: _at(23, 9, 1),
  channels: const {TxChannel.notification},
  sync: SyncMark.none,
  merchant: 'A tu cuenta Nequi',
  categoryId: 'transferencias',
  categoryName: 'Transferencias',
  categorySlug: 'transferencias',
  bank: 'bancolombia',
  transferPairId: 'from-bancolombia',
  parsedBy: 'llm',
);

final _fromBancolombia = TransactionView(
  id: 'from-bancolombia',
  amount: Cop.pesos(50000),
  direction: TxDirection.credit,
  kind: TxKind.transfer,
  occurredAt: _at(23, 9, 2),
  channels: const {TxChannel.notification},
  sync: SyncMark.none,
  merchant: 'Desde Bancolombia',
  bank: 'nequi',
  transferPairId: 'to-nequi',
);

final _manual = TransactionView(
  id: 'manual',
  amount: Cop.pesos(2000000),
  direction: TxDirection.credit,
  kind: TxKind.income,
  occurredAt: _at(25, 15, 42),
  channels: const {TxChannel.manual},
  sync: SyncMark.none,
  merchant: 'Prueba',
  parsedBy: 'manual',
);

final List<TxSource> _twoSources = [
  (channel: TxChannel.email, receivedAt: _at(23, 12, 43)),
  (channel: TxChannel.notification, receivedAt: _at(23, 12, 41)),
];

void main() {
  late _Repository repository;
  late _Actions actions;
  late _Coordinator coordinator;
  late Map<String, TransactionView?> rows;
  late List<TxSource>? sources;

  setUpAll(() => registerFallbackValue(_exito));

  setUp(() {
    repository = _Repository();
    actions = _Actions();
    coordinator = _Coordinator();
    rows = {
      _exito.id: _exito,
      _toNequi.id: _toNequi,
      _fromBancolombia.id: _fromBancolombia,
      _manual.id: _manual,
    };
    sources = _twoSources;
    when(() => repository.watchOne(any())).thenAnswer(
      (invocation) =>
          Stream.value(rows[invocation.positionalArguments.first as String]),
    );
    when(() => repository.fetchSources(any())).thenAnswer((_) async => sources);
    when(
      () => repository.watchCategories(),
    ).thenAnswer((_) => Stream.value(_categories));
    when(
      () => actions.changeCategory(any(), any(), always: any(named: 'always')),
    ).thenAnswer((_) async {});
    when(
      () => actions.setTransfer(any(), isTransfer: any(named: 'isTransfer')),
    ).thenAnswer((_) async {});
    when(() => actions.saveNotes(any(), any())).thenAnswer((_) async {});
    when(() => actions.retryRejected(any())).thenAnswer((_) async {});
    when(() => actions.discardRejected(any())).thenAnswer((_) async {});
    when(() => actions.delete(any())).thenAnswer((_) async {});
  });

  /// El detalle de [id] dentro de un GoRouter, sobre la lista.
  Future<void> pumpDetail(
    WidgetTester tester, {
    String id = 'exito',
    ThemeMode themeMode = ThemeMode.light,
    Size size = const Size(390, 1040),
  }) async {
    tester.view
      ..physicalSize = size * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/movimientos/$id',
      routes: [
        GoRoute(
          path: '/movimientos',
          builder: (_, _) => const Scaffold(body: Text('lista')),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  TransactionDetailPage(id: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(repository),
          transactionActionsProvider.overrideWithValue(actions),
          syncCoordinatorProvider.overrideWith(() => coordinator),
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

  testWidgets('muestra los campos con el monto en decimales', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpDetail(tester);

    expect(find.text('Movimiento'), findsOneWidget);
    expect(find.text('Éxito Calle 80'), findsOneWidget);
    expect(find.text(r'−$126.400,00'), findsOneWidget);
    expect(find.bySemanticsLabel('gasto de 126.400,00 pesos'), findsOneWidget);
    expect(find.text('Miércoles 23 sep 2026 · 12:41'), findsOneWidget);
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Bancolombia ahorros ···4821'), findsOneWidget);
    expect(find.text('Gasto'), findsOneWidget);
    expect(find.text('Leído con'), findsOneWidget);
    expect(find.text('Plantilla Bancolombia'), findsOneWidget);
    expect(find.text('Marcar como transferencia propia'), findsOneWidget);
    expect(find.text('Agrega una nota para ti'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('las áreas táctiles miden al menos 48 dp', (tester) async {
    await pumpDetail(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('fuentes cargadas: una tarjeta por fuente y el sello', (
    tester,
  ) async {
    await pumpDetail(tester);

    expect(find.text('2 canales'), findsOneWidget);
    expect(find.text('Notificación del banco'), findsOneWidget);
    expect(find.text('Recibida 23 sep · 12:41'), findsOneWidget);
    expect(find.text('Correo del banco'), findsOneWidget);
    expect(find.text('Recibido 23 sep · 12:43'), findsOneWidget);
    expect(
      find.text('1 registro con 2 fuentes, sin duplicados'),
      findsOneWidget,
    );
  });

  testWidgets('con una sola fuente no hay sello', (tester) async {
    sources = [(channel: TxChannel.manual, receivedAt: _at(23, 12, 41))];
    await pumpDetail(tester);

    expect(find.text('1 canal'), findsOneWidget);
    expect(find.text('Registrado 23 sep · 12:41'), findsOneWidget);
    expect(find.textContaining('1 registro con'), findsNothing);
  });

  testWidgets('sin fuentes en el servidor lo explica', (tester) async {
    sources = const [];
    await pumpDetail(tester);

    expect(
      find.text(
        'Las fuentes aparecen cuando el movimiento llega a tu cuenta en el '
        'servidor.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sin conexión muestra el panel y reintenta al volver la red', (
    tester,
  ) async {
    sources = null;
    await pumpDetail(tester);

    expect(
      find.text(
        'Las fuentes se consultan con conexión. El resto del movimiento '
        'está guardado en tu teléfono.',
      ),
      findsOneWidget,
    );

    sources = _twoSources;
    coordinator.emit(const SyncStatus(offline: true));
    await tester.pump();
    coordinator.emit(const SyncStatus());
    await tester.pumpAndSettle();

    verify(() => repository.fetchSources('exito')).called(2);
    expect(find.text('Correo del banco'), findsOneWidget);
  });

  testWidgets('marcar como transferencia llama a setTransfer', (tester) async {
    await pumpDetail(tester);

    await tester.ensureVisible(find.text('Marcar como transferencia propia'));
    await tester.tap(find.text('Marcar como transferencia propia'));

    verify(() => actions.setTransfer(_exito, isTransfer: true)).called(1);
  });

  testWidgets('una transferencia se desmarca y abre la otra parte', (
    tester,
  ) async {
    await pumpDetail(tester, id: _toNequi.id);

    expect(find.text('TRANSFERENCIA PROPIA'), findsOneWidget);
    expect(find.text(r'$50.000,00'), findsOneWidget);
    expect(find.text('No cuenta como gasto ni como ingreso'), findsOneWidget);
    expect(find.text('Transferencia propia'), findsOneWidget);
    expect(find.text('Lectura automática'), findsOneWidget);

    await tester.ensureVisible(find.text('No es una transferencia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No es una transferencia'));
    verify(() => actions.setTransfer(_toNequi, isTransfer: false)).called(1);

    expect(find.text('La otra parte'), findsOneWidget);
    await tester.tap(find.text('Nequi · recibida 09:02'));
    await tester.pumpAndSettle();

    expect(find.text('Desde Bancolombia'), findsOneWidget);
    expect(find.text('Bancolombia · enviada 09:01'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('A tu cuenta Nequi'), findsOneWidget);
  });

  testWidgets('el aviso de rechazo reintenta o descarta', (tester) async {
    rows[_exito.id] = _exito.copyWith(sync: SyncMark.rejected);
    await pumpDetail(tester);

    expect(find.text('No se guardó un cambio'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    verify(() => actions.retryRejected('exito')).called(1);
    await tester.tap(find.text('Dejar como estaba'));
    verify(() => actions.discardRejected('exito')).called(1);
  });

  testWidgets('el chip de categoría abre la hoja y pregunta por la regla', (
    tester,
  ) async {
    await pumpDetail(tester);

    await tester.tap(find.bySemanticsLabel('Cambiar categoría: Mercado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restaurantes'));
    await tester.pumpAndSettle();
    expect(find.text('¿Aplicar siempre a Éxito Calle 80?'), findsOneWidget);
    await tester.tap(find.text('Solo este movimiento'));
    await tester.pumpAndSettle();

    verify(
      () => actions.changeCategory(_exito, 'restaurantes', always: false),
    ).called(1);
  });

  group('notas', () {
    testWidgets('se guardan tras la pausa al escribir', (tester) async {
      await pumpDetail(tester);

      await tester.enterText(find.byType(TextField), 'Para la casa');
      await tester.pump(const Duration(milliseconds: 400));
      verifyNever(() => actions.saveNotes(any(), any()));
      await tester.pump(const Duration(seconds: 1));

      verify(() => actions.saveNotes(_exito, 'Para la casa')).called(1);
    });

    testWidgets('se guardan al perder el foco, una sola vez', (tester) async {
      await pumpDetail(tester);

      await tester.enterText(find.byType(TextField), 'Para la casa ');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      verify(() => actions.saveNotes(_exito, 'Para la casa')).called(1);

      await tester.pump(const Duration(seconds: 1));
      verifyNever(() => actions.saveNotes(any(), any()));
    });

    testWidgets('se guardan al salir de la pantalla', (tester) async {
      await pumpDetail(tester);

      await tester.enterText(find.byType(TextField), 'Para la casa');
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();

      expect(find.text('lista'), findsOneWidget);
      verify(() => actions.saveNotes(_exito, 'Para la casa')).called(1);
    });

    testWidgets('sin cambios no guarda nada', (tester) async {
      rows[_exito.id] = _exito.copyWith(notes: 'Para la casa');
      await pumpDetail(tester);

      expect(find.text('Para la casa'), findsOneWidget);
      await tester.tap(find.byType(TextField));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      verifyNever(() => actions.saveNotes(any(), any()));
    });
  });

  group('eliminar', () {
    testWidgets('uno manual pide confirmación, borra y vuelve', (
      tester,
    ) async {
      await pumpDetail(tester, id: 'manual');

      await tester.ensureVisible(find.text('Eliminar movimiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar movimiento'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar este movimiento?'), findsOneWidget);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      verify(() => actions.delete('manual')).called(1);
      expect(find.text('lista'), findsOneWidget);
      expect(find.text('Movimiento eliminado'), findsOneWidget);
    });

    testWidgets('cancelar no borra', (tester) async {
      await pumpDetail(tester, id: 'manual');

      await tester.ensureVisible(find.text('Eliminar movimiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar movimiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => actions.delete(any()));
      expect(find.text('Eliminar movimiento'), findsOneWidget);
    });

    testWidgets('el botón mide 48 dp o más', (tester) async {
      await pumpDetail(tester, id: 'manual');

      final button = find.ancestor(
        of: find.text('Eliminar movimiento'),
        matching: find.byWidgetPredicate((w) => w is TextButton),
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    });

    for (final id in ['exito', 'to-nequi']) {
      testWidgets('uno capturado ($id) no se puede eliminar', (tester) async {
        await pumpDetail(tester, id: id);
        expect(find.text('Eliminar movimiento'), findsNothing);
      });
    }
  });

  testWidgets('un movimiento borrado lo dice', (tester) async {
    rows.remove(_exito.id);
    await pumpDetail(tester);

    expect(find.text('Este movimiento ya no existe.'), findsOneWidget);
  });

  test('"Leído con" traduce parsed_by', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('es'));

    expect(
      parsedByLabel(l10n, 'rule:bancolombia:compra_v1'),
      'Plantilla '
      'Bancolombia',
    );
    expect(
      parsedByLabel(l10n, 'rule:banco_bogota:x'),
      'Plantilla Banco de Bogotá',
    );
    expect(parsedByLabel(l10n, 'rule:banco_x:y'), 'Plantilla Banco x');
    expect(parsedByLabel(l10n, 'llm'), 'Lectura automática');
    expect(parsedByLabel(l10n, 'manual'), 'Registro manual');
    expect(parsedByLabel(l10n, 'rule:'), isNull);
    expect(parsedByLabel(l10n, 'otro'), isNull);
    expect(parsedByLabel(l10n, null), isNull);
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('detalle ${mode.name}', tags: ['golden'], (tester) async {
        await pumpDetail(
          tester,
          themeMode: mode,
        );
        await expectLater(
          find.byType(TransactionDetailPage),
          matchesGoldenFile('goldens/transaction_detail_${mode.name}.png'),
        );
      });
    }
  });
}
