import 'dart:async';

import 'package:finanzia/app/app.dart';
import 'package:finanzia/app/router.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/auth/presentation/login_page.dart';
import 'package:finanzia/features/auth/presentation/splash_page.dart';
import 'package:finanzia/features/dashboard/presentation/dashboard_placeholder_page.dart';
import 'package:finanzia/features/gmail/application/gmail_controller.dart';
import 'package:finanzia/features/gmail/application/gmail_gate.dart';
import 'package:finanzia/features/gmail/domain/gmail_connection.dart';
import 'package:finanzia/features/gmail/domain/gmail_failure.dart';
import 'package:finanzia/features/gmail/domain/gmail_prompt_store.dart';
import 'package:finanzia/features/gmail/domain/gmail_repository.dart';
import 'package:finanzia/features/gmail/presentation/gmail_onboarding_page.dart';
import 'package:finanzia/features/review/application/review_providers.dart';
import 'package:finanzia/features/review/domain/review_item.dart';
import 'package:finanzia/features/review/domain/review_repository.dart';
import 'package:finanzia/features/review/presentation/review_detail_page.dart';
import 'package:finanzia/features/review/presentation/review_page.dart';
import 'package:finanzia/features/shell/presentation/home_shell.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/domain/sync_ports.dart';
import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/domain/transaction_filter.dart';
import 'package:finanzia/features/transactions/domain/transactions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSyncStore extends Mock implements SyncStore {}

class _MockTransactions extends Mock implements TransactionsRepository {}

class _MockGmail extends Mock implements GmailRepository {}

class _MockPrompts extends Mock implements GmailPromptStore {}

class _MockReview extends Mock implements ReviewRepository {}

class _StartingAuthController extends AuthController {
  _StartingAuthController(this._initial);

  final AuthState _initial;

  @override
  Future<AuthState> build() async => _initial;
}

class _IdleCoordinator extends SyncCoordinator {
  @override
  SyncStatus build() => const SyncStatus();
}

const _ana = User(
  id: 'u-1',
  email: 'ana@example.com',
  status: UserStatus.active,
);

