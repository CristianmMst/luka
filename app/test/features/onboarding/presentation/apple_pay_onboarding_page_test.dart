import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/capture/domain/capture_ports.dart';
import 'package:luka/features/onboarding/presentation/apple_pay_onboarding_page.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';
import 'onboarding_harness.dart';

class _MockSource extends Mock implements NotificationSource {}

void main() {
  late _MockSource source;

  setUp(() {
    source = _MockSource();
    // iOS: cola de Apple Pay, sin listener de notificaciones.
    when(() => source.isSupported).thenReturn(true);
    when(() => source.readsNotifications).thenReturn(false);
    when(() => source.openPermissionSettings()).thenAnswer((_) async {});
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    bool inOnboarding = true,
    ThemeMode themeMode = ThemeMode.light,
  }) => pumpOnboardingStep(
    tester,
    themeMode: themeMode,
    location: Routes.onboardingApplePay,
    page: ApplePayOnboardingPage(inOnboarding: inOnboarding),
    overrides: [
      notificationSourceProvider.overrideWithValue(source),
      foregroundTicksProvider.overrideWithValue(const Stream.empty()),
    ],
  );

  testWidgets('guía los tres pasos del Atajo y el progreso', (tester) async {
    await pumpPage(tester);

    expect(find.text('Registra tus pagos con Apple Pay'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('^Paso 1: Abre Atajos')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('^Paso 3: Agrega')), findsOneWidget);
    expect(find.textContaining('«Bancolombia 1234»'), findsOneWidget);
    expect(find.bySemanticsLabel('Paso 2 de 3'), findsOneWidget);
  });

  testWidgets('"Abrir Atajos" abre la app y "Continuar" sigue a Cuentas', (
    tester,
  ) async {
    await pumpPage(tester);

    await tapVisible(tester, find.text('Abrir Atajos'));
    verify(() => source.openPermissionSettings()).called(1);

    await tapVisible(tester, find.text('Continuar'));
    expect(find.text(nextAccounts), findsOneWidget);
  });

  testWidgets('si Atajos no abre lo avisa', (tester) async {
    when(
      () => source.openPermissionSettings(),
    ).thenThrow(PlatformException(code: 'unavailable'));
    await pumpPage(tester);

    await tapVisible(tester, find.text('Abrir Atajos'));

    expect(
      find.text('No se pudo abrir Atajos. Búscala en tu iPhone.'),
      findsOneWidget,
    );
  });

  testWidgets('desde Ajustes no hay progreso ni "Continuar"', (tester) async {
    await pumpPage(tester, inOnboarding: false);

    expect(find.bySemanticsLabel('Paso 2 de 3'), findsNothing);
    expect(find.text('Continuar'), findsNothing);
    expect(find.byTooltip('Atrás'), findsOneWidget);
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('apple pay ${mode.name}', tags: ['golden'], (tester) async {
        await pumpPage(tester, themeMode: mode);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/apple_pay_onboarding_${mode.name}.png'),
        );
      });
    }
  });
}
