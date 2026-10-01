import 'package:luka/core/db/app_database.dart';
import 'package:luka/core/db/device_state.dart';
import 'package:luka/features/onboarding/domain/onboarding_store.dart';

/// "Onboarding terminado" en la tabla `sync_state`, con la clave
/// `device:onboarding_done:<userId>`.
///
/// Es una clave del teléfono ([deviceStatePrefix]): cerrar sesión no la
/// borra, así que quien ya lo terminó no lo vuelve a ver al entrar de
/// nuevo; otro usuario en el mismo teléfono sí lo ve. Borrar la cuenta la
/// quita ([forget]).
class DriftOnboardingStore implements OnboardingStore {
  DriftOnboardingStore(this._db);

  final AppDatabase _db;

  static String keyFor(String userId) =>
      deviceStateKey('onboarding_done:$userId');

  /// La clave de antes, que cerrar sesión borraba: se sigue leyendo para no
  /// mostrar otra vez el onboarding a quien ya lo terminó.
  static String legacyKeyFor(String userId) => 'onboarding_done:$userId';

  @override
  Future<bool> isDone(String userId) async {
    final row =
        await (_db.select(_db.syncState)..where(
              (s) => s.key.isIn([keyFor(userId), legacyKeyFor(userId)]),
            ))
            .get();
    return row.isNotEmpty;
  }

  @override
  Future<void> markDone(String userId) => _db
      .into(_db.syncState)
      .insertOnConflictUpdate(
        SyncStateCompanion.insert(key: keyFor(userId), value: '1'),
      );

  @override
  Future<void> forget(String userId) =>
      (_db.delete(_db.syncState)..where(
            (s) => s.key.isIn([keyFor(userId), legacyKeyFor(userId)]),
          ))
          .go();
}
