import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

enum UserStatus { active, deletionPending, unknown }

/// Usuario autenticado (espejo de `UserResponse`, spec 005 §2).
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    required UserStatus status,
    String? displayName,
    String? photoUrl,
  }) = _User;

  const User._();

  /// Nombre para saludar: el de Google o, si no hay, la parte local del email.
  String get greetingName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    return email.split('@').first;
  }
}
