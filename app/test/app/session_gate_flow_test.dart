import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/app/app.dart';
import 'package:luka/app/router.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/domain/entities/user.dart';
import 'package:luka/features/auth/presentation/login_page.dart';
import 'package:luka/features/auth/presentation/splash_page.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/capture/data/method_channel_notification_source.dart';
import 'package:luka/features/dashboard/application/dashboard_providers.dart';
import 'package:luka/features/dashboard/domain/insights_repository.dart';
import 'package:luka/features/dashboard/domain/monthly_summary.dart';
import 'package:luka/features/dashboard/presentation/dashboard_page.dart';
import 'package:luka/features/gmail/application/gmail_controller.dart';
import 'package:luka/features/gmail/domain/gmail_connection.dart';
import 'package:luka/features/gmail/domain/gmail_failure.dart';
import 'package:luka/features/gmail/domain/gmail_repository.dart';
import 'package:luka/features/gmail/presentation/gmail_onboarding_page.dart';
import 'package:luka/features/onboarding/application/onboarding_gate.dart';
import 'package:luka/features/onboarding/domain/onboarding_step.dart';
import 'package:luka/features/onboarding/domain/onboarding_store.dart';
import 'package:luka/features/onboarding/presentation/accounts_onboarding_page.dart';
import 'package:luka/features/review/application/review_providers.dart';
import 'package:luka/features/review/domain/review_item.dart';
import 'package:luka/features/review/domain/review_repository.dart';
import 'package:luka/features/review/presentation/review_detail_page.dart';
import 'package:luka/features/review/presentation/review_page.dart';
import 'package:luka/features/shell/presentation/home_shell.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/domain/sync_ports.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/transaction_filter.dart';
import 'package:luka/features/transactions/domain/transactions_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/capture_health.dart';

class _MockSyncStore extends Mock implements SyncStore {}

class _MockTransactions extends Mock implements TransactionsRepository {}

class _MockGmail extends Mock implements GmailRepository {}

class _MockOnboarding extends Mock implements OnboardingStore {}

class _MockAccounts extends Mock implements AccountsStore {}

class _MockReview extends Mock implements ReviewRepository {}

class _MockInsights extends Mock implements InsightsRepository {}

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

/// El gate de sesión con la app entera: login → onboarding → Inicio. Con
/// `NoopNotificationSource` (como en iOS) no hay paso de notificaciones.
void main() {
  late _MockSyncStore store;
  late _MockTransactions transactions;
  late _MockGmail gmail;
  late _MockOnboarding onboardingStore;
  late _MockAccounts accounts;
  late _MockReview review;
  late _MockInsights insights;

  setUpAll(() {
    registerFallbackValue(const TransactionFilter());
    registerFallbackValue(ColombiaMonth(2000, 1));
  });

  setUp(() {
    store = _MockSyncStore();
    transactions = _MockTransactions();
    gmail = _MockGmail();
    onboardingStore = _MockOnboarding();
    accounts = _MockAccounts();
    review = _MockReview();
    insights = _MockInsights();
    when(() => insights.watchMonth(any())).thenAnswer(
      (i) => Stream.value(
        MonthlySummary(
          month: i.positionalArguments.single as ColombiaMonth,
          totals: const MonthlyTotals(),
          previousTotals: const MonthlyTotals(),
          topCategories: const [],
          otherAmount: const Cop(0),
        ),
      ),
    );
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
    when(
      () => onboardingStore.isDone(any()),
    ).thenAnswer((_) async => false);
    when(() => onboardingStore.markDone(any())).thenAnswer((_) async {});
    when(() => accounts.watchAll()).thenAnswer((_) => Stream.value(const []));
  });

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    AuthState auth = const Authenticated(_ana),
  }) async {
    final container = ProviderContainer(
      overrides: [
        captureHealthOk(),
        authControllerProvider.overrideWith(
          () => _StartingAuthController(auth),
        ),
        syncCoordinatorProvider.overrideWith(_IdleCoordinator.new),
        syncStoreProvider.overrideWithValue(store),
        transactionsRepositoryProvider.overrideWithValue(transactions),
        gmailRepositoryProvider.overrideWithValue(gmail),
        onboardingStoreProvider.overrideWithValue(onboardingStore),
        accountsStoreProvider.overrideWithValue(accounts),
        notificationSourceProvider.overrideWithValue(
          const NoopNotificationSource(),
        ),
        reviewRepositoryProvider.overrideWithValue(review),
        insightsRepositoryProvider.overrideWithValue(insights),
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
        child: const LukaApp(),
      ),
    );
    return container;
  }

  final home = find.byType(DashboardPage);
  final onboarding = find.byType(GmailOnboardingPage);
  final accountsStep = find.byType(AccountsOnboardingPage);

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

  testWidgets('"Ahora no" en cada paso termina en Inicio y el onboarding '
      'no vuelve', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(onboarding, findsOneWidget);

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();
    expect(accountsStep, findsOneWidget);
    verifyNever(() => onboardingStore.markDone(any()));

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();
    expect(home, findsOneWidget);
    verify(() => onboardingStore.markDone('u-1')).called(1);
  });

  testWidgets('con Gmail activo salta ese paso', (tester) async {
    when(() => gmail.status()).thenAnswer(
      (_) async => const GmailConnectionInfo(status: GmailStatus.active),
    );
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(accountsStep, findsOneWidget);
    expect(onboarding, findsNothing);
  });

  testWidgets('con el onboarding terminado abre directo en Inicio', (
    tester,
  ) async {
    when(() => onboardingStore.isDone('u-1')).thenAnswer((_) async => true);
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(home, findsOneWidget);
  });

  testWidgets('sin red muestra el paso de Gmail, que ofrece reintentar', (
    tester,
  ) async {
    when(() => gmail.status()).thenThrow(const GmailNetworkFailure());
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(onboarding, findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('si el estado tarda, muestra el onboarding y no rebota al '
      'llegar', (tester) async {
    final status = Completer<GmailConnectionInfo>();
    when(() => gmail.status()).thenAnswer((_) => status.future);
    final container = await pumpApp(tester);
    await tester.pump();
    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump(OnboardingGateController.timeout);
    await tester.pumpAndSettle();
    expect(onboarding, findsOneWidget);

    status.complete(
      const GmailConnectionInfo(status: GmailStatus.active),
    );
    await tester.pumpAndSettle();
    expect(
      container.read(onboardingGateProvider),
      const OnboardingShow(OnboardingStep.accounts),
    );
    // Sigue en Gmail, que ahora solo ofrece continuar.
    expect(onboarding, findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(home, findsNothing);
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
    when(() => onboardingStore.isDone('u-1')).thenAnswer((_) async => true);
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
