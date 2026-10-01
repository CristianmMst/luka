import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/capture/domain/capture_ports.dart';
import 'package:luka/features/onboarding/presentation/notifications_onboarding_page.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';
import 'onboarding_harness.dart';

class _MockSource extends Mock implements NotificationSource {}

void main() {
  late _MockSource source;
  late StreamController<void> ticks;

  setUp(() {
    source = _MockSource();
    ticks = StreamController<void>.broadcast();
    addTearDown(ticks.close);
    when(() => source.isSupported).thenReturn(true);
    when(() => source.readsNotifications).thenReturn(true);
    when(() => source.isPermissionGranted()).thenAnswer((_) async => false);
    when(() => source.openPermissionSettings()).thenAnswer((_) async {});
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
  }) => pumpOnboardingStep(
    tester,
    themeMode: themeMode,
    location: Routes.onboardingNotifications,
    page: const NotificationsOnboardingPage(),
    overrides: [
      notificationSourceProvider.overrideWithValue(source),
      foregroundTicksProvider.overrideWithValue(ticks.stream),
    ],
  );

  testWidgets('explica qué lee, qué ignora, y el progreso', (tester) async {
    await pumpPage(tester);

    expect(find.text('Registra tus pagos al instante'), findsOneWidget);
    expect(
      find.text('Solo las apps de tus bancos y los SMS que envían tus bancos.'),
      findsOneWidget,
    );
    expect(find.textContaining('Chats, correos y SMS'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('queda registrada sola')), findsOne);
    expect(find.bySemanticsLabel('Paso 2 de 3'), findsOneWidget);
    expect(find.text('Activar acceso'), findsOneWidget);
  });

  testWidgets('"Activar acceso" abre el ajuste del sistema', (tester) async {
    await pumpPage(tester);

    await tapVisible(tester, find.text('Activar acceso'));

    verify(() => source.openPermissionSettings()).called(1);
    expect(find.text('Activar acceso'), findsOneWidget);
  });

  testWidgets('al volver con el acceso concedido ofrece continuar', (
    tester,
  ) async {
    await pumpPage(tester);

    when(() => source.isPermissionGranted()).thenAnswer((_) async => true);
    ticks.add(null);
    await tester.pumpAndSettle();

    expect(
      find.text('Acceso activado. Ya capturamos tus pagos.'),
      findsOneWidget,
    );
    expect(find.text('Activar acceso'), findsNothing);
    await tapVisible(tester, find.text('Continuar'));
    expect(find.text(nextAccounts), findsOneWidget);
  });

  testWidgets('"Ahora no" sigue a Cuentas sin abrir el ajuste', (
    tester,
  ) async {
    await pumpPage(tester);

    await tapVisible(tester, find.widgetWithText(TextButton, 'Ahora no'));

    expect(find.text(nextAccounts), findsOneWidget);
    verifyNever(() => source.openPermissionSettings());
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('notificaciones ${mode.name}', tags: ['golden'], (
        tester,
      ) async {
        await pumpPage(tester, themeMode: mode);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/notifications_onboarding_${mode.name}.png',
          ),
        );
      });
    }
  });
}