/// El gate de sesión con la app entera: login → Gmail → Inicio.
void main() {
  late _MockSyncStore store;
  late _MockTransactions transactions;
  late _MockGmail gmail;
  late _MockPrompts prompts;
  late _MockReview review;

  setUpAll(() => registerFallbackValue(const TransactionFilter()));

  setUp(() {
    store = _MockSyncStore();
    transactions = _MockTransactions();
    gmail = _MockGmail();
    prompts = _MockPrompts();
    review = _MockReview();
    when(() => review.watchOpen()).thenAnswer((_) => Stream.value(const []));
    when(() => review.watchOne(any())).thenAnswer(
      (_) => Stream.value(
        ReviewItem(
          rawMessageId: 'm-1',
          channel: 'email',
          sender: 'alertas@bancolombia.com.co',
          receivedAt: DateTime.utc(2026, 9, 23, 17),
          reason: 'no_template',
          partialExtract: const {},
        ),
      ),
    );
    when(() => store.watchOpenReviewCount()).thenAnswer((_) => Stream.value(0));
    when(
      () => transactions.watch(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => transactions.watchCategories(),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => gmail.status(),
    ).thenAnswer((_) async => GmailConnectionInfo.disconnected);
    when(() => prompts.isDismissed(any())).thenAnswer((_) async => false);
    when(() => prompts.dismiss(any())).thenAnswer((_) async {});
  });

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    AuthState auth = const Authenticated(_ana),
  }) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StartingAuthController(auth),
        ),
        syncCoordinatorProvider.overrideWith(_IdleCoordinator.new),
        syncStoreProvider.overrideWithValue(store),
        transactionsRepositoryProvider.overrideWithValue(transactions),
        gmailRepositoryProvider.overrideWithValue(gmail),
        gmailPromptStoreProvider.overrideWithValue(prompts),
        reviewRepositoryProvider.overrideWithValue(review),
      ],
    );
    addTearDown(container.dispose);
    tester.view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FinanziaApp(),
      ),
    );
    return container;
  }

  final home = find.byType(DashboardPlaceholderPage);
  final onboarding = find.byType(GmailOnboardingPage);

  testWidgets('tras el login sin Gmail pasa por el splash al paso de Gmail, '
      'sin asomarse a Inicio', (tester) async {
    final status = Completer<GmailConnectionInfo>();
    final container = await pumpApp(tester, auth: const Unauthenticated());
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    when(() => gmail.status()).thenAnswer((_) => status.future);
    container.read(authControllerProvider.notifier).signedIn(_ana);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(home, findsNothing);
      expect(onboarding, findsNothing);
    }
    expect(find.byType(SplashPage), findsOneWidget);

    status.complete(GmailConnectionInfo.disconnected);
    await tester.pumpAndSettle();
    expect(onboarding, findsOneWidget);
    expect(home, findsNothing);
  });

  testWidgets('"Ahora no" lleva a Inicio y el gate no vuelve a mandar al '
      'onboarding', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(onboarding, findsOneWidget);

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(home, findsOneWidget);
    verify(() => prompts.dismiss('u-1')).called(1);
  });

  testWidgets('con Gmail activo abre directo en Inicio', (tester) async {
    when(() => gmail.status()).thenAnswer(
      (_) async => const GmailConnectionInfo(status: GmailStatus.active),
    );
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(home, findsOneWidget);
    expect(onboarding, findsNothing);
  });

  testWidgets('con "Ahora no" guardado abre directo en Inicio', (tester) async {
    when(() => prompts.isDismissed('u-1')).thenAnswer((_) async => true);
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(home, findsOneWidget);
  });

  testWidgets('sin red abre en Inicio (Gmail es opcional)', (tester) async {
    when(() => gmail.status()).thenThrow(const GmailNetworkFailure());
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(home, findsOneWidget);
  });

  testWidgets('si el estado tarda, sigue a Inicio y no rebota al llegar', (
    tester,
  ) async {
    final status = Completer<GmailConnectionInfo>();
    when(() => gmail.status()).thenAnswer((_) => status.future);
    final container = await pumpApp(tester);
    await tester.pump();
    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump(GmailGateController.timeout);
    await tester.pumpAndSettle();
    expect(home, findsOneWidget);

    status.complete(GmailConnectionInfo.disconnected);
    await tester.pumpAndSettle();
    expect(container.read(gmailGateProvider), GmailGate.prompt);
    expect(home, findsOneWidget);
    expect(onboarding, findsNothing);
  });

  testWidgets('el deep link al onboarding funciona sin nada pendiente', (
    tester,
  ) async {
    when(() => gmail.status()).thenAnswer(
      (_) async => const GmailConnectionInfo(status: GmailStatus.active),
    );
    final container = await pumpApp(tester);
    await tester.pumpAndSettle();

    container.read(routerProvider).go(Routes.onboardingGmail);
    await tester.pumpAndSettle();

    expect(onboarding, findsOneWidget);
  });

  testWidgets('Revisión vive en el shell y su detalle va a pantalla completa', (
    tester,
  ) async {
    when(() => prompts.isDismissed('u-1')).thenAnswer((_) async => true);
    final container = await pumpApp(tester);
    await tester.pumpAndSettle();

    container.read(routerProvider).go(Routes.review);
    await tester.pumpAndSettle();
    expect(find.byType(ReviewPage), findsOneWidget);
    expect(find.byType(HomeShell), findsOneWidget);

    container.read(routerProvider).go('${Routes.review}/m-1');
    await tester.pumpAndSettle();
    expect(find.byType(ReviewDetailPage), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
    verify(() => review.watchOne('m-1')).called(1);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewPage), findsOneWidget);
  });
}
