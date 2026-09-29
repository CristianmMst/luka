/// Recuerda, por usuario, que ya terminó (o saltó) el onboarding, para no
/// volver a mostrarlo después de cada apertura.
abstract interface class OnboardingStore {
  Future<bool> isDone(String userId);

  Future<void> markDone(String userId);
}
