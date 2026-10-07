import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/synced_models.dart';

part 'outbox_operation.freezed.dart';

/// Cuerpo de `POST /transactions` y de `convert` (spec 005 §6–7).
@freezed
abstract class NewTransaction with _$NewTransaction {
  const factory NewTransaction({
    required Cop amount,
    required TxDirection direction,
    required DateTime occurredAt,
    TxKind? kind,
    String? categoryId,
    String? merchant,
    String? description,
    String? accountId,
    String? notes,
  }) = _NewTransaction;
}

/// Cambios de `PATCH /transactions/{id}` (spec 005 §6). Un campo nulo no se
/// envía; `notes`, `merchant` y `accountId` usan un record para distinguir
/// "borrar" de "no tocar".
@freezed
abstract class TransactionPatch with _$TransactionPatch {
  const factory TransactionPatch({
    String? categoryId,
    TxKind? kind,
    ({String? value})? notes,
    ({String? value})? merchant,
    Cop? amount,
    TxDirection? direction,
    DateTime? occurredAt,
    ({String? value})? accountId,
    @Default(true) bool learnMerchantRule,
  }) = _TransactionPatch;
}

/// Operación hecha sin red, pendiente de enviar (spec 005 §9).
@freezed
sealed class OutboxOperation with _$OutboxOperation {
  const OutboxOperation._();

  const factory OutboxOperation.createTransaction({
    required String localId,
    required NewTransaction data,
  }) = CreateTransactionOp;
  const factory OutboxOperation.patchTransaction({
    required String id,
    required TransactionPatch patch,
  }) = PatchTransactionOp;
  const factory OutboxOperation.setTransferPair({
    required String id,
    required String pairId,
  }) = SetTransferPairOp;
  const factory OutboxOperation.unsetTransferPair({required String id}) =
      UnsetTransferPairOp;
  const factory OutboxOperation.deleteTransaction({required String id}) =
      DeleteTransactionOp;
  const factory OutboxOperation.convertReview({
    required String rawMessageId,
    required String localId,
    required NewTransaction data,
  }) = ConvertReviewOp;
  const factory OutboxOperation.discardReview({required String rawMessageId}) =
      DiscardReviewOp;

  /// Registro local que la operación modifica.
  String get targetId => switch (this) {
    CreateTransactionOp(:final localId) => localId,
    ConvertReviewOp(:final localId) => localId,
    PatchTransactionOp(:final id) ||
    SetTransferPairOp(:final id) ||
    UnsetTransferPairOp(:final id) ||
    DeleteTransactionOp(:final id) => id,
    DiscardReviewOp(:final rawMessageId) => rawMessageId,
  };

  String? get relatedId => switch (this) {
    SetTransferPairOp(:final pairId) => pairId,
    ConvertReviewOp(:final rawMessageId) => rawMessageId,
    _ => null,
  };

  /// Crea una transacción con id local que el servidor reemplaza.
  bool get createsRecord =>
      this is CreateTransactionOp || this is ConvertReviewOp;
}
