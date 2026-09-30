import 'dart:convert';

import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/synced_models.dart';

/// Codificación persistida de una [OutboxOperation] (spec 005 §9): `targetId`
/// y `relatedId` van en columnas propias (el `SyncStore` las indexa); el
/// `payload` es JSON con el resto de los datos, sin repetir esos ids.
typedef EncodedOp = ({
  String kind,
  String targetId,
  String? relatedId,
  String payload,
});

/// Convierte una [OutboxOperation] a su forma persistida y de vuelta.
class OutboxCodec {
  const OutboxCodec._();

  static const _emptyPayload = '{}';

  static EncodedOp encode(OutboxOperation op) {
    final payload = switch (op) {
      CreateTransactionOp(:final data) => _encodeNewTransaction(data),
      PatchTransactionOp(:final patch) => _encodePatch(patch),
      ConvertReviewOp(:final data) => _encodeNewTransaction(data),
      SetTransferPairOp() ||
      UnsetTransferPairOp() ||
      DeleteTransactionOp() ||
      DiscardReviewOp() => _emptyPayload,
    };
    return (
      kind: _kindOf(op),
      targetId: op.targetId,
      relatedId: op.relatedId,
      payload: payload,
    );
  }

  static OutboxOperation decode({
    required String kind,
    required String targetId,
    required String payload,
    String? relatedId,
  }) {
    final body = jsonDecode(payload) as Map<String, dynamic>;
    return switch (kind) {
      'create_transaction' => OutboxOperation.createTransaction(
        localId: targetId,
        data: _decodeNewTransaction(body),
      ),
      'patch_transaction' => OutboxOperation.patchTransaction(
        id: targetId,
        patch: _decodePatch(body),
      ),
      'set_transfer_pair' => OutboxOperation.setTransferPair(
        id: targetId,
        pairId: relatedId!,
      ),
      'unset_transfer_pair' => OutboxOperation.unsetTransferPair(id: targetId),
      'delete_transaction' => OutboxOperation.deleteTransaction(id: targetId),
      'convert_review' => OutboxOperation.convertReview(
        rawMessageId: relatedId!,
        localId: targetId,
        data: _decodeNewTransaction(body),
      ),
      'discard_review' => OutboxOperation.discardReview(
        rawMessageId: targetId,
      ),
      _ => throw ArgumentError.value(
        kind,
        'kind',
        'tipo de operación de outbox desconocido',
      ),
    };
  }

  static String _kindOf(OutboxOperation op) => switch (op) {
    CreateTransactionOp() => 'create_transaction',
    PatchTransactionOp() => 'patch_transaction',
    SetTransferPairOp() => 'set_transfer_pair',
    UnsetTransferPairOp() => 'unset_transfer_pair',
    DeleteTransactionOp() => 'delete_transaction',
    ConvertReviewOp() => 'convert_review',
    DiscardReviewOp() => 'discard_review',
  };

  static String _encodeNewTransaction(NewTransaction data) => jsonEncode({
    'amount': data.amount.toWire(),
    'direction': data.direction.name,
    'occurred_at': data.occurredAt.toUtc().toIso8601String(),
    if (data.kind != null) 'kind': data.kind!.name,
    if (data.categoryId != null) 'category_id': data.categoryId,
    if (data.merchant != null) 'merchant': data.merchant,
    if (data.description != null) 'description': data.description,
    if (data.accountId != null) 'account_id': data.accountId,
    if (data.notes != null) 'notes': data.notes,
    if (data.nfcTagId != null) 'nfc_tag_id': data.nfcTagId,
  });

  static NewTransaction _decodeNewTransaction(Map<String, dynamic> body) =>
      NewTransaction(
        amount: Cop.parse(body['amount'] as String),
        direction: TxDirection.values.byName(body['direction'] as String),
        occurredAt: DateTime.parse(body['occurred_at'] as String),
        kind: body['kind'] == null
            ? null
            : TxKind.values.byName(body['kind'] as String),
        categoryId: body['category_id'] as String?,
        merchant: body['merchant'] as String?,
        description: body['description'] as String?,
        accountId: body['account_id'] as String?,
        notes: body['notes'] as String?,
        nfcTagId: body['nfc_tag_id'] as String?,
      );

  static String _encodePatch(TransactionPatch patch) => jsonEncode({
    if (patch.categoryId != null) 'category_id': patch.categoryId,
    if (patch.kind != null) 'kind': patch.kind!.name,
    if (patch.notes != null) 'notes': patch.notes!.value,
    if (patch.merchant != null) 'merchant': patch.merchant!.value,
    'learn_merchant_rule': patch.learnMerchantRule,
  });

  static TransactionPatch _decodePatch(Map<String, dynamic> body) =>
      TransactionPatch(
        categoryId: body['category_id'] as String?,
        kind: body['kind'] == null
            ? null
            : TxKind.values.byName(body['kind'] as String),
        notes: body.containsKey('notes')
            ? (value: body['notes'] as String?)
            : null,
        merchant: body.containsKey('merchant')
            ? (value: body['merchant'] as String?)
            : null,
        learnMerchantRule: body['learn_merchant_rule'] as bool? ?? true,
      );
}
