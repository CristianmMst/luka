import 'dart:async';

import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/routing/routes.dart';
import 'package:finanzia/core/theme/app_theme.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/gmail/application/gmail_controller.dart';
import 'package:finanzia/features/gmail/domain/gmail_connection.dart';
import 'package:finanzia/features/gmail/domain/gmail_failure.dart';
import 'package:finanzia/features/gmail/domain/gmail_prompt_store.dart';
import 'package:finanzia/features/gmail/domain/gmail_repository.dart';
import 'package:finanzia/features/gmail/presentation/gmail_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGmail extends Mock implements GmailRepository {}

class _MockPrompts extends Mock implements GmailPromptStore {}

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

const _inicio = 'INICIO';

void main() {
  late _MockGmail gmail;
  late _MockPrompts prompts;

  setUp(() {
    gmail = _MockGmail();
    prompts = _MockPrompts();
    when(
      () => gmail.status(),
    ).thenAnswer((_) async => GmailConnectionInfo.disconnected);
    when(() => prompts.isDismissed(any())).thenAnswer((_) async => false);
    when(() => prompts.dismiss(any())).thenAnswer((_) async {});
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
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text(_inicio)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FixedAuthController.new),
          gmailRepositoryProvider.overrideWithValue(gmail),
          gmailPromptStoreProvider.overrideWithValue(prompts),
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

  testWidgets('conectar abre el consentimiento y lleva a Inicio', (
    tester,
  ) async {
    when(() => gmail.connect()).thenAnswer((_) async => _active);
    await pumpPage(tester);

    await tester.tap(connectButton());
    await tester.pumpAndSettle();

    verify(() => gmail.connect()).called(1);
    expect(find.text(_inicio), findsOneWidget);
  });

  for (final status in [GmailStatus.error, GmailStatus.revoked]) {
    testWidgets('conectado con ${status.name}: avisa y lleva a Inicio', (
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

      expect(find.text(_inicio), findsOneWidget);
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
    expect(find.text(_inicio), findsOneWidget);
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
    expect(find.text(_inicio), findsNothing);
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
  ];

  for (final (name, failure, message) in failures) {
    testWidgets('$name: aviso y botón de reintentar', (tester) async {
      when(() => gmail.connect()).thenThrow(failure);
      await pumpPage(tester);

      await tester.tap(connectButton());
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text(_inicio), findsNothing);
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

  testWidgets('reintentar tras un rechazo conecta y lleva a Inicio', (
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

    expect(find.text(_inicio), findsOneWidget);
  });

  testWidgets('"Ahora no" lo recuerda para el usuario y lleva a Inicio', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(notNowButton());
    await tester.pumpAndSettle();

    verify(() => prompts.dismiss('u-1')).called(1);
    verifyNever(() => gmail.connect());
    expect(find.text(_inicio), findsOneWidget);
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
