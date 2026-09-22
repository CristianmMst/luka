import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_dto.g.dart';

/// `UserResponse` del backend (`identity/infrastructure/api/schemas.py`).
@JsonSerializable(fieldRename: FieldRename.snake)
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.status,
    required this.createdAt,
    this.displayName,
    this.photoUrl,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String status;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  User toDomain() => User(
    id: id,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
    status: switch (status) {
      'active' => UserStatus.active,
      'deletion_pending' => UserStatus.deletionPending,
      _ => UserStatus.unknown,
    },
  );
}

/// `SessionResponse` de `POST /v1/auth/google` y `POST /v1/auth/refresh`.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class SessionDto {
  const SessionDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);

  final String accessToken;
  final String refreshToken;

  /// Segundos de vida del access token.
  final int expiresIn;
  final UserDto user;
}
