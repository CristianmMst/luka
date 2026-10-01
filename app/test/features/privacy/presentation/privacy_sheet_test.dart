import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/privacy/application/privacy_actions.dart';
import 'package:luka/features/privacy/domain/privacy_ports.dart';
import 'package:luka/features/privacy/presentation/privacy_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _Actions extends Mock implements PrivacyActions {}

void main() {
  late _Actions actions;

  setUp(() {
    actions = _Actions();
    when(() => actions.exportData()).thenAnswer((_) async {});
    when(() => actions.deleteAccount()).thenAnswer((_) async {});
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpApp(
      const Scaffold(body: PrivacySheet()),
      themeMode: themeMode,
      overrides: [privacyActionsProvider.overrideWithValue(actions)],
    );
    await tester.pumpAndSettle();
  }

  Finder deleteButton() =>
      find.widgetWithText(FilledButton, 'Borrar para siempre');

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('lista lo que se borra y exige escribir BORRAR', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Tus movimientos y sus fuentes'), findsOneWidget);
    expect(find.text('La conexión con Gmail'), findsOneWidget);
    expect(tester.widget<FilledButton>(deleteButton()).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'borra');
    await tester.pump();
    expect(tester.widget<FilledButton>(deleteButton()).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'borrar');
    await tester.pump();
    await tapVisible(tester, deleteButton());

    verify(() => actions.deleteAccount()).called(1);
  });

  testWidgets('exportar y "Exportar mis datos antes" descargan', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tapVisible(tester, find.text('Exportar mis datos'));
    await tapVisible(tester, find.text('Exportar mis datos antes'));

    verify(() => actions.exportData()).called(2);
    verifyNever(() => actions.deleteAccount());
  });

  testWidgets('sin conexión lo dice y no cierra', (tester) async {
    when(() => actions.deleteAccount()).thenThrow(const PrivacyOffline());
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), 'BORRAR');
    await tester.pump();
    await tapVisible(tester, deleteButton());

    expect(
      find.text('Necesitas conexión para exportar o borrar tu cuenta.'),
      findsOneWidget,
    );
    expect(find.byType(PrivacySheet), findsOneWidget);
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('privacidad ${mode.name}', tags: ['golden'], (tester) async {
        await pumpSheet(tester, themeMode: mode);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/privacy_sheet_${mode.name}.png'),
        );
      });
    }
  });
}
