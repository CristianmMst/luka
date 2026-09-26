import 'package:finanzia/app/router.dart';
import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/app_theme.dart';
import 'package:finanzia/features/capture/application/capture_flusher.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinanziaApp extends ConsumerWidget {
  const FinanziaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mantiene vivos el sync y el envío de notificaciones capturadas sin
    // reconstruir la app.
    ref
      ..listen(syncCoordinatorProvider, (_, _) {})
      ..listen(captureFlusherProvider, (_, _) {});
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: const Locale('es', 'CO'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
