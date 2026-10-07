import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/onboarding/application/onboarding_gate.dart';
import 'package:luka/features/privacy/domain/privacy_ports.dart';

/// Puerto de privacidad; se sobrescribe en `lib/app/composition.dart`.
final privacyRemoteProvider = Provider<PrivacyRemote>(
  (ref) => throw UnimplementedError(
    'privacyRemoteProvider se sobrescribe en la composición',
  ),
);

/// Borrar mi cuenta (RF-11.3, spec 008 §3.7).
class PrivacyActions {
  PrivacyActions({
    required PrivacyRemote remote,
    required Future<void> Function() signOut,
    required Future<void> Function() forgetDevice,
  }) : _remote = remote,
       _signOut = signOut,
       _forgetDevice = forgetDevice;

  final PrivacyRemote _remote;
  final Future<void> Function() _signOut;
  final Future<void> Function() _forgetDevice;

  /// Borra la cuenta en el servidor y luego cierra la sesión, que borra la
  /// base local (P6). Antes olvida lo que el teléfono guarda de este
  /// usuario aunque se cierre sesión (el onboarding terminado). Si el
  /// servidor falla, no se toca nada local.
  Future<void> deleteAccount() async {
    await _remote.deleteAccount();
    await _forgetDevice();
    await _signOut();
  }
}

final privacyActionsProvider = Provider<PrivacyActions>(
  (ref) => PrivacyActions(
    remote: ref.watch(privacyRemoteProvider),
    signOut: () => ref.read(authControllerProvider.notifier).signOut(),
    forgetDevice: () async {
      final auth = ref.read(authControllerProvider).value;
      if (auth is Authenticated) {
        await ref.read(onboardingStoreProvider).forget(auth.user.id);
      }
    },
  ),
);
