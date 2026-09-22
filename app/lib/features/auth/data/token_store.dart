import 'dart:convert';

import 'package:finanzia/features/auth/data/dtos/session_dto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sesión persistida: tokens, vencimiento del access y el último perfil
/// conocido (para abrir la app sin red, P4).
class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.user,
  });

  factory StoredSession.fromDto(SessionDto dto, DateTime now) => StoredSession(
    accessToken: dto.accessToken,
    refreshToken: dto.refreshToken,
    accessExpiresAt: now.toUtc().add(Duration(seconds: dto.expiresIn)),
    user: dto.user,
  );

  factory StoredSession.fromJson(Map<String, dynamic> json) => StoredSession(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    accessExpiresAt: DateTime.parse(json['access_expires_at'] as String),
    user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
  );

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final UserDto user;

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_expires_at': accessExpiresAt.toUtc().toIso8601String(),
    'user': user.toJson(),
  };
}

/// Guarda la sesión como un único blob JSON en el almacén cifrado, para que
/// tokens y perfil se escriban de forma atómica.
class TokenStore {
  TokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'finanzia.session.v1';

  Future<StoredSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return StoredSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Blob corrupto o de un formato anterior: se descarta y se pide login.
      await clear();
      return null;
    }
  }

  Future<void> write(StoredSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  Future<void> clear() => _storage.delete(key: _key);
}
