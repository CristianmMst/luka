import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/app_theme.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/review/application/review_providers.dart';
import 'package:luka/features/review/domain/review_item.dart';
import 'package:luka/features/review/domain/review_repository.dart';
import 'package:luka/features/review/presentation/review_page.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';
import 'review_fixtures.dart';

class _Repository extends Mock implements ReviewRepository {}

void main() {
  late _Repository repository;
  late List<ReviewItem> rows;

  setUp(() {
    repository = _Repository();
    rows = [emailItem, notificationItem, purgedItem];
    when(
      () => repository.watchOpen(),
    ).thenAnswer((_) => Stream.value(rows));
  });

  List<Override> overrides(SyncStatus status) => [
    reviewRepositoryProvider.overrideWithValue(repository),
    authControllerProvider.overrideWith(SignedInAuth.new),
    syncCoordinatorProvider.overrideWith(() => FixedCoordinator(status)),
  ];

  Future<void> pumpPage(
    WidgetTester tester, {
    SyncStatus status = const SyncStatus(),
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpApp(
      const ReviewPage(),
      overrides: overrides(status),
      themeMode: themeMode,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cada tarjeta muestra origen, fecha, motivo y extracto', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Revisión'), findsOneWidget);
    expect(find.text('3 mensajes por revisar'), findsOneWidget);

    expect(find.text('Bancolombia'), findsOneWidget);
    expect(find.text('23 sep · 12:41'), findsOneWidget);
    expect(find.text('No reconocimos el formato'), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
    expect(
      find.textContaining('a EXITO CALLE 80', findRichText: true),
      findsOneWidget,
    );

    expect(find.text('Nequi'), findsOneWidget);
    expect(find.text('22 sep · 18:30'), findsOneWidget);
    expect(find.text('La lectura no fue confiable'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // Sin banco se ve el remitente; un motivo desconocido, el genérico.
    expect(find.text('891333'), findsOneWidget);
    expect(find.text('Necesita tu ayuda'), findsOneWidget);
    expect(
      find.text('El texto de este mensaje ya no está disponible.'),
      findsOneWidget,
    );
  });

  testWidgets('el extracto resalta los montos y no los teléfonos', (
    tester,
  ) async {
    rows = [emailItem];
    await pumpPage(tester);

    final text = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('EXITO'),
      ),
    );
    final highlighted = <String>[];
    text.text.visitChildren((span) {
      if (span is TextSpan && span.style?.backgroundColor != null) {
        highlighted.add(span.text!);
      }
      return true;
    });
    expect(highlighted, [r'$126.400', r'$1.254.300,50']);
  });

  testWidgets('la tarjeta se anuncia como un botón con su resumen', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    rows = [notificationItem];
    await pumpPage(tester);

    expect(
      find.bySemanticsLabel(
        RegExp(
          r'^Revisar mensaje de Nequi, 22 sep · 18:30\. La lectura no fue '
          r'confiable\. Pagaste \$38\.900',
        ),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('las áreas táctiles y el contraste cumplen', (tester) async {
    await pumpPage(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('sin mensajes: "Nada por revisar"', (tester) async {
    rows = [];
    await pumpPage(tester);

    expect(find.text('Nada por revisar'), findsOneWidget);
    expect(find.text('Todo al día'), findsOneWidget);
  });

  testWidgets('sin conexión muestra el aviso sobre la lista', (tester) async {
    await pumpPage(tester, status: const SyncStatus(offline: true));

    expect(find.text('Sin conexión · ves tus datos guardados'), findsOneWidget);
    expect(find.text('Bancolombia'), findsOneWidget);
  });

  testWidgets('un error de la base local ofrece reintentar', (tester) async {
    var broken = true;
    when(() => repository.watchOpen()).thenAnswer(
      (_) => broken ? Stream.error(StateError('db')) : Stream.value(rows),
    );
    await pumpPage(tester);

    expect(
      find.text('No pudimos cargar los mensajes por revisar.'),
      findsOneWidget,
    );
    broken = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Bancolombia'), findsOneWidget);
  });

  testWidgets('tocar una tarjeta abre su detalle', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/revision',
      routes: [
        GoRoute(
          path: '/revision',
          builder: (_, _) => const ReviewPage(),
          routes: [
            GoRoute(
              path: ':rawMessageId',
              builder: (_, state) =>
                  Text('detalle ${state.pathParameters['rawMessageId']}'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(const SyncStatus()),
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('es', 'CO'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nequi'));
    await tester.pumpAndSettle();

    expect(find.text('detalle m-notif'), findsOneWidget);
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('lista ${mode.name}', tags: ['golden'], (tester) async {
        await pumpPage(tester, themeMode: mode);
        await expectLater(
          find.byType(ReviewPage),
          matchesGoldenFile('goldens/review_list_${mode.name}.png'),
        );
      });
    }
  });
}
