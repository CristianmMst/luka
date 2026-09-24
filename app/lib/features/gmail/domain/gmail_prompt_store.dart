/// Recuerda, por usuario, que eligió "Ahora no" en la invitación a conectar
/// Gmail, para no volver a preguntar después de cada login.
abstract interface class GmailPromptStore {
  Future<bool> isDismissed(String userId);

  Future<void> dismiss(String userId);
}
