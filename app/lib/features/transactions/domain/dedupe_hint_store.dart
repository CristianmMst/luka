/// Recuerda que se descartó el aviso "Sin duplicados" de Movimientos, que
/// explica el sello de un registro hecho de varios avisos.
abstract interface class DedupeHintStore {
  Future<bool> wasDismissed();

  Future<void> dismiss();
}
