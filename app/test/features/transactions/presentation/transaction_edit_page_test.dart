import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/app_theme.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/application/transaction_actions.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';
import 'package:luka/features/transactions/domain/transactions_repository.dart';
import 'package:luka/features/transactions/presentation/transaction_edit_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _Repository extends Mock implements TransactionsRepository {}

class _Actions extends Mock implements TransactionActions {}

/// Hora de Bogotá del día [day] de octubre de 2026, como instante UTC.
DateTime _at(int day, int hour, int minute) =>
    DateTime.utc(2026, 10, day, hour + 5, minute);

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

final _frisby = TransactionView(
  id: 'frisby',
  amount: Cop.pesos(99000),
  direction: TxDirection.debit,
  kind: TxKind.expense,
  occurredAt: _at(4, 15, 31),
  channels: const {TxChannel.email},
  sync: SyncMark.none,
  merchant: 'FRISBY I 24',
  categoryId: 'restaurantes',
  categoryName: 'Restaurantes',
  categorySlug: 'restaurantes',
  bank: 'bancolombia',
  accountId: 'acc-1',
  accountBank: 'bancolombia',
  accountKind: 'savings',
  accountLast4: '1799',
  parsedBy: 'rule:bancolombia:compra_tdeb:v1',
);

final _paired = TransactionView(
  id: 'to-nequi',
  amount: Cop.pesos(50000),
  direction: TxDirection.debit,
  kind: TxKind.transfer,
  occurredAt: _at(4, 9, 1),
  channels: const {TxChannel.notification},
  sync: SyncMark.none,
  merchant: 'A tu cuenta Nequi',
  bank: 'bancolombia',
  transferPairId: 'from-bancolombia',
  parsedBy: 'llm',
);

void main() {
  late _Repository repository;
  late _Actions actions;

  setUpAll(() {
    registerFallbackValue(_frisby);
    registerFallbackValue(const TransactionPatch());
  });

  setUp(() {
    repository = _Repository();
    actions = _Actions();
    final rows = {_frisby.id: _frisby, _paired.id: _paired};
    when(() => repository.watchOne(any())).thenAnswer(
      (invocation) =>
          Stream.value(rows[invocation.positionalArguments.first as String]),
    );
    when(() => repository.fetchSources(any())).thenAnswer((_) async => []);
    when(
      () => repository.watchCategories(),
    ).thenAnswer((_) => Stream.value(_categories));
    when(() => actions.edit(any(), any())).thenAnswer((_) async {});
  });

  /// La edición de [id] dentro de un GoRouter, sobre su detalle.
  Future<void> pumpEdit(
    WidgetTester tester, {
    String id = 'frisby',
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 900) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/movimientos/$id/editar',
      routes: [
        GoRoute(
          path: '/movimientos/:id',
          builder: (_, _) => const Scaffold(body: Text('detalle')),
          routes: [
            GoRoute(
              path: 'editar',
              builder: (_, state) =>
                  TransactionEditPage(id: state.pathParameters['id']!),
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
          transactionsClockProvider.overrideWithValue(() => _at(5, 10, 0)),
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

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
  }

  testWidgets('sale prellenado con el movimiento', (tester) async {
    await pumpEdit(tester);

    expect(find.text('Editar movimiento'), findsOneWidget);
    expect(find.text('FRISBY I 24'), findsOneWidget);
    expect(find.text('Restaurantes'), findsOneWidget);
    expect(find.textContaining('1799'), findsOneWidget);
  });

  testWidgets('guardar envía solo lo que cambió y vuelve al detalle', (
    tester,
  ) async {
    await pumpEdit(tester);

    await tester.enterText(find.text('FRISBY I 24'), 'Frisby');
    await save(tester);

    verify(
      () => actions.edit(
        _frisby,
        const TransactionPatch(
          merchant: (value: 'Frisby'),
          learnMerchantRule: false,
        ),
      ),
    ).called(1);
    expect(find.text('detalle'), findsOneWidget);
    expect(find.text('Cambios guardados'), findsOneWidget);
  });

  testWidgets('sin cambios no envía nada', (tester) async {
    await pumpEdit(tester);

    await save(tester);

    verifyNever(() => actions.edit(any(), any()));
    expect(find.text('detalle'), findsOneWidget);
  });

  testWidgets('sin monto no guarda y lo dice', (tester) async {
    await pumpEdit(tester);

    await tester.enterText(find.byType(TextField).first, '');
    await save(tester);

    verifyNever(() => actions.edit(any(), any()));
    expect(find.text(r'Escribe un monto mayor a $0.'), findsOneWidget);
  });

  testWidgets(
    'en una transferencia emparejada el monto y el tipo no se tocan',
    (
      tester,
    ) async {
      await pumpEdit(tester, id: 'to-nequi');

      expect(find.textContaining('desmárcala'), findsOneWidget);
      final locked = find.ancestor(
        of: find.text('Gasto'),
        matching: find.byType(IgnorePointer),
      );
      expect(
        tester.widgetList<IgnorePointer>(locked).any((w) => w.ignoring),
        isTrue,
      );
    },
  );

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('editar ${mode.name}', tags: ['golden'], (tester) async {
        await pumpEdit(tester, themeMode: mode);
        await expectLater(
          find.byType(TransactionEditPage),
          matchesGoldenFile('goldens/transaction_edit_${mode.name}.png'),
        );
      });
    }
  });
}
