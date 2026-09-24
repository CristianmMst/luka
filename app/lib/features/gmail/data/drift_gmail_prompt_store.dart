import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/features/gmail/domain/gmail_prompt_store.dart';

/// "Ahora no" en la tabla `sync_state`, con la clave
/// `gmail_prompt_dismissed:<userId>`.
///
/// `DriftSyncStore.clearAll` (cerrar sesión) y `claimFor` con otro usuario
/// vacían `sync_state`, así que la preferencia se pierde con ellos: tras
/// cerrar sesión y volver a entrar, la app invita otra vez a conectar Gmail.
/// Al restaurar la sesión (abrir la app) se conserva.
class DriftGmailPromptStore implements GmailPromptStore {
  DriftGmailPromptStore(this._db);

  final AppDatabase _db;

  static String keyFor(String userId) => 'gmail_prompt_dismissed:$userId';

  @override
  Future<bool> isDismissed(String userId) async {
    final row = await (_db.select(
      _db.syncState,
    )..where((s) => s.key.equals(keyFor(userId)))).getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> dismiss(String userId) => _db
      .into(_db.syncState)
      .insertOnConflictUpdate(
        SyncStateCompanion.insert(key: keyFor(userId), value: '1'),
      );
}
