import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/app_theme.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/domain/entities/user.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/capture/data/method_channel_notification_source.dart';
import 'package:luka/features/gmail/application/gmail_controller.dart';
import 'package:luka/features/gmail/domain/gmail_connection.dart';
import 'package:luka/features/gmail/domain/gmail_failure.dart';
import 'package:luka/features/gmail/domain/gmail_repository.dart';
import 'package:luka/features/gmail/presentation/gmail_onboarding_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGmail extends Mock implements GmailRepository {}

class _FixedAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const Authenticated(_ana);
}

const _ana = User(
  id: 'u-1',
  email: 'ana@example.com',
  status: UserStatus.active,
);

const _active = GmailConnectionInfo(
  status: GmailStatus.active,
  email: 'ana@gmail.com',
);

/// El paso que sigue a Gmail: sin notificaciones (iOS), Cuentas.
const _next = 'CUENTAS';

void main() {
  late _MockGmail gmail;

  setUp(() {
    gmail = _MockGmail();
    when(
      () => gmail.status(),
    ).thenAnswer((_) async => GmailConnectionInfo.disconnected);
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: Routes.onboardingGmail,
      routes: [
        GoRoute(
          path: Routes.onboardingGmail,
          builder: (_, _) => const GmailOnboardingPage(),
        ),
        GoRoute(
          path: Routes.onboardingAccounts,
          builder: (_, _) => const Scaffold(body: Text(_next)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FixedAuthController.new),
          gmailRepositoryProvider.overrideWithValue(gmail),
          notificationSourceProvider.overrideWithValue(
            const NoopNotificationSource(),
          ),
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

  Finder connectButton() => find.byType(FilledButton);
  Finder notNowButton() => find.widgetWithText(TextButton, 'Ahora no');

  testWidgets('explica qué lee, qué no y ofrece "Ahora no"', (tester) async {
    await pumpPage(tester);

    expect(find.text('Conecta tu Gmail'), findsOneWidget);
    expect(
      find.text('Correos de alertas de tus bancos (Bancolombia, Nequi…).'),
      findsOneWidget,
    );
    expect(
      find.text('Tu correo personal, contactos ni adjuntos.'),
      findsOneWidget,
    );
    expect(
      find.text('Tus compras quedan registradas solas, sin duplicados.'),
      findsOneWidget,
    );
    expect(find.text('Conectar Gmail'), findsOneWidget);
    expect(notNowButton(), findsOneWidget);
    expect(find.textContaining('desde Ajustes'), findsOneWidget);
    // Áreas táctiles de 48 dp o más.
    expect(tester.getSize(connectButton()).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(notNowButton()).height, greaterThanOrEqualTo(48));
  });

  testWidgets('conectar abre el consentimiento y sigue al próximo paso', (
    tester,
  ) async {
    when(() => gmail.connect()).thenAnswer((_) async => _active);
    await pumpPage(tester);

    await tester.tap(connectButton());
    await tester.pumpAndSettle();

    verify(() => gmail.connect()).called(1);
    expect(find.text(_next), findsOneWidget);
  });

  for (final status in [GmailStatus.error, GmailStatus.revoked]) {
    testWidgets('conectado con ${status.name}: avisa y sigue al próximo paso', (
      tester,
    ) async {
      when(() => gmail.connect()).thenAnswer(
        (_) async =>
            GmailConnectionInfo(status: status, email: 'ana@gmail.com'),
      );
      await pumpPage(tester);

      await tester.tap(connectButton());
      await tester.pump();
      await tester.pump();

      expect(find.text(_next), findsOneWidget);
      expect(
        find.text(
          'Conectado, pero no pudimos activar la captura; '
          'reintenta desde Ajustes.',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('conectado y activo: sin aviso', (tester) async {
    when(() => gmail.connect()).thenAnswer((_) async => _active);
    await pumpPage(tester);

    await tester.tap(connectButton());
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('mientras conecta bloquea los botones', (tester) async {
    final pending = Completer<GmailConnectionInfo>();
    when(() => gmail.connect()).thenAnswer((_) => pending.future);
    await pumpPage(tester);

    await tester.tap(connectButton());
    await tester.pump();

    expect(find.text('Conectando Gmail…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(connectButton()).onPressed, isNull);
    expect(tester.widget<TextButton>(notNowButton()).onPressed, isNull);
    await tester.tap(connectButton());
    verify(() => gmail.connect()).called(1);

    pending.complete(_active);
    await tester.pumpAndSettle();
    expect(find.text(_next), findsOneWidget);
  });

  testWidgets('cancelar el consentimiento se queda en la página sin aviso', (
    tester,
  ) async {
    when(() => gmail.connect()).thenThrow(const GmailConsentCancelled());
    await pumpPage(tester);

    await tester.tap(connectButton());
    await tester.pumpAndSettle();

    expect(find.text('Conecta tu Gmail'), findsOneWidget);
    expect(find.text('Conectar Gmail'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    expect(find.text(_next), findsNothing);
  });

  final failures = <(String, GmailFailure, String)>[
    (
      'sin red',
      const GmailNetworkFailure(),
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
    ),
    (
      'rechazo del servidor',
      const GmailCodeRejected(),
      'Google no aceptó la autorización. Inténtalo de nuevo.',
    ),
    (
      'sin refresh token',
      const GmailRefreshTokenMissing(),
      'Google no aceptó la autorización. Inténtalo de nuevo.',
    ),
    (
      'Google no disponible',
      const GmailUpstreamUnavailable(),
      'No pudimos hablar con Google. Inténtalo de nuevo en unos minutos.',
    ),
    (
      'permiso desmarcado',
      const GmailScopeDenied(),
      'Para conectar Gmail, marca el permiso de lectura de correos en la '
          'pantalla de Google.',
    ),
    (
      'demasiados intentos',
      const GmailRateLimited(),
      'Hiciste muchos intentos seguidos. Espera un momento y vuelve a '
          'intentarlo.',
    ),
    (
      'inesperado',
      const GmailUnexpected(),
      'No pudimos conectar Gmail. Inténtalo de nuevo.',
    ),
    (
      'inesperado con código de la plataforma',
      const GmailUnexpected(null, 'uiUnavailable'),
      'No pudimos conectar Gmail. Inténtalo de nuevo. (código: uiUnavailable)',
    ),
  ];

  for (final (name, failure, message) in failures) {
    testWidgets('$name: aviso y botón de reintentar', (tester) async {
      when(() => gmail.connect()).thenThrow(failure);
      await pumpPage(tester);

      await tester.tap(connectButton());
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text(_next), findsNothing);
    });
  }

  testWidgets('sin configurar: avisa (con el detalle en debug)', (
    tester,
  ) async {
    when(
      () => gmail.connect(),
    ).thenThrow(const GmailMisconfigured('sin client id'));
    await pumpPage(tester);

    await tester.tap(connectButton());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('La conexión con Gmail no está configurada'),
      findsOneWidget,
    );
  });

  testWidgets('reintentar tras un rechazo conecta y sigue al próximo paso', (
    tester,
  ) async {
    var calls = 0;
    when(() => gmail.connect()).thenAnswer((_) async {
      if (calls++ == 0) throw const GmailCodeRejected();
      return _active;
    });
    await pumpPage(tester);

    await tester.tap(connectButton());
    await tester.pumpAndSettle();
    await tester.tap(connectButton());
    await tester.pumpAndSettle();

    expect(find.text(_next), findsOneWidget);
  });

  testWidgets('"Ahora no" sigue al próximo paso sin conectar', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(notNowButton());
    await tester.pumpAndSettle();

    verifyNever(() => gmail.connect());
    expect(find.text(_next), findsOneWidget);
  });

  testWidgets('con Gmail ya activo solo ofrece continuar', (tester) async {
    when(() => gmail.status()).thenAnswer((_) async => _active);
    await pumpPage(tester);

    expect(find.text('Conectar Gmail'), findsNothing);
    expect(notNowButton(), findsNothing);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    verifyNever(() => gmail.connect());
    expect(find.text(_next), findsOneWidget);
  });

  testWidgets('sin poder leer el estado: avisa y reintenta leerlo', (
    tester,
  ) async {
    when(() => gmail.status()).thenThrow(const GmailNetworkFailure());
    await pumpPage(tester);

    expect(
      find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'),
      findsOneWidget,
    );
    when(() => gmail.status()).thenAnswer(
      (_) async => GmailConnectionInfo.disconnected,
    );
    await tester.tap(connectButton());
    await tester.pumpAndSettle();

    verify(() => gmail.status()).called(2);
    verifyNever(() => gmail.connect());
    expect(find.text('Conectar Gmail'), findsOneWidget);
  });

  testWidgets('mientras lee el estado, conectar espera', (tester) async {
    final pending = Completer<GmailConnectionInfo>();
    when(() => gmail.status()).thenAnswer((_) => pending.future);
    await pumpPage(tester);

    expect(tester.widget<FilledButton>(connectButton()).onPressed, isNull);
    pending.complete(GmailConnectionInfo.disconnected);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(connectButton()).onPressed, isNotNull);
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('onboarding gmail ${mode.name}', tags: ['golden'], (
        tester,
      ) async {
        await pumpPage(tester, themeMode: mode);
        await expectLater(
          find.byType(GmailOnboardingPage),
          matchesGoldenFile('goldens/gmail_onboarding_${mode.name}.png'),
        );
      });
    }
  });
}
