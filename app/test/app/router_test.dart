import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/app/router.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/domain/entities/user.dart';
import 'package:luka/features/onboarding/application/onboarding_gate.dart';
import 'package:luka/features/onboarding/domain/onboarding_step.dart';

void main() {
  const user = User(id: 'u', email: 'a@b.co', status: UserStatus.active);
  const loading = AsyncLoading<AuthState>();
  const signedIn = AsyncData<AuthState>(Authenticated(user));
  const signedOut = AsyncData<AuthState>(Unauthenticated());
  final failed = AsyncError<AuthState>(Exception(), StackTrace.empty);

  const skip = OnboardingSkip();
  const pending = OnboardingPending();
  const gmail = OnboardingShow(OnboardingStep.gmail);
  const accounts = OnboardingShow(OnboardingStep.accounts);
  const gates = <OnboardingGate>[
    skip,
    pending,
    gmail,
    OnboardingShow(OnboardingStep.notifications),
    accounts,
  ];

  group('sesión (onboarding ya resuelto)', () {
    final table = <(AsyncValue<AuthState>, String, String?)>[
      (loading, Routes.splash, null),
      (loading, Routes.home, Routes.splash),
      (signedOut, Routes.splash, Routes.login),
      (signedOut, Routes.home, Routes.login),
      (signedOut, Routes.login, null),
      (signedIn, Routes.splash, Routes.home),
      (signedIn, Routes.login, Routes.home),
      (signedIn, Routes.home, null),
      (failed, Routes.home, Routes.login),
      // Las rutas del shell (F4.2) piden sesión igual que /.
      (signedOut, Routes.transactions, Routes.login),
      (signedOut, '${Routes.transactions}/tx1', Routes.login),
      (signedOut, Routes.register, Routes.login),
      (signedOut, Routes.review, Routes.login),
      (signedOut, '${Routes.review}/m1', Routes.login),
      (signedOut, Routes.settings, Routes.login),
      (signedIn, Routes.transactions, null),
      (signedIn, '${Routes.transactions}/tx1', null),
      (signedIn, Routes.register, null),
      (signedIn, Routes.review, null),
      (signedIn, '${Routes.review}/m1', null),
      (signedIn, Routes.settings, null),
      // El onboarding también pide sesión.
      (signedOut, Routes.onboardingGmail, Routes.login),
      (signedOut, Routes.onboardingNotifications, Routes.login),
      (signedOut, Routes.onboardingAccounts, Routes.login),
      (loading, Routes.onboardingGmail, Routes.splash),
      (failed, Routes.onboardingAccounts, Routes.login),
    ];

    for (final (auth, location, expected) in table) {
      test('${auth.runtimeType} en $location → ${expected ?? 'se queda'}', () {
        expect(redirectFor(auth, location, onboarding: skip), expected);
      });
    }
  });

  group('onboarding', () {
    final table = <(OnboardingGate, String, String?)>[
      // Al salir del splash o del login decide el gate, en el primer paso
      // pendiente.
      (gmail, Routes.splash, Routes.onboardingGmail),
      (gmail, Routes.login, Routes.onboardingGmail),
      (
        const OnboardingShow(OnboardingStep.notifications),
        Routes.splash,
        Routes.onboardingNotifications,
      ),
      (accounts, Routes.login, Routes.onboardingAccounts),
      (skip, Routes.splash, Routes.home),
      (skip, Routes.login, Routes.home),
      // Cargando: espera en el splash, sin pasar por Inicio.
      (pending, Routes.splash, null),
      (pending, Routes.login, Routes.splash),
      // Ya en el onboarding no se redirige: ni bucle ni rebote al avanzar
      // de paso, y el deep link funciona aunque no haya nada pendiente.
      (gmail, Routes.onboardingGmail, null),
      (gmail, Routes.onboardingAccounts, null),
      (skip, Routes.onboardingGmail, null),
      (skip, Routes.onboardingNotifications, null),
      (pending, Routes.onboardingGmail, null),
      // En el shell tampoco: desconectar en Ajustes no saca al usuario.
      (gmail, Routes.home, null),
      (gmail, Routes.settings, null),
      (pending, Routes.home, null),
      (pending, '${Routes.transactions}/tx1', null),
      (accounts, '${Routes.review}/m1', null),
    ];

    for (final (gate, location, expected) in table) {
      test('con sesión, $gate en $location → ${expected ?? 'se queda'}', () {
        expect(redirectFor(signedIn, location, onboarding: gate), expected);
      });
    }

    test('sin sesión el gate del onboarding no importa', () {
      for (final gate in gates) {
        expect(
          redirectFor(signedOut, Routes.splash, onboarding: gate),
          Routes.login,
        );
        expect(
          redirectFor(loading, Routes.home, onboarding: gate),
          Routes.splash,
        );
      }
    });

    test('ningún destino vuelve a redirigir (sin bucles)', () {
      for (final auth in [loading, signedIn, signedOut, failed]) {
        for (final gate in gates) {
          for (final location in [
            Routes.splash,
            Routes.login,
            Routes.home,
            Routes.onboardingGmail,
            Routes.onboardingAccounts,
            Routes.settings,
          ]) {
            final target = redirectFor(auth, location, onboarding: gate);
            if (target == null) continue;
            expect(
              redirectFor(auth, target, onboarding: gate),
              isNull,
              reason: '$auth/$gate: $location → $target',
            );
          }
        }
      }
    });
  });
}
