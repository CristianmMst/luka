import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_item.freezed.dart';

/// Mensaje que no se pudo convertir en transacción y espera que el usuario
/// lo convierta o lo descarte (RF-8, spec 008 §3.5).
@freezed
abstract class ReviewItem with _$ReviewItem {
  const factory ReviewItem({
    required String rawMessageId,

    /// `email` o `notification`.
    required String channel,
    required String sender,
    required DateTime receivedAt,

    /// Motivo del fallo (`no_template`, `llm_low_confidence`, …).
    required String reason,

    /// Lo que sí se extrajo (`amount`, `direction`, `occurred_at`,
    /// `merchant`); vacío salvo en fallos del LLM.
    required Map<String, String> partialExtract,
    String? bank,

    /// Cuerpo crudo; `null` si ya se purgó.
    String? text,
  }) = _ReviewItem;
}
