import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/domain/auth_failure.dart';

/// Estado de la acción "Continuar con Google" en la pantalla de login.
///
/// `AsyncLoading` bloquea el botón; `AsyncError` lleva el `AuthFailure` que
/// la pantalla traduce a un aviso. Cancelar no es un error.
class SignInController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!ref.mounted) return;
      ref.read(authControllerProvider.notifier).signedIn(user);
      state = const AsyncData(null);
    } on AuthCancelled {
      if (ref.mounted) state = const AsyncData(null);
    } on AuthFailure catch (failure, stack) {
      if (ref.mounted) state = AsyncError(failure, stack);
    }
  }
}

final AsyncNotifierProvider<SignInController, void> signInControllerProvider =
    AsyncNotifierProvider.autoDispose<SignInController, void>(
      SignInController.new,
    );
