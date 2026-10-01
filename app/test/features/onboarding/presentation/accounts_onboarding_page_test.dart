import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/domain/entities/user.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/capture/data/method_channel_notification_source.dart';
import 'package:luka/features/onboarding/application/onboarding_gate.dart';
import 'package:luka/features/onboarding/domain/onboarding_store.dart';
import 'package:luka/features/onboarding/presentation/accounts_onboarding_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';
import 'onboarding_harness.dart';

class _MockAccounts extends Mock implements AccountsStore {}

class _MockOnboarding extends Mock implements OnboardingStore {}

class _FixedAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const Authenticated(_ana);
}

const _ana = User(
  id: 'u-1',
  email: 'ana@example.com',
  status: UserStatus.active,
);

const _nomina = LinkedAccount(
  id: 'a-1',
  bank: 'bancolombia',
  kind: 'savings',
  last4: '4821',
  alias: 'Nómina',
  transactionCount: 0,
);

void main() {
  late _MockAccounts accounts;
  late _MockOnboarding onboarding;

  setUp(() {
    accounts = _MockAccounts();
    onboarding = _MockOnboarding();
    when(() => onboarding.isDone(any())).thenAnswer((_) async => false);
    when(() => onboarding.markDone(any())).thenAnswer((_) async {});
  });

  Future<void> pumpPage(
    WidgetTester tester,
    List<LinkedAccount> all, {
    ThemeMode themeMode = ThemeMode.light,
  }) {
    when(() => accounts.watchAll()).thenAnswer((_) => Stream.value(all));
    return pumpOnboardingStep(
      tester,
      themeMode: themeMode,
      location: Routes.onboardingAccounts,
      page: const AccountsOnboardingPage(),
      overrides: [
        authControllerProvider.overrideWith(_FixedAuthController.new),
        accountsStoreProvider.overrideWithValue(accounts),
        onboardingStoreProvider.overrideWithValue(onboarding),
        notificationSourceProvider.overrideWithValue(
          const NoopNotificationSource(),
        ),
      ],
    );
  }

  testWidgets('sin cuentas explica para qué sirven y deja saltar', (
    tester,
  ) async {
    await pumpPage(tester, const []);

    expect(find.text('¿Qué cuentas tienes?'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('transferencia propia')),
      findsOneWidget,
    );
    expect(find.text('Agregar cuenta'), findsOneWidget);
    expect(find.text('Listo'), findsNothing);
    // En iOS (sin notificaciones) son dos pasos.
    expect(find.bySemanticsLabel('Paso 2 de 2'), findsOneWidget);

    await tapVisible(tester, find.text('Ahora no'));

    verify(() => onboarding.markDone('u-1')).called(1);
    expect(find.text(nextHome), findsOneWidget);
  });

  testWidgets('con cuentas las lista y "Listo" termina', (tester) async {
    await pumpPage(tester, const [_nomina]);

    expect(find.text('Nómina'), findsOneWidget);
    expect(find.text('Bancolombia · Ahorros ···4821'), findsOneWidget);
    expect(find.byTooltip('Editar Nómina'), findsOneWidget);
    expect(find.byTooltip('Borrar Nómina'), findsNothing);

    await tapVisible(tester, find.text('Listo'));

    verify(() => onboarding.markDone('u-1')).called(1);
    expect(find.text(nextHome), findsOneWidget);
  });

  testWidgets('"Agregar cuenta" abre la hoja de Mis cuentas', (tester) async {
    await pumpPage(tester, const []);

    await tapVisible(tester, find.text('Agregar cuenta'));

    expect(find.text('Nueva cuenta'), findsOneWidget);
    expect(find.text('Elige tu banco'), findsOneWidget);
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('cuentas ${mode.name}', tags: ['golden'], (tester) async {
        await pumpPage(tester, const [], themeMode: mode);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/accounts_onboarding_${mode.name}.png'),
        );
      });
    }
  });
}
