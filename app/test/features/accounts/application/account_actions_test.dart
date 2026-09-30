import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/accounts/domain/account_draft.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AccountsRemote {}

class _MockStore extends Mock implements AccountsStore {}

const _nomina = SyncedAccount(
  id: 'a-1',
  bank: 'bancolombia',
  kind: 'savings',
  last4: '4821',
  alias: 'Nómina',
);

void main() {
  late _MockRemote remote;
  late _MockStore store;
  late AccountActions actions;

  setUpAll(() {
    registerFallbackValue(const AccountDraft());
    registerFallbackValue(_nomina);
  });

  setUp(() {
    remote = _MockRemote();
    store = _MockStore();
    when(() => store.upsert(any())).thenAnswer((_) async {});
    when(() => store.remove(any())).thenAnswer((_) async {});
    actions = AccountActions(remote: remote, store: store);
  });

  test('crear envía el borrador recortado y guarda en local', () async {
    when(() => remote.create(any())).thenAnswer((_) async => _nomina);

    final created = await actions.create(
      const AccountDraft(
        bank: 'bancolombia',
        last4: ' 4821 ',
        alias: ' Nómina ',
      ),
    );

    expect(created, _nomina);
    final sent =
        verify(() => remote.create(captureAny())).captured.single
            as AccountDraft;
    expect(sent.last4, '4821');
    expect(sent.alias, 'Nómina');
    verify(() => store.upsert(_nomina)).called(1);
  });

  test('un borrador inválido no llega al servidor', () async {
    await expectLater(
      actions.create(const AccountDraft(bank: 'nequi', last4: '12345')),
      throwsA(
        isA<InvalidAccountDraft>().having(
          (e) => e.errors,
          'errors',
          {AccountDraftError.invalidLast4},
        ),
      ),
    );
    verifyNever(() => remote.create(any()));
  });

  test('una cuenta repetida no toca la base local', () async {
    when(() => remote.create(any())).thenThrow(const AccountDuplicate());

    await expectLater(
      actions.create(const AccountDraft(bank: 'nequi')),
      throwsA(isA<AccountDuplicate>()),
    );
    verifyNever(() => store.upsert(any()));
  });

  test('editar guarda en local lo que devolvió el servidor', () async {
    when(() => remote.update(any(), any())).thenAnswer((_) async => _nomina);

    await actions.update('a-1', const AccountDraft(bank: 'bancolombia'));

    verify(() => remote.update('a-1', any())).called(1);
    verify(() => store.upsert(_nomina)).called(1);
  });

  test('borrar quita en local solo si el servidor lo borró', () async {
    when(() => remote.delete(any())).thenAnswer((_) async {});
    await actions.delete('a-1');
    verify(() => store.remove('a-1')).called(1);

    when(() => remote.delete(any())).thenThrow(const AccountOffline());
    await expectLater(actions.delete('a-2'), throwsA(isA<AccountOffline>()));
    verifyNever(() => store.remove('a-2'));
  });

  test('linkedAccountsProvider lee la base local', () async {
    const account = LinkedAccount(
      id: 'a-1',
      bank: 'nequi',
      kind: 'wallet',
      transactionCount: 2,
    );
    when(() => store.watchAll()).thenAnswer((_) => Stream.value([account]));
    final container = ProviderContainer(
      overrides: [accountsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(linkedAccountsProvider, (_, _) {});
    addTearDown(sub.close);

    expect(await container.read(linkedAccountsProvider.future), [account]);
  });
}
