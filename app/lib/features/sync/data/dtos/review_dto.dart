import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:json_annotation/json_annotation.dart';

part 'review_dto.g.dart';

/// `ReviewEntryResponse` de `GET /review` (spec 005 §7, D1).
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ReviewEntryDto {
  const ReviewEntryDto({
    required this.rawMessageId,
    required this.channel,
    required this.sender,
    required this.receivedAt,
    required this.reason,
    required this.partialExtract,
    required this.createdAt,
    this.bank,
    this.text,
  });

  factory ReviewEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewEntryDtoFromJson(json);

  final String rawMessageId;
  final String channel;
  final String sender;
  final DateTime receivedAt;
  final String reason;
  final Map<String, String> partialExtract;
  final DateTime createdAt;
  final String? bank;
  final String? text;

  SyncedReviewItem toDomain() => SyncedReviewItem(
    rawMessageId: rawMessageId,
    channel: channel,
    sender: sender,
    receivedAt: receivedAt,
    reason: reason,
    partialExtract: partialExtract,
    createdAt: createdAt,
    bank: bank,
    text: text,
  );
}

/// `Page[ReviewEntryResponse]` de `GET /review`.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ReviewPageDto {
  const ReviewPageDto({required this.items, this.nextCursor});

  factory ReviewPageDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewPageDtoFromJson(json);

  final List<ReviewEntryDto> items;
  final String? nextCursor;
}
