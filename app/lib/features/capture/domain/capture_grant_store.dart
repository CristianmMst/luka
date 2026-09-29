/// Recuerda, por usuario, que el acceso a notificaciones llegó a estar
/// concedido en este teléfono. Así, al perderlo, la app avisa que la captura
/// "se detuvo" (AC-3.4); a quien nunca lo activó no le dice nada.
abstract interface class CaptureGrantStore {
  Future<bool> wasGranted(String userId);

  Future<void> markGranted(String userId);
}
