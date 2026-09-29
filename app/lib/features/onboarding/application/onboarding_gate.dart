import 'dart:async';

import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/capture/application/notification_access_controller.dart';
import 'package:finanzia/features/gmail/application/gmail_controller.dart';
import 'package:finanzia/features/gmail/domain/gmail_connection.dart';
import 'package:finanzia/features/onboarding/domain/onboarding_step.dart';
import 'package:finanzia/features/onboarding/domain/onboarding_store.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puerto de la marca "onboarding terminado"; se sobrescribe en
/// `lib/app/composition.dart`.
final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => throw UnimplementedError(
    'onboardingStoreProvider se sobrescribe en la composición',
  ),
);

/// El usuario en sesión ya terminó o saltó el onboarding (`true` sin
/// sesión: no hay a quién mostrárselo). Es una lectura local: el gate no
/// espera la red para quien ya lo terminó.
final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final auth = await ref.watch(authControllerProvider.future);
  if (auth is! Authenticated) return true;
  return ref.read(onboardingStoreProvider).isDone(auth.user.id);
});

/// Qué necesita saber el session gate al salir del splash o del login
/// (spec 008 §2).
@immutable
sealed class OnboardingGate {
  const OnboardingGate();
}

/// Todavía se lee el estado: el gate espera en el splash.
final class OnboardingPending extends OnboardingGate {
  const OnboardingPending();
}

/// Mostrar el onboarding desde [step].
final class OnboardingShow extends OnboardingGate {
  const OnboardingShow(this.step);

  final OnboardingStep step;

  @override
  bool operator ==(Object other) =>
      other is OnboardingShow && other.step == step;

  @override
  int get hashCode => step.hashCode;

  @override
  String toString() => 'OnboardingShow($step)';
}

/// Ya lo terminó (o no hay sesión): directo a Inicio.
final class OnboardingSkip extends OnboardingGate {
  const OnboardingSkip();
}

/// Deriva [OnboardingGate]:
///
/// - Leyendo la marca local → pendiente. Con la marca (o si no se pudo
///   leer) → [OnboardingSkip], sin esperar la red.
/// - Sin la marca, el primer paso sin resolver ([firstPendingStep]). Para
///   saberlo espera el estado de Gmail y el acceso a notificaciones, pero
///   como mucho [timeout] desde que la sesión es [Authenticated]: sin red
///   (P4) se muestra desde Gmail, cuya pantalla ofrece reintentar.
class OnboardingGateController extends Notifier<OnboardingGate> {
  /// Espera máxima del splash por el estado de Gmail.
  static const timeout = Duration(seconds: 4);

  @override
  OnboardingGate build() {
    final timedOut = ref.watch(_gateTimedOutProvider);
    final done = ref.watch(onboardingDoneProvider);
    // Durante una recarga (p. ej. tras un login) el valor previo es de la
    // sesión anterior: no vale para decidir.
    if (done.isLoading) return const OnboardingPending();
    if (done.value ?? true) return const OnboardingSkip();

    final gmail = ref.watch(gmailControllerProvider);
    final access = ref.watch(notificationAccessProvider);
    if ((gmail.isLoading || access.isLoading) && !timedOut) {
      return const OnboardingPending();
    }
    return OnboardingShow(
      firstPendingStep(
        from: OnboardingStep.gmail,
        gmailActive: _gmailActive(gmail),
        notificationsPending: _notificationsPending(ref, access),
      ),
    );
  }
}

bool _gmailActive(AsyncValue<GmailState> gmail) =>
    !gmail.isLoading &&
    !gmail.hasError &&
    gmail.value?.info.status == GmailStatus.active;

bool _notificationsPending(Ref ref, AsyncValue<NotificationAccess> access) =>
    ref.read(notificationCaptureSupportedProvider) &&
    access.value != NotificationAccess.granted;

/// `true` cuando pasaron [OnboardingGateController.timeout] desde que la
/// sesión es [Authenticated] sin que llegara lo que el gate espera; vuelve a
/// `false` y se rearma con cada sesión nueva. El timer solo corre mientras
/// algo carga: al llegar se cancela.
final _gateTimedOutProvider = NotifierProvider<_GateTimeout, bool>(
  _GateTimeout.new,
);

class _GateTimeout extends Notifier<bool> {
  @override
  bool build() {
    final userId = ref.watch(
      authControllerProvider.select(
        (auth) => switch (auth.value) {
          Authenticated(:final user) => user.id,
          _ => null,
        },
      ),
    );
    final loading =
        ref.watch(gmailControllerProvider.select((g) => g.isLoading)) ||
        ref.watch(notificationAccessProvider.select((a) => a.isLoading));
    if (userId == null || !loading) return false;
    final timer = Timer(OnboardingGateController.timeout, () {
      if (ref.mounted) state = true;
    });
    ref.onDispose(timer.cancel);
    return false;
  }
}

final onboardingGateProvider =
    NotifierProvider<OnboardingGateController, OnboardingGate>(
      OnboardingGateController.new,
    );

/// Avanzar y terminar el onboarding desde sus pantallas.
class OnboardingFlow {
  OnboardingFlow(this._ref);

  final Ref _ref;

  /// Los pasos de esta plataforma, para el indicador de progreso.
  List<OnboardingStep> get steps => onboardingSteps(
    notificationsSupported: _ref.read(notificationCaptureSupportedProvider),
  );

  /// El paso que sigue a [current], saltando los ya resueltos; `null` tras
  /// el último.
  OnboardingStep? next(OnboardingStep current) {
    if (current == OnboardingStep.accounts) return null;
    return firstPendingStep(
      from: OnboardingStep.values[current.index + 1],
      // Gmail es el primer paso: después de cualquiera ya no cuenta.
      gmailActive: true,
      notificationsPending: _notificationsPending(
        _ref,
        _ref.read(notificationAccessProvider),
      ),
    );
  }

  /// Guarda la marca: el onboarding no vuelve a salir para este usuario.
  Future<void> finish() async {
    final auth = await _ref.read(authControllerProvider.future);
    if (auth is Authenticated) {
      await _ref.read(onboardingStoreProvider).markDone(auth.user.id);
    }
    _ref.invalidate(onboardingDoneProvider);
  }
}

final onboardingFlowProvider = Provider<OnboardingFlow>(OnboardingFlow.new);
