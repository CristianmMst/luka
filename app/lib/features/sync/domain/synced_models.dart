import 'package:finanzia/core/format/money.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'synced_models.freezed.dart';

enum TxDirection { debit, credit }

enum TxKind { expense, income, transfer }

/// Transacción del servidor (`TransactionListItem`, spec 005 §6).
@freezed
abstract class SyncedTransaction with _$SyncedTransaction {
  const factory SyncedTransaction({
    required String id,
    required Cop amount,
    required String currency,
    required TxDirection direction,
    required TxKind kind,
    required DateTime occurredAt,
    required String categoryId,
    required String fiscalTag,
    required bool transferAuto,
    required String parsedBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? merchant,
    String? description,
    String? bank,
    String? accountId,
    String? transferPairId,
    double? confidence,
    String? notes,
    @Default(<String>[]) List<String> channels,
  }) = _SyncedTransaction;
}

/// Fuente cruda adjunta a una transaccion, solo para el detalle
/// (`TransactionSourceResponse`, spec 005 §6).
@freezed
abstract class SyncedSource with _$SyncedSource {
  const factory SyncedSource({
    required String channel,
    required DateTime receivedAt,
  }) = _SyncedSource;
}

@freezed
abstract class SyncedCategory with _$SyncedCategory {
  const factory SyncedCategory({
    required String id,
    required String name,
    required String fiscalTag,
    required bool isSystem,
    String? userId,
    String? slug,
    String? icon,
    String? color,
  }) = _SyncedCategory;
}

@freezed
abstract class SyncedAccount with _$SyncedAccount {
  const factory SyncedAccount({
    required String id,
    required String bank,
    required String kind,
    String? last4,
    String? alias,
  }) = _SyncedAccount;
}

@freezed
abstract class SyncedReviewItem with _$SyncedReviewItem {
  const factory SyncedReviewItem({
    required String rawMessageId,
    required String channel,
    required String sender,
    required DateTime receivedAt,
    required String reason,
    required Map<String, String> partialExtract,
    required DateTime createdAt,
    String? bank,
    String? text,
  }) = _SyncedReviewItem;
}
