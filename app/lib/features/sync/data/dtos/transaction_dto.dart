import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_dto.g.dart';

/// `TransactionListItem` del backend (`ledger/infrastructure/api/schemas.py`,
/// spec 005 §6). Sin `sources`/`pair`: solo aparecen en el detalle, que la app
/// no consume.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class TransactionDto {
  const TransactionDto({
    required this.id,
    required this.amount,
    required this.currency,
    required this.direction,
    required this.kind,
    required this.occurredAt,
    required this.categoryId,
    required this.fiscalTag,
    required this.transferAuto,
    required this.parsedBy,
    required this.createdAt,
    required this.updatedAt,
    this.merchant,
    this.description,
    this.bank,
    this.accountId,
    this.transferPairId,
    this.confidence,
    this.notes,
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) =>
      _$TransactionDtoFromJson(json);

  final String id;
  final String amount;
  final String currency;
  final String direction;
  final String kind;
  final DateTime occurredAt;
  final String categoryId;
  final String fiscalTag;
  final bool transferAuto;
  final String parsedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? merchant;
  final String? description;
  final String? bank;
  final String? accountId;
  final String? transferPairId;
  final double? confidence;
  final String? notes;

  /// Lanza si `direction`/`kind` no son un valor conocido (respuesta fuera de
  /// contrato: queda como `RemoteFailure(statusCode: 200, code: 'unknown')`
  /// en `SyncApi`).
  SyncedTransaction toDomain() => SyncedTransaction(
    id: id,
    amount: Cop.parse(amount),
    currency: currency,
    direction: TxDirection.values.byName(direction),
    kind: TxKind.values.byName(kind),
    occurredAt: occurredAt,
    categoryId: categoryId,
    fiscalTag: fiscalTag,
    transferAuto: transferAuto,
    parsedBy: parsedBy,
    createdAt: createdAt,
    updatedAt: updatedAt,
    merchant: merchant,
    description: description,
    bank: bank,
    accountId: accountId,
    transferPairId: transferPairId,
    confidence: confidence,
    notes: notes,
  );
}

/// `Page[TransactionListItem]` de `GET /transactions`.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class TransactionPageDto {
  const TransactionPageDto({required this.items, this.nextCursor});

  factory TransactionPageDto.fromJson(Map<String, dynamic> json) =>
      _$TransactionPageDtoFromJson(json);

  final List<TransactionDto> items;
  final String? nextCursor;
}
