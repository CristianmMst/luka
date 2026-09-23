import 'package:finanzia/app/router.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = User(id: 'u', email: 'a@b.co', status: UserStatus.active);
  const loading = AsyncLoading<AuthState>();
  const signedIn = AsyncData<AuthState>(Authenticated(user));
  const signedOut = AsyncData<AuthState>(Unauthenticated());

  final table = <(AsyncValue<AuthState>, String, String?)>[
    (loading, Routes.splash, null),
    (loading, Routes.home, Routes.splash),
    (signedOut, Routes.splash, Routes.login),
    (signedOut, Routes.home, Routes.login),
    (signedOut, Routes.login, null),
    (signedIn, Routes.splash, Routes.home),
    (signedIn, Routes.login, Routes.home),
    (signedIn, Routes.home, null),
    (
      AsyncError<AuthState>(Exception(), StackTrace.empty),
      Routes.home,
      Routes.login,
    ),
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
  ];

  for (final (auth, location, expected) in table) {
    test('${auth.runtimeType} en $location → ${expected ?? 'se queda'}', () {
      expect(redirectFor(auth, location), expected);
    });
  }
}
