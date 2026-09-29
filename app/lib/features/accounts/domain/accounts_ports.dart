import 'package:finanzia/features/accounts/domain/account_draft.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'accounts_ports.freezed.dart';

/// Cuenta vinculada del usuario, con cuántos movimientos locales la usan
/// (para "Mis cuentas" y el diálogo de borrar).
@freezed
abstract class LinkedAccount with _$LinkedAccount {
  const factory LinkedAccount({
    required String id,
    required String bank,
    required String kind,
    required int transactionCount,
    String? last4,
    String? alias,
  }) = _LinkedAccount;
}

/// Por qué no se pudo crear, editar o borrar una cuenta.
sealed class AccountFailure implements Exception {
  const AccountFailure();
}

/// Sin conexión: las cuentas se gestionan solo en línea.
final class AccountOffline extends AccountFailure {
  const AccountOffline();
}

/// 409: ya hay una cuenta con ese banco y esos últimos 4.
final class AccountDuplicate extends AccountFailure {
  const AccountDuplicate();
}

/// 404: la cuenta ya no existe.
final class AccountGone extends AccountFailure {
  const AccountGone();
}

/// Cualquier otro fallo (5xx, respuesta fuera de contrato).
final class AccountUnexpected extends AccountFailure {
  const AccountUnexpected();
}

/// `/v1/accounts` del backend. Falla con [AccountFailure].
abstract interface class AccountsRemote {
  Future<SyncedAccount> create(AccountDraft draft);

  /// El banco no se edita (el backend no lo acepta en el PATCH).
  Future<SyncedAccount> update(String id, AccountDraft draft);
  Future<void> delete(String id);
}

/// Copia local (Drift) de las cuentas vinculadas.
abstract interface class AccountsStore {
  /// Todas las cuentas, por banco y últimos 4.
  Stream<List<LinkedAccount>> watchAll();

  /// Guarda la cuenta que devolvió el servidor, para verla sin esperar al
  /// próximo pull.
  Future<void> upsert(SyncedAccount account);

  /// Quita la cuenta y deja sus movimientos locales sin cuenta, como hace
  /// el servidor (`ON DELETE SET NULL`).
  Future<void> remove(String id);
}
