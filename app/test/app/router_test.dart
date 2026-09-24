import 'package:finanzia/app/router.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/gmail/application/gmail_gate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = User(id: 'u', email: 'a@b.co', status: UserStatus.active);
  const loading = AsyncLoading<AuthState>();
  const signedIn = AsyncData<AuthState>(Authenticated(user));
  const signedOut = AsyncData<AuthState>(Unauthenticated());
  final failed = AsyncError<AuthState>(Exception(), StackTrace.empty);

  group('sesión (Gmail ya resuelto)', () {
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
      (signedOut, Routes.settings, Routes.login),
      (signedIn, Routes.transactions, null),
      (signedIn, '${Routes.transactions}/tx1', null),
      (signedIn, Routes.register, null),
      (signedIn, Routes.review, null),
      (signedIn, Routes.settings, null),
      // El onboarding de Gmail también pide sesión.
      (signedOut, Routes.onboardingGmail, Routes.login),
      (loading, Routes.onboardingGmail, Routes.splash),
      (failed, Routes.onboardingGmail, Routes.login),
    ];

    for (final (auth, location, expected) in table) {
      test('${auth.runtimeType} en $location → ${expected ?? 'se queda'}', () {
        expect(redirectFor(auth, location, gmail: GmailGate.skip), expected);
      });
    }
  });

  group('paso de Gmail', () {
    final table = <(GmailGate, String, String?)>[
      // Al salir del splash o del login decide el gate.
      (GmailGate.prompt, Routes.splash, Routes.onboardingGmail),
      (GmailGate.prompt, Routes.login, Routes.onboardingGmail),
      (GmailGate.skip, Routes.splash, Routes.home),
      (GmailGate.skip, Routes.login, Routes.home),
      // Cargando: espera en el splash, sin pasar por Inicio.
      (GmailGate.pending, Routes.splash, null),
      (GmailGate.pending, Routes.login, Routes.splash),
      // Ya en el onboarding no se redirige: ni bucle ni rebote, y el deep
      // link funciona aunque no haya nada pendiente.
      (GmailGate.prompt, Routes.onboardingGmail, null),
      (GmailGate.skip, Routes.onboardingGmail, null),
      (GmailGate.pending, Routes.onboardingGmail, null),
      // En el shell tampoco: desconectar en Ajustes no saca al usuario.
      (GmailGate.prompt, Routes.home, null),
      (GmailGate.prompt, Routes.settings, null),
      (GmailGate.pending, Routes.home, null),
      (GmailGate.pending, '${Routes.transactions}/tx1', null),
    ];

    for (final (gmail, location, expected) in table) {
      test('con sesión, $gmail en $location → ${expected ?? 'se queda'}', () {
        expect(redirectFor(signedIn, location, gmail: gmail), expected);
      });
    }

    test('sin sesión el gate de Gmail no importa', () {
      for (final gmail in GmailGate.values) {
        expect(
          redirectFor(signedOut, Routes.splash, gmail: gmail),
          Routes.login,
        );
        expect(redirectFor(loading, Routes.home, gmail: gmail), Routes.splash);
      }
    });

    test('ningún destino vuelve a redirigir (sin bucles)', () {
      for (final auth in [loading, signedIn, signedOut, failed]) {
        for (final gmail in GmailGate.values) {
          for (final location in [
            Routes.splash,
            Routes.login,
            Routes.home,
            Routes.onboardingGmail,
            Routes.settings,
          ]) {
            final target = redirectFor(auth, location, gmail: gmail);
            if (target == null) continue;
            expect(
              redirectFor(auth, target, gmail: gmail),
              isNull,
              reason: '$auth/$gmail: $location → $target',
            );
          }
        }
      }
    });
  });
}
