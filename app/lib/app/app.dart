import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/app/router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/app_theme.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';

class LukaApp extends ConsumerWidget {
  const LukaApp({super.key});

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
