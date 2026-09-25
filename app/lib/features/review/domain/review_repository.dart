import 'package:finanzia/features/review/domain/review_item.dart';

/// Puerto de lectura de la lista de revisión (los datos viven en Drift y
/// se refrescan en cada pull, spec 008 §5).
abstract interface class ReviewRepository {
  /// Mensajes abiertos, los recibidos más recientemente primero.
  Stream<List<ReviewItem>> watchOpen();

  /// Un mensaje abierto, para abrir su formulario por id; `null` si ya no
  /// está (se convirtió, se descartó o el pull lo quitó).
  Stream<ReviewItem?> watchOne(String rawMessageId);
}
