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
}
