import 'dart:async';

import 'package:finanzia/features/auth/domain/auth_failure.dart';
import 'package:finanzia/features/auth/domain/auth_repository.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puerto de auth para la capa de aplicación; la implementación se cablea en
/// `lib/app/composition.dart`.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError(
    'authRepositoryProvider debe sobrescribirse en la composición de la app',
  ),
);

/// Estado de la sesión. Mientras el provider está en `AsyncLoading` la app
/// todavía no sabe si hay sesión (splash).
sealed class AuthState {
  const AuthState();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final User user;
}

final class Unauthenticated extends AuthState {
  const Unauthenticated({this.sessionExpired = false});

  /// La sesión terminó sin que el usuario la cerrara.
  final bool sessionExpired;
}

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repository = ref.watch(authRepositoryProvider);
    final subscription = repository.sessionExpired.listen((_) {
      state = const AsyncData(Unauthenticated(sessionExpired: true));
    });
    ref.onDispose(subscription.cancel);

    try {
      final user = await repository.restoreSession();
      return user == null ? const Unauthenticated() : Authenticated(user);
    } on AuthFailure {
      return const Unauthenticated();
    }
  }

  void signedIn(User user) => state = AsyncData(Authenticated(user));

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(Unauthenticated());
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
