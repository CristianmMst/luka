import 'package:luka/core/db/app_database.dart';
import 'package:luka/features/onboarding/domain/onboarding_store.dart';

/// "Onboarding terminado" en la tabla `sync_state`, con la clave
/// `onboarding_done:<userId>`.
///
/// `DriftSyncStore.clearAll` (cerrar sesión) y `claimFor` con otro usuario
/// vacían `sync_state`, así que la marca se pierde con ellos: tras cerrar
/// sesión y volver a entrar, el onboarding se muestra otra vez (con los
/// pasos ya resueltos saltados). Al restaurar la sesión se conserva.
class DriftOnboardingStore implements OnboardingStore {
  DriftOnboardingStore(this._db);

  final AppDatabase _db;

  static String keyFor(String userId) => 'onboarding_done:$userId';

  @override
  Future<bool> isDone(String userId) async {
    final row = await (_db.select(
      _db.syncState,
    )..where((s) => s.key.equals(keyFor(userId)))).getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> markDone(String userId) => _db
      .into(_db.syncState)
      .insertOnConflictUpdate(
        SyncStateCompanion.insert(key: keyFor(userId), value: '1'),
      );
}
