import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/capture/application/notification_access_controller.dart';
import 'package:luka/features/capture/domain/capture_grant_store.dart';
import 'package:luka/features/gmail/application/gmail_controller.dart';
import 'package:luka/features/gmail/domain/gmail_connection.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';

/// Puerto de la marca "acceso concedido alguna vez"; se sobrescribe en
/// `lib/app/composition.dart`.
final captureGrantStoreProvider = Provider<CaptureGrantStore>(
  (ref) => throw UnimplementedError(
    'captureGrantStoreProvider se sobrescribe en la composición',
  ),
);

/// El acceso a notificaciones llegó a estar concedido en este teléfono para
/// el usuario en sesión. La primera vez que se ve concedido se guarda.
class CaptureWasGrantedController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final auth = await ref.watch(authControllerProvider.future);
    if (auth is! Authenticated) return false;
    final userId = auth.user.id;
    final store = ref.read(captureGrantStoreProvider);
    ref.listen(notificationAccessProvider, (_, next) {
      if (next.value == NotificationAccess.granted && state.value == false) {
        state = const AsyncData(true);
        unawaited(store.markGranted(userId));
      }
    });
    if (await store.wasGranted(userId)) return true;
    // Concedido antes de que esta marca existiera, o mientras se leía.
    if (ref.read(notificationAccessProvider).value ==
        NotificationAccess.granted) {
      await store.markGranted(userId);
      return true;
    }
    return false;
  }
}

final captureWasGrantedProvider =
    AsyncNotifierProvider<CaptureWasGrantedController, bool>(
      CaptureWasGrantedController.new,
    );

/// Si la captura automática se detuvo y por qué (AC-3.4, spec 008 §3.2).
enum CaptureHealth {
  ok,

  /// El acceso a notificaciones estaba concedido y se perdió (lo quitó el
  /// usuario o el sistema).
  notificationsLost,

  /// Google revocó el permiso de Gmail: solo se recupera reconectando
  /// (spec 005 §3). `error` no cuenta: el backend lo reintenta solo.
  gmailRevoked,
}

/// Deriva [CaptureHealth]; si fallan las dos, Gmail va primero. Mientras
/// alguien la escucha (el Inicio), vuelve a consultar Gmail al volver a
/// primer plano, como mucho cada [gmailRecheck]: un permiso revocado en la
/// cuenta de Google se ve sin reiniciar la app.
class CaptureHealthController extends Notifier<CaptureHealth> {
  static const gmailRecheck = Duration(minutes: 15);

  @override
  CaptureHealth build() {
    _lastGmailCheck ??= ref.read(captureClockProvider)();
    final sub = ref
        .watch(foregroundTicksProvider)
        .listen((_) => _recheckGmail());
    ref.onDispose(sub.cancel);

    final gmail = ref.watch(gmailControllerProvider).value?.info.status;
    if (gmail == GmailStatus.revoked) return CaptureHealth.gmailRevoked;
    final access = ref.watch(notificationAccessProvider).value;
    final wasGranted = ref.watch(captureWasGrantedProvider).value ?? false;
    if (access == NotificationAccess.denied && wasGranted) {
      return CaptureHealth.notificationsLost;
    }
    return CaptureHealth.ok;
  }

  DateTime? _lastGmailCheck;

  void _recheckGmail() {
    final now = ref.read(captureClockProvider)();
    final last = _lastGmailCheck;
    if (last != null && now.difference(last) < gmailRecheck) return;
    _lastGmailCheck = now;
    unawaited(ref.read(gmailControllerProvider.notifier).refresh());
  }
}

final captureHealthProvider =
    NotifierProvider<CaptureHealthController, CaptureHealth>(
      CaptureHealthController.new,
    );
