import 'dart:async';

import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/capture/application/capture_flusher.dart';
import 'package:finanzia/features/capture/data/method_channel_notification_source.dart';
import 'package:finanzia/features/gmail/application/gmail_controller.dart';
import 'package:finanzia/features/gmail/domain/gmail_connection.dart';
import 'package:finanzia/features/gmail/domain/gmail_failure.dart';
import 'package:finanzia/features/gmail/domain/gmail_repository.dart';
import 'package:finanzia/features/gmail/presentation/widgets/gmail_disconnect_dialog.dart';
import 'package:finanzia/features/shell/presentation/ajustes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  late _MockGmail gmail;

  setUp(() {
    gmail = _MockGmail();
    when(() => gmail.status()).thenAnswer((_) async => _active);
  });

  Future<void> pumpAjustes(WidgetTester tester) async {
    await tester.pumpApp(
      const AjustesPage(),
      overrides: [
        authControllerProvider.overrideWith(_FixedAuthController.new),
        gmailRepositoryProvider.overrideWithValue(gmail),
        notificationSourceProvider.overrideWithValue(
          const NoopNotificationSource(),
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  Finder action(String label) => find.widgetWithText(TextButton, label);

  testWidgets('conectado muestra la cuenta y conserva cerrar sesión', (
    tester,
  ) async {
    await pumpAjustes(tester);

    expect(find.text('Gmail'), findsOneWidget);
    expect(find.text('Conectado · ana@gmail.com'), findsOneWidget);
    expect(action('Desconectar'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('la acción mide 48 dp o más y dice qué hace', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpAjustes(tester);

    expect(
      tester.getSize(action('Desconectar')).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.bySemanticsLabel('Desconectar Gmail'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('desconectar pide confirmación; cancelar no hace nada', (
    tester,
  ) async {
    await pumpAjustes(tester);

    await tester.tap(action('Desconectar'));
    await tester.pumpAndSettle();
    expect(find.byType(GmailDisconnectDialog), findsOneWidget);
    expect(find.text('¿Desconectar Gmail?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(GmailDisconnectDialog), findsNothing);
    verifyNever(() => gmail.disconnect());
    expect(find.text('Conectado · ana@gmail.com'), findsOneWidget);
  });

  testWidgets('confirmar desconecta y ofrece conectar', (tester) async {
    when(() => gmail.disconnect()).thenAnswer((_) async {});
    await pumpAjustes(tester);

    await tester.tap(action('Desconectar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(GmailDisconnectDialog),
        matching: find.widgetWithText(FilledButton, 'Desconectar'),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => gmail.disconnect()).called(1);
    expect(
      find.text('Sin conectar · tus compras por correo no se registran'),
      findsOneWidget,
    );
    expect(action('Conectar'), findsOneWidget);
  });

  testWidgets('un fallo al desconectar se avisa y deja la conexión', (
    tester,
  ) async {
    when(() => gmail.disconnect()).thenThrow(const GmailNetworkFailure());
    await pumpAjustes(tester);

    await tester.tap(action('Desconectar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Desconectar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Conectado · ana@gmail.com'), findsOneWidget);
  });

  for (final (status, message) in [
    (
      GmailStatus.revoked,
      'Google quitó el permiso. Reconecta para seguir capturando.',
    ),
    (
      GmailStatus.error,
      'La captura de correos se detuvo. Reconecta para reanudarla.',
    ),
  ]) {
    testWidgets('${status.name} ofrece reconectar', (tester) async {
      when(
        () => gmail.status(),
      ).thenAnswer((_) async => GmailConnectionInfo(status: status));
      when(() => gmail.connect()).thenAnswer((_) async => _active);
      await pumpAjustes(tester);

      expect(find.text(message), findsOneWidget);
      await tester.tap(action('Reconectar'));
      await tester.pumpAndSettle();

      verify(() => gmail.connect()).called(1);
      expect(find.text('Conectado · ana@gmail.com'), findsOneWidget);
    });
  }

  testWidgets('desconectado ofrece conectar; mientras conecta, espera', (
    tester,
  ) async {
    when(
      () => gmail.status(),
    ).thenAnswer((_) async => GmailConnectionInfo.disconnected);
    final pending = Completer<GmailConnectionInfo>();
    when(() => gmail.connect()).thenAnswer((_) => pending.future);
    await pumpAjustes(tester);

    await tester.tap(action('Conectar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(action('Conectar'), findsNothing);

    pending.complete(_active);
    await tester.pumpAndSettle();
    expect(find.text('Conectado · ana@gmail.com'), findsOneWidget);
  });

  testWidgets('un rechazo al conectar se avisa', (tester) async {
    when(
      () => gmail.status(),
    ).thenAnswer((_) async => GmailConnectionInfo.disconnected);
    when(() => gmail.connect()).thenThrow(const GmailCodeRejected());
    await pumpAjustes(tester);

    await tester.tap(action('Conectar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Google no aceptó la autorización. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(action('Conectar'), findsOneWidget);
  });

  testWidgets('cancelar el consentimiento no avisa nada', (tester) async {
    when(
      () => gmail.status(),
    ).thenAnswer((_) async => GmailConnectionInfo.disconnected);
    when(() => gmail.connect()).thenThrow(const GmailConsentCancelled());
    await pumpAjustes(tester);

    await tester.tap(action('Conectar'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    expect(action('Conectar'), findsOneWidget);
  });

  testWidgets('conectado sin email muestra solo el estado', (tester) async {
    when(() => gmail.status()).thenAnswer(
      (_) async => const GmailConnectionInfo(status: GmailStatus.active),
    );
    await pumpAjustes(tester);

    expect(find.text('Conectado'), findsOneWidget);
  });

  testWidgets('cargando muestra que consulta', (tester) async {
    final pending = Completer<GmailConnectionInfo>();
    when(() => gmail.status()).thenAnswer((_) => pending.future);
    await tester.pumpApp(
      const AjustesPage(),
      overrides: [
        authControllerProvider.overrideWith(_FixedAuthController.new),
        gmailRepositoryProvider.overrideWithValue(gmail),
        notificationSourceProvider.overrideWithValue(
          const NoopNotificationSource(),
        ),
      ],
    );
    await tester.pump();

    expect(find.text('Consultando Gmail…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(_active);
    await tester.pumpAndSettle();
  });

  testWidgets('sin poder consultar el estado ofrece reintentar', (
    tester,
  ) async {
    when(() => gmail.status()).thenThrow(const GmailUpstreamUnavailable());
    await pumpAjustes(tester);

    expect(
      find.text('No pudimos consultar el estado de Gmail.'),
      findsOneWidget,
    );
    when(() => gmail.status()).thenAnswer((_) async => _active);
    await tester.tap(action('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Conectado · ana@gmail.com'), findsOneWidget);
  });
}
