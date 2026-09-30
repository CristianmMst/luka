import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/app_theme.dart';

extension PumpApp on WidgetTester {
  /// Monta [child] con tema, l10n y los overrides dados, en un teléfono de
  /// 390×844 (el tamaño del canvas de diseño).
  Future<void> pumpApp(
    Widget child, {
    List<Override> overrides = const [],
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    view
      ..physicalSize = const Size(390, 844) * 3
      ..devicePixelRatio = 3;
    addTearDown(view.reset);
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: const Locale('es', 'CO'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: child,
        ),
      ),
    );
  }
}

/// Carga las fuentes de la marca para que los goldens se parezcan a la app
/// (por defecto los tests usan Ahem).
Future<void> loadBrandFonts() async {
  const families = {
    'BricolageGrotesque': ['BricolageGrotesque-500', 'BricolageGrotesque-700'],
    'Manrope': ['Manrope-400', 'Manrope-500', 'Manrope-600', 'Manrope-700'],
    'IBMPlexMono': ['IBMPlexMono-500', 'IBMPlexMono-600'],
    'Roboto': ['Roboto-500'],
  };
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load('assets/fonts/$file.ttf'));
    }
    await loader.load();
  }

  // Íconos Material desde el SDK (flutter test define FLUTTER_ROOT).
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (flutterRoot != null && icons.existsSync()) {
    final bytes = await icons.readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}
