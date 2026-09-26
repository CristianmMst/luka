// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CaptureConfigDto _$CaptureConfigDtoFromJson(Map<String, dynamic> json) =>
    CaptureConfigDto(
      version: (json['version'] as num).toInt(),
      bankingApps: (json['banking_apps'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      messagesApps: (json['messages_apps'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      smsSenderPatterns: (json['sms_sender_patterns'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$IngestItemDtoToJson(IngestItemDto instance) =>
    <String, dynamic>{
      'package': instance.package,
      'channel': instance.channel,
      'posted_at': instance.postedAt,
      if (instance.title case final value?) 'title': value,
      'text': instance.text,
      'client_hash': instance.clientHash,
    };

IngestResultDto _$IngestResultDtoFromJson(Map<String, dynamic> json) =>
    IngestResultDto(
      accepted: (json['accepted'] as num).toInt(),
      duplicates: (json['duplicates'] as num).toInt(),
      discarded: (json['discarded'] as num).toInt(),
    );
