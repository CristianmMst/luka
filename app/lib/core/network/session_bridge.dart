/// Resultado de intentar renovar la sesión con el refresh token.
enum RefreshOutcome {
  /// Hay tokens nuevos guardados.
  refreshed,

  /// El backend rechazó el refresh token (vencido, revocado o reutilizado):
  /// la sesión terminó y hay que volver a iniciar sesión.
  rejected,

  /// No se pudo hablar con el backend (sin red). La sesión sigue viva.
  unavailable,
}

/// Lo que la capa de red necesita saber de la sesión, sin depender de la
/// feature `auth` (que la implementa).
abstract interface class SessionBridge {
  /// Access token vigente, o `null` si no hay sesión.
  Future<String?> accessToken();

  /// Renueva la sesión. Llamadas concurrentes comparten un único refresh.
  Future<RefreshOutcome> refresh();

  /// El backend rechazó las credenciales: borrar la sesión local y avisar.
  Future<void> expire();
}
