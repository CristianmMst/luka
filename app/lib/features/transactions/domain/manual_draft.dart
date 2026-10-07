import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/synced_models.dart';

part 'manual_draft.freezed.dart';

enum ManualDraftError {
  /// Sin monto o con monto en cero.
  amountRequired,
}

class InvalidManualDraft implements Exception {
  const InvalidManualDraft(this.errors);

  final Set<ManualDraftError> errors;

  @override
  String toString() => 'InvalidManualDraft($errors)';
}

/// Formulario de "Registrar" (spec 008 §3.4, AC-4.4): solo el monto es
/// obligatorio; la dirección arranca en gasto y la fecha en ahora.
@freezed
abstract class ManualDraft with _$ManualDraft {
  const factory ManualDraft({
    required DateTime occurredAt,
    Cop? amount,
    @Default(TxDirection.debit) TxDirection direction,
    String? merchant,
    String? categoryId,
    String? notes,

    /// Cuenta vinculada de donde salió o a donde entró (spec 008 §3.4).
    String? accountId,
  }) = _ManualDraft;

  const ManualDraft._();

  Set<ManualDraftError> validate() => {
    if (amount == null || amount!.cents <= 0) ManualDraftError.amountRequired,
  };

  NewTransaction toNewTransaction() {
    final errors = validate();
    if (errors.isNotEmpty) throw InvalidManualDraft(errors);
    return NewTransaction(
      amount: amount!,
      direction: direction,
      occurredAt: occurredAt,
      merchant: _text(merchant),
      categoryId: categoryId,
      notes: _text(notes),
      accountId: accountId,
    );
  }

  static String? _text(String? raw) {
    final trimmed = raw?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
