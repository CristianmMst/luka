import 'package:luka/features/auth/domain/entities/user.dart';

/// Puerto de autenticación. Las operaciones fallan con `AuthFailure`.
abstract interface class AuthRepository {
  /// Abre Google Sign-In, canjea el `id_token` en el backend y guarda la
  /// sesión.
  Future<User> signInWithGoogle();

  /// Recupera la sesión guardada al abrir la app. `null` si no hay sesión o
  /// el backend la rechazó. Sin red devuelve el usuario en caché (P4).
  Future<User?> restoreSession();

  /// Revoca la sesión en el backend (best effort) y borra la local.
  Future<void> signOut();

  /// Emite cuando la sesión terminó sin que el usuario la cerrara
  /// (refresh rechazado o revocado).
  Stream<void> get sessionExpired;
}
