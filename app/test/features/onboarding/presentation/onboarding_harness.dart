import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/app_theme.dart';

/// Texto de las pantallas de relleno a donde lleva cada paso.
const nextAccounts = 'PASO CUENTAS';
const nextHome = 'INICIO';

/// Monta [page] en [location] con go_router: el paso de Cuentas y el Inicio
/// son pantallas de relleno con [nextAccounts] y [nextHome].
Future<void> pumpOnboardingStep(
  WidgetTester tester, {
  required String location,
  required Widget page,
  required List<Override> overrides,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view
    ..physicalSize = const Size(390, 844) * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: location, builder: (_, _) => page),
      if (location != Routes.onboardingAccounts)
        GoRoute(
          path: Routes.onboardingAccounts,
          builder: (_, _) => const Scaffold(body: Text(nextAccounts)),
        ),
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const Scaffold(body: Text(nextHome)),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
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

/// Toca [finder] después de desplazar la pantalla hasta verlo.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
