import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/synced_models.dart';

part 'review_draft.freezed.dart';

/// Lo que le falta a un borrador para convertirse en transacción.
enum ReviewDraftError {
  /// Sin monto o con monto en cero.
  amountRequired,
  directionRequired,
  occurredAtRequired,
}

/// El borrador no se puede convertir; [errors] dice por qué.
class InvalidReviewDraft implements Exception {
  const InvalidReviewDraft(this.errors);

  final Set<ReviewDraftError> errors;

  @override
  String toString() => 'InvalidReviewDraft($errors)';
}

/// Formulario de "crear transacción" desde un mensaje en revisión
/// (AC-8.1): se prellena con lo que sí se extrajo.
@freezed
abstract class ReviewDraft with _$ReviewDraft {
  const factory ReviewDraft({
    Cop? amount,
    TxDirection? direction,
    DateTime? occurredAt,
    String? merchant,
    String? categoryId,
  }) = _ReviewDraft;

  const ReviewDraft._();

  /// Prellena desde `partial_extract`. Un valor que no se entiende se deja
  /// vacío para que el usuario lo escriba: un monto que no pasa
  /// [Cop.parse] o no es positivo, una dirección distinta de
  /// `debit`/`credit` y una fecha sin zona horaria (no se adivina la zona
  /// de un gasto, P5).
  factory ReviewDraft.fromPartialExtract(Map<String, String> extract) =>
      ReviewDraft(
        amount: _amount(extract['amount']),
        direction: _direction(extract['direction']),
        occurredAt: _occurredAt(extract['occurred_at']),
        merchant: _text(extract['merchant']),
      );

  Set<ReviewDraftError> validate() => {
    if (amount == null || amount!.cents <= 0) ReviewDraftError.amountRequired,
    if (direction == null) ReviewDraftError.directionRequired,
    if (occurredAt == null) ReviewDraftError.occurredAtRequired,
  };

  bool get isValid => validate().isEmpty;

  static Cop? _amount(String? raw) {
    if (raw == null) return null;
    try {
      final amount = Cop.parse(raw);
      return amount.cents > 0 ? amount : null;
    } on FormatException {
      return null;
    }
  }

  static TxDirection? _direction(String? raw) => switch (raw) {
    'debit' => TxDirection.debit,
    'credit' => TxDirection.credit,
    _ => null,
  };

  // ISO 8601 con hora y zona explícita (`Z` o `±hh:mm`), como lo escribe
  // `datetime.isoformat()` del backend.
  static final _zoned = RegExp(r'T.*(?:Z|[+-]\d{2}:?\d{2})$');

  static DateTime? _occurredAt(String? raw) {
    if (raw == null || !_zoned.hasMatch(raw)) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  static String? _text(String? raw) {
    final trimmed = raw?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
