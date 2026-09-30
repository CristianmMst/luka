import 'package:luka/features/sync/domain/outbox_operation.dart';

/// Método, ruta (con prefijo `/v1`, como `AuthApi`) y cuerpo HTTP para
/// enviar una [OutboxOperation] (spec 005 §6-7). Las claves opcionales
/// ausentes se omiten del cuerpo.
({String method, String path, Map<String, Object?>? body}) requestFor(
  OutboxOperation op,
) => switch (op) {
  CreateTransactionOp(:final data) => (
    method: 'POST',
    path: '/v1/transactions',
    body: _newTransactionBody(data, includeNfcTag: true),
  ),
  PatchTransactionOp(:final id, :final patch) => (
    method: 'PATCH',
    path: '/v1/transactions/$id',
    body: _patchBody(patch),
  ),
  SetTransferPairOp(:final id, :final pairId) => (
    method: 'POST',
    path: '/v1/transactions/$id/transfer-pair',
    body: {'pair_id': pairId},
  ),
  UnsetTransferPairOp(:final id) => (
    method: 'DELETE',
    path: '/v1/transactions/$id/transfer-pair',
    body: null,
  ),
  DeleteTransactionOp(:final id) => (
    method: 'DELETE',
    path: '/v1/transactions/$id',
    body: null,
  ),
  ConvertReviewOp(:final rawMessageId, :final data) => (
    method: 'POST',
    path: '/v1/review/$rawMessageId/convert',
    body: _newTransactionBody(data, includeNfcTag: false),
  ),
  DiscardReviewOp(:final rawMessageId) => (
    method: 'POST',
    path: '/v1/review/$rawMessageId/discard',
    body: null,
  ),
};

Map<String, Object?> _newTransactionBody(
  NewTransaction data, {
  required bool includeNfcTag,
}) => {
  'amount': data.amount.toWire(),
  'direction': data.direction.name,
  'occurred_at': data.occurredAt.toUtc().toIso8601String(),
  if (data.kind != null) 'kind': data.kind!.name,
  if (data.categoryId != null) 'category_id': data.categoryId,
  if (data.merchant != null) 'merchant': data.merchant,
  if (data.description != null) 'description': data.description,
  if (data.accountId != null) 'account_id': data.accountId,
  if (data.notes != null) 'notes': data.notes,
  if (includeNfcTag && data.nfcTagId != null) 'nfc_tag_id': data.nfcTagId,
};

Map<String, Object?> _patchBody(TransactionPatch patch) => {
  if (patch.categoryId != null) 'category_id': patch.categoryId,
  if (patch.kind != null) 'kind': patch.kind!.name,
  if (patch.notes != null) 'notes': patch.notes!.value,
  if (patch.merchant != null) 'merchant': patch.merchant!.value,
  'learn_merchant_rule': patch.learnMerchantRule,
};
