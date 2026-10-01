import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/auth/presentation/splash_page.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('muestra la marca y el progreso', (tester) async {
    await tester.pumpApp(const SplashPage());
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('splash ${mode.name}', tags: ['golden'], (tester) async {
        await tester.pumpApp(const SplashPage(), themeMode: mode);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/splash_${mode.name}.png'),
        );
      });
    }
  });
}
