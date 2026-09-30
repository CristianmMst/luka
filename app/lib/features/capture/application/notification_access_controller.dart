import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';

enum NotificationAccess {
  /// Sin listener de notificaciones (iOS): la UI no muestra la sección.
  unsupported,
  granted,
  denied,
}

/// Hay listener de notificaciones en esta plataforma (solo Android). Es
/// síncrono para que la UI no muestre nada, ni un instante, en iOS.
final notificationCaptureSupportedProvider = Provider<bool>(
  (ref) => ref.watch(notificationSourceProvider).readsNotifications,
);

/// Hay captura de pagos con Apple Pay (solo iOS, spec 006 §3.3): la cola
/// existe pero no lee notificaciones.
final walletCaptureSupportedProvider = Provider<bool>((ref) {
  final source = ref.watch(notificationSourceProvider);
  return source.isSupported && !source.readsNotifications;
});

/// Acceso de la app a las notificaciones del sistema (spec 008 §3.7). Se
/// vuelve a consultar al volver a primer plano, que es cuando el usuario
/// regresa del ajuste del sistema (AC-3.4).
class NotificationAccessController extends AsyncNotifier<NotificationAccess> {
  @override
  Future<NotificationAccess> build() async {
    final source = ref.watch(notificationSourceProvider);
    if (!source.readsNotifications) return NotificationAccess.unsupported;
    final sub = ref
        .read(foregroundTicksProvider)
        .listen((_) => unawaited(refresh()));
    ref.onDispose(sub.cancel);
    return _check();
  }

  Future<NotificationAccess> _check() async =>
      await ref.read(notificationSourceProvider).isPermissionGranted()
      ? NotificationAccess.granted
      : NotificationAccess.denied;

  Future<void> refresh() async {
    final access = await _check();
    if (ref.mounted) state = AsyncData(access);
  }

  Future<void> openSettings() =>
      ref.read(notificationSourceProvider).openPermissionSettings();
}

final notificationAccessProvider =
    AsyncNotifierProvider<NotificationAccessController, NotificationAccess>(
      NotificationAccessController.new,
    );
