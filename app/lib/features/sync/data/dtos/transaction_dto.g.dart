// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionDto _$TransactionDtoFromJson(Map<String, dynamic> json) =>
    TransactionDto(
      id: json['id'] as String,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      direction: json['direction'] as String,
      kind: json['kind'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      categoryId: json['category_id'] as String,
      fiscalTag: json['fiscal_tag'] as String,
      transferAuto: json['transfer_auto'] as bool,
      parsedBy: json['parsed_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      merchant: json['merchant'] as String?,
      description: json['description'] as String?,
      bank: json['bank'] as String?,
      accountId: json['account_id'] as String?,
      transferPairId: json['transfer_pair_id'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );

TransactionPageDto _$TransactionPageDtoFromJson(Map<String, dynamic> json) =>
    TransactionPageDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => TransactionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
    );
