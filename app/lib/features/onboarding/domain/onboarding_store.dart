/// Recuerda, por usuario y en el teléfono, que ya terminó (o saltó) el
/// onboarding, para no volver a mostrarlo al abrir la app ni al volver a
/// iniciar sesión.
abstract interface class OnboardingStore {
  Future<bool> isDone(String userId);

  Future<void> markDone(String userId);

  /// Borra la marca (al borrar la cuenta, P6).
  Future<void> forget(String userId);
}
