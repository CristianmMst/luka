import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/features/capture/domain/capture_grant_store.dart';

/// "Acceso concedido alguna vez" en la tabla `sync_state`, con la clave
/// `capture_was_granted:<userId>`. Cerrar sesión vacía `sync_state` y la
/// marca se pierde: tras volver a entrar, un acceso ya perdido no avisa
/// hasta que se conceda otra vez.
class DriftCaptureGrantStore implements CaptureGrantStore {
  DriftCaptureGrantStore(this._db);

  final AppDatabase _db;

  static String keyFor(String userId) => 'capture_was_granted:$userId';

  @override
  Future<bool> wasGranted(String userId) async {
    final row = await (_db.select(
      _db.syncState,
    )..where((s) => s.key.equals(keyFor(userId)))).getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> markGranted(String userId) => _db
      .into(_db.syncState)
      .insertOnConflictUpdate(
        SyncStateCompanion.insert(key: keyFor(userId), value: '1'),
      );
}
