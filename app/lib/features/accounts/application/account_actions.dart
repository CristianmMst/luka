import 'package:finanzia/features/accounts/domain/account_draft.dart';
import 'package:finanzia/features/accounts/domain/accounts_ports.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puertos de cuentas; se sobrescriben en `lib/app/composition.dart`.
final accountsRemoteProvider = Provider<AccountsRemote>(
  (ref) => throw UnimplementedError(
    'accountsRemoteProvider se sobrescribe en la composición',
  ),
);
final accountsStoreProvider = Provider<AccountsStore>(
  (ref) => throw UnimplementedError(
    'accountsStoreProvider se sobrescribe en la composición',
  ),
);

/// Cuentas vinculadas del usuario con su conteo de movimientos.
final StreamProvider<List<LinkedAccount>> linkedAccountsProvider =
    StreamProvider.autoDispose<List<LinkedAccount>>(
      (ref) => ref.watch(accountsStoreProvider).watchAll(),
    );

/// El borrador no se puede enviar; [errors] dice por qué.
class InvalidAccountDraft implements Exception {
  const InvalidAccountDraft(this.errors);

  final Set<AccountDraftError> errors;

  @override
  String toString() => 'InvalidAccountDraft($errors)';
}

/// Crear, editar y borrar cuentas vinculadas (spec 005 §7, RF-6). Van
/// directo al servidor, sin outbox: sin conexión fallan con
/// `AccountOffline`. Tras un éxito la copia local se actualiza al instante;
/// el servidor no cambia otros datos, así que no hace falta un sync.
class AccountActions {
  AccountActions({required AccountsRemote remote, required AccountsStore store})
    : _remote = remote,
      _store = store;

  final AccountsRemote _remote;
  final AccountsStore _store;

  Future<SyncedAccount> create(AccountDraft draft) async {
    final created = await _remote.create(_checked(draft));
    await _store.upsert(created);
    return created;
  }

  Future<SyncedAccount> update(String id, AccountDraft draft) async {
    final updated = await _remote.update(id, _checked(draft));
    await _store.upsert(updated);
    return updated;
  }

  /// El servidor deja sus movimientos sin cuenta; en local igual.
  Future<void> delete(String id) async {
    await _remote.delete(id);
    await _store.remove(id);
  }

  AccountDraft _checked(AccountDraft draft) {
    final errors = draft.validate();
    if (errors.isNotEmpty) throw InvalidAccountDraft(errors);
    return draft.copyWith(
      last4: draft.cleanLast4 ?? '',
      alias: draft.cleanAlias ?? '',
    );
  }
}

final accountActionsProvider = Provider<AccountActions>(
  (ref) => AccountActions(
    remote: ref.watch(accountsRemoteProvider),
    store: ref.watch(accountsStoreProvider),
  ),
);
