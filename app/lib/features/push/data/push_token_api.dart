import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/features/push/domain/push_ports.dart';

/// [PushTokenRemote] sobre dio (spec 005 §10).
class PushTokenApi implements PushTokenRemote {
  PushTokenApi(this._dio);

  final Dio _dio;

  static const _path = '/v1/devices/push-token';

  @override
  Future<void> register(String token, String platform) => _dio.put<void>(
    _path,
    data: jsonEncode({'token': token, 'platform': platform}),
  );

  @override
  Future<void> unregister(String token) =>
      _dio.delete<void>(_path, data: jsonEncode({'token': token}));
}

/// [PushPrefs] en `sync_state` (se borra al cerrar sesión, como el resto).
class DriftPushPrefs implements PushPrefs {
  DriftPushPrefs(this._db);

  final AppDatabase _db;

  static const _key = 'push_permission_asked';

  @override
  Future<bool> permissionAsked() async {
    final row = await (_db.select(
      _db.syncState,
    )..where((s) => s.key.equals(_key))).getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> markPermissionAsked() => _db
      .into(_db.syncState)
      .insertOnConflictUpdate(SyncStateCompanion.insert(key: _key, value: '1'));
}
