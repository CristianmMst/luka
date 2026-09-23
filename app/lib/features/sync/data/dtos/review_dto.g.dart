// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewEntryDto _$ReviewEntryDtoFromJson(Map<String, dynamic> json) =>
    ReviewEntryDto(
      rawMessageId: json['raw_message_id'] as String,
      channel: json['channel'] as String,
      sender: json['sender'] as String,
      receivedAt: DateTime.parse(json['received_at'] as String),
      reason: json['reason'] as String,
      partialExtract: Map<String, String>.from(json['partial_extract'] as Map),
      createdAt: DateTime.parse(json['created_at'] as String),
      bank: json['bank'] as String?,
      text: json['text'] as String?,
    );

ReviewPageDto _$ReviewPageDtoFromJson(Map<String, dynamic> json) =>
    ReviewPageDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => ReviewEntryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
    );
