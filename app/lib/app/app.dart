import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/app/router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/app_theme.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/push/application/push_registrar.dart';
import 'package:luka/features/recurring/application/local_reminder_sync.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';

/// Mensajero raíz: muestra el aviso push que llega con la app abierta.
final _messengerKey = GlobalKey<ScaffoldMessengerState>();

class LukaApp extends ConsumerWidget {
  const LukaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mantiene vivos el sync, el envío de notificaciones capturadas y el
    // registro del token de push sin reconstruir la app.
    ref
      ..listen(syncCoordinatorProvider, (_, _) {})
      ..listen(captureFlusherProvider, (_, _) {})
      ..listen(pushRegistrarProvider, (_, push) => _onPush(ref, push))
      // Avisos locales de iPhone (spec 011 §5.1); en Android no hace nada.
      ..listen(localReminderSyncProvider, (_, _) {})
      // Un aviso tocado antes de restaurar la sesión se abre al entrar.
      ..listen(
        authControllerProvider,
        (_, _) => _onPush(ref, ref.read(pushRegistrarProvider)),
      );
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: const Locale('es', 'CO'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
    );
  }

  /// Abre `/gastos-fijos?ocurrencia=<id>` para el aviso tocado (spec 008
  /// §4.2), o lo ofrece como snackbar si llegó con la app abierta.
  static void _onPush(WidgetRef ref, PushState push) {
    final signedIn = switch (ref.read(authControllerProvider)) {
      AsyncData(value: Authenticated()) => true,
      _ => false,
    };
    if (!signedIn) return;
    final registrar = ref.read(pushRegistrarProvider.notifier);
    String location(String id) => '${Routes.recurring}?ocurrencia=$id';

    final open = push.pendingOpen;
    if (open != null) {
      registrar.consumeOpen();
      ref.read(routerProvider).push(location(open.occurrenceId)).ignore();
    }
    final foreground = push.foreground;
    if (foreground != null) {
      registrar.consumeForeground();
      final l10n = lookupAppLocalizations(const Locale('es'));
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(l10n.pushForeground),
          action: SnackBarAction(
            label: l10n.pushForegroundAction,
            onPressed: () => ref
                .read(routerProvider)
                .push(location(foreground.occurrenceId))
                .ignore(),
          ),
        ),
      );
    }
  }
}
