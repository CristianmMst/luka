// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: json['id'] as String,
  email: json['email'] as String,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  displayName: json['display_name'] as String?,
  photoUrl: json['photo_url'] as String?,
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'display_name': instance.displayName,
  'photo_url': instance.photoUrl,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
};

SessionDto _$SessionDtoFromJson(Map<String, dynamic> json) => SessionDto(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  expiresIn: (json['expires_in'] as num).toInt(),
  user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
);
