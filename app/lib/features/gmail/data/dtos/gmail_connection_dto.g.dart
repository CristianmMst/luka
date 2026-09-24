// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gmail_connection_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GmailConnectionDto _$GmailConnectionDtoFromJson(Map<String, dynamic> json) =>
    GmailConnectionDto(
      status: json['status'] as String,
      email: json['email'] as String?,
      lastSyncAt: json['last_sync_at'] == null
          ? null
          : DateTime.parse(json['last_sync_at'] as String),
      watchExpiresAt: json['watch_expires_at'] == null
          ? null
          : DateTime.parse(json['watch_expires_at'] as String),
    );
