import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/manual_draft.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';

part 'transaction_edit.freezed.dart';

/// Formulario de "Editar movimiento" (spec 008 §3.3): sale con los datos del
/// movimiento y produce un solo `PATCH` con lo que cambió. Las notas se
/// editan en el detalle, que las guarda solas.
@freezed
abstract class TransactionEdit with _$TransactionEdit {
  const factory TransactionEdit({
    required Cop? amount,
    required TxDirection direction,
    required DateTime occurredAt,
    String? merchant,
    String? categoryId,
    String? accountId,
  }) = _TransactionEdit;

  const TransactionEdit._();

  factory TransactionEdit.from(TransactionView tx) => TransactionEdit(
    amount: tx.amount,
    direction: tx.direction,
    occurredAt: tx.occurredAt,
    merchant: tx.merchant,
    categoryId: tx.categoryId,
    accountId: tx.accountId,
  );

  Set<ManualDraftError> validate() => {
    if (amount == null || amount!.cents <= 0) ManualDraftError.amountRequired,
  };

  bool categoryChanged(TransactionView original) =>
      categoryId != null && categoryId != original.categoryId;

  /// El `PATCH` con lo que cambió frente a [original], o `null` si nada
  /// cambió. [learnMerchantRule] solo cuenta si cambió la categoría.
  TransactionPatch? patchFrom(
    TransactionView original, {
    bool learnMerchantRule = false,
  }) {
    final newMerchant = _text(merchant);
    final merchantChanged = newMerchant != _text(original.merchant);
    final amountChanged = amount != null && amount != original.amount;
    final directionChanged = direction != original.direction;
    final dateChanged = occurredAt != original.occurredAt;
    final accountChanged = accountId != original.accountId;
    final category = categoryChanged(original);
    if (!(merchantChanged ||
        amountChanged ||
        directionChanged ||
        dateChanged ||
        accountChanged ||
        category)) {
      return null;
    }
    return TransactionPatch(
      categoryId: category ? categoryId : null,
      merchant: merchantChanged ? (value: newMerchant) : null,
      amount: amountChanged ? amount : null,
      direction: directionChanged ? direction : null,
      occurredAt: dateChanged ? occurredAt : null,
      accountId: accountChanged ? (value: accountId) : null,
      learnMerchantRule: category && learnMerchantRule,
    );
  }

  static String? _text(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
