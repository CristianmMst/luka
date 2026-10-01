import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/domain/entities/user.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/capture/data/method_channel_notification_source.dart';
import 'package:luka/features/gmail/application/gmail_controller.dart';
import 'package:luka/features/gmail/domain/gmail_connection.dart';
import 'package:luka/features/gmail/domain/gmail_repository.dart';
import 'package:luka/features/shell/presentation/ajustes_page.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGmail extends Mock implements GmailRepository {}

class _Coordinator extends SyncCoordinator {
  _Coordinator(this._status);

  final SyncStatus _status;

  @override
  SyncStatus build() => _status;
}

class _FixedAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const Authenticated(
    User(
      id: 'u-1',
      email: 'ana.gomez@gmail.com',
      displayName: 'Ana Gómez',
      status: UserStatus.active,
    ),
  );
}

void main() {
  late _MockGmail gmail;

  setUp(() {
    gmail = _MockGmail();
    when(() => gmail.status()).thenAnswer(
      (_) async => const GmailConnectionInfo(
        status: GmailStatus.active,
        email: 'ana.gomez@gmail.com',
      ),
    );
  });

  Future<void> pumpAjustes(
    WidgetTester tester, {
    SyncStatus sync = const SyncStatus(),
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpApp(
      const AjustesPage(),
      themeMode: themeMode,
      overrides: [
        authControllerProvider.overrideWith(_FixedAuthController.new),
        gmailRepositoryProvider.overrideWithValue(gmail),
        syncCoordinatorProvider.overrideWith(() => _Coordinator(sync)),
        notificationSourceProvider.overrideWithValue(
          const NoopNotificationSource(),
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la tarjeta muestra el perfil y la línea de sync', (
    tester,
  ) async {
    await pumpAjustes(tester);

    expect(find.text('TU CUENTA LUKA'), findsOneWidget);
    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('ana.gomez@gmail.com'), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp('Ver sincronización')),
      findsWidgets,
    );
  });

  testWidgets('las filas van agrupadas por tema', (tester) async {
    await pumpAjustes(tester);

    expect(find.text('CAPTURA AUTOMÁTICA'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('TUS DATOS'), 200);
    expect(find.text('TUS DATOS'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('PRIVACIDAD'), 200);
    expect(find.text('PRIVACIDAD'), findsOneWidget);
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ajustes ${mode.name}', tags: ['golden'], (tester) async {
        await pumpAjustes(tester, themeMode: mode);
        await expectLater(
          find.byType(AjustesPage),
          matchesGoldenFile('goldens/ajustes_${mode.name}.png'),
        );
      });
    }
  });
}
