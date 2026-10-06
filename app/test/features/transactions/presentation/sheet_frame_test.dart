import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/theme/app_theme.dart';
import 'package:luka/features/transactions/presentation/widgets/sheet_frame.dart';

void main() {
  testWidgets('la hoja se abre sobre la barra del shell, no dentro de la '
      'pestaña', (tester) async {
    // Como el shell: cada pestaña tiene su Navigator y la barra va encima.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          extendBody: true,
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showLukaSheet<void>(
                    context,
                    builder: (_) => const SizedBox(
                      height: 200,
                      child: Text('hoja'),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
          bottomNavigationBar: const SizedBox(
            height: 80,
            child: Text('barra'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(of: find.text('hoja'), matching: find.byType(Navigator)),
      findsOneWidget,
    );
  });

  group('tirar hacia abajo en el tope cierra la hoja', () {
    /// Hoja con un formulario más alto que la pantalla (el caso de "Editar
    /// gasto fijo"): su scroll se quedaba con el arrastre y no cerraba.
    Future<void> openTallSheet(
      WidgetTester tester, {
      bool autofocus = false,
    }) async {
      tester.view
        ..physicalSize = const Size(390, 600) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showLukaSheet<void>(
                    context,
                    builder: (_) => SingleChildScrollView(
                      child: Column(
                        children: [
                          const SheetHandle(),
                          const Text('titulo'),
                          TextField(autofocus: autofocus),
                          for (var i = 0; i < 30; i++)
                            SizedBox(height: 48, child: Text('fila $i')),
                        ],
                      ),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('titulo'), findsOneWidget);
    }

    testWidgets('con scroll, arrastrar hacia abajo la cierra', (tester) async {
      await openTallSheet(tester);

      await tester.drag(find.text('titulo'), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.text('titulo'), findsNothing);
    });

    testWidgets('con el teclado abierto también la cierra', (tester) async {
      await openTallSheet(tester, autofocus: true);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await tester.pumpAndSettle();

      await tester.drag(find.text('titulo'), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.text('titulo'), findsNothing);
    });

    testWidgets('a mitad del scroll, arrastrar hacia abajo solo hace scroll', (
      tester,
    ) async {
      await openTallSheet(tester);
      await tester.drag(find.text('fila 5'), const Offset(0, -400));
      await tester.pumpAndSettle();

      await tester.drag(find.text('fila 12'), const Offset(0, 150));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('un tirón corto en el tope no la cierra', (tester) async {
      await openTallSheet(tester);

      await tester.drag(find.text('titulo'), const Offset(0, 30));
      await tester.pumpAndSettle();

      expect(find.text('titulo'), findsOneWidget);
    });
  });
}
