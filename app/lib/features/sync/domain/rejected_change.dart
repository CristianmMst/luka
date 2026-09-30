import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';

part 'rejected_change.freezed.dart';

/// Un cambio que el servidor rechazó y espera que el usuario decida
/// (spec 008 §5): reintentarlo o dejar el dato como lo tiene el servidor.
@freezed
abstract class RejectedChange with _$RejectedChange {
  const factory RejectedChange({
    required int seq,
    required OutboxOperation op,

    /// Código del rechazo: el `code` del sobre de error (`not_found`,
    /// `validation_error`…), el status HTTP si no había sobre (`'404'`) o
    /// `dependency_rejected`; `null` si no se guardó.
    String? reason,

    /// Datos del movimiento local afectado, si todavía existe.
    String? merchant,
    int? amountCents,
    String? direction,
  }) = _RejectedChange;
}

/// Motivo del rechazo, agrupado para mostrarlo en lenguaje claro.
enum RejectedReason {
  /// El registro (o algo que usaba, como la cuenta) ya no existe.
  gone,

  /// El servidor no aceptó los datos.
  invalid,

  /// Dependía de otro cambio que también se rechazó.
  dependency,

  /// Cualquier otro motivo.
  other,
}

/// Agrupa un código de rechazo del outbox.
RejectedReason classifyRejectedReason(String? code) => switch (code) {
  'not_found' || 'forbidden' || '403' || '404' || '410' => RejectedReason.gone,
  'validation_error' ||
  'conflict' ||
  '400' ||
  '409' ||
  '422' => RejectedReason.invalid,
  'dependency_rejected' => RejectedReason.dependency,
  _ => RejectedReason.other,
};
