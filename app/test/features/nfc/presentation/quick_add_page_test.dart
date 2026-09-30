import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/app_theme.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';
import 'package:luka/features/nfc/application/nfc_actions.dart';
import 'package:luka/features/nfc/domain/nfc_ports.dart';
import 'package:luka/features/nfc/presentation/quick_add_page.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/domain/transactions_repository.dart';
import 'package:mocktail/mocktail.dart';

class _Actions extends Mock implements NfcActions {}

class _Store extends Mock implements NfcTagStore {}

class _Accounts extends Mock implements AccountsStore {}

class _Transactions extends Mock implements TransactionsRepository {}

class _Idle extends SyncCoordinator {
  @override
  SyncStatus build() => const SyncStatus();
}

const _cafe = NfcTagTemplate(
  id: 't-1',
  name: 'Café de la oficina',
  categoryId: 'c-rest',
  accountId: 'a-1',
  note: 'tinto',
);

void main() {
  late _Actions actions;
  late _Store store;
  late _Accounts accounts;
  late _Transactions transactions;

  setUpAll(() => registerFallbackValue(Cop.pesos(1)));

  setUp(() {
    actions = _Actions();
    store = _Store();
    accounts = _Accounts();
    transactions = _Transactions();
    when(
      () => actions.saveQuickAdd(
        tagId: any(named: 'tagId'),
        amount: any(named: 'amount'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
        note: any(named: 'note'),
        rememberAs: any(named: 'rememberAs'),
      ),
    ).thenAnswer((_) async => 'local-1');
    when(() => accounts.watchAll()).thenAnswer(
      (_) => Stream.value(const [
        LinkedAccount(
          id: 'a-1',
          bank: 'bancolombia',
          kind: 'savings',
          alias: 'Nómina',
          transactionCount: 0,
        ),
      ]),
    );
    when(() => transactions.watchCategories()).thenAnswer(
      (_) => Stream.value(const [
        CategoryOption(id: 'c-rest', name: 'Restaurantes', isSystem: true),
        CategoryOption(id: 'c-trans', name: 'Transporte', isSystem: true),
      ]),
    );
  });

  Future<void> pumpPage(WidgetTester tester, String tagId) async {
    tester.view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('inicio')),
          routes: [
            GoRoute(
              path: 'rapido',
              pageBuilder: (_, _) => QuickAddPage.page(tagId: tagId),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nfcActionsProvider.overrideWithValue(actions),
          nfcTagStoreProvider.overrideWithValue(store),
          accountsStoreProvider.overrideWithValue(accounts),
          transactionsRepositoryProvider.overrideWithValue(transactions),
          syncCoordinatorProvider.overrideWith(_Idle.new),
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
    unawaited(router.push('/rapido'));
    await tester.pumpAndSettle();
  }

  testWidgets('un tag conocido solo pide el monto', (tester) async {
    when(() => store.get('t-1')).thenAnswer((_) async => _cafe);
    await pumpPage(tester, 't-1');

    expect(find.text('Café de la oficina'), findsOneWidget);
    expect(find.text('Restaurantes · Nómina'), findsOneWidget);
    expect(find.text('Guardar como plantilla de este tag'), findsNothing);

    await tester.enterText(find.byType(TextField), '8500');
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    verify(
      () => actions.saveQuickAdd(
        tagId: 't-1',
        amount: Cop.pesos(8500),
        categoryId: 'c-rest',
        accountId: 'a-1',
        note: 'tinto',
      ),
    ).called(1);
    expect(find.byType(QuickAddPage), findsNothing);
    expect(find.text('inicio'), findsOneWidget);
  });

  testWidgets('sin monto avisa y no guarda', (tester) async {
    when(() => store.get('t-1')).thenAnswer((_) async => _cafe);
    await pumpPage(tester, 't-1');

    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe cuánto fue.'), findsOneWidget);
    verifyNever(
      () => actions.saveQuickAdd(
        tagId: any(named: 'tagId'),
        amount: any(named: 'amount'),
      ),
    );
  });

  testWidgets('un tag desconocido pide la categoría y lo recuerda', (
    tester,
  ) async {
    when(() => store.get('t-9')).thenAnswer((_) async => null);
    await pumpPage(tester, 't-9');

    expect(find.text('Tag sin configurar'), findsOneWidget);
    expect(find.text('Este teléfono no lo conoce'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '5000');
    await tester.tap(find.text('Categoría: Elegir categoría…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transporte'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar gasto'));
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    verify(
      () => actions.saveQuickAdd(
        tagId: 't-9',
        amount: Cop.pesos(5000),
        categoryId: 'c-trans',
        rememberAs: 'Transporte',
      ),
    ).called(1);
  });

  testWidgets('sin la casilla no se guarda la plantilla', (tester) async {
    when(() => store.get('t-9')).thenAnswer((_) async => null);
    await pumpPage(tester, 't-9');

    await tester.enterText(find.byType(TextField), '5000');
    await tester.tap(find.text('Guardar como plantilla de este tag'));
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar gasto'));
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    verify(
      () => actions.saveQuickAdd(tagId: 't-9', amount: Cop.pesos(5000)),
    ).called(1);
  });
}
