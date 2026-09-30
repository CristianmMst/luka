import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/accounts/data/accounts_api.dart';
import 'package:luka/features/accounts/domain/account_draft.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';

import '../../../helpers/stub_backend.dart';

Map<String, dynamic> _accountJson({String? alias = 'Nómina'}) => {
  'id': 'a-1',
  'bank': 'bancolombia',
  'kind': 'savings',
  'last4': '4821',
  'alias': alias,
};

void main() {
  test('crear hace POST /v1/accounts con banco y vacíos en null', () async {
    final backend = StubBackend((_) => StubResponse(201, _accountJson()));

    final created = await AccountsApi(stubDio(backend)).create(
      const AccountDraft(bank: 'bancolombia', last4: '4821'),
    );

    expect(created.id, 'a-1');
    expect(created.alias, 'Nómina');
    final request = backend.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/v1/accounts');
    expect(jsonDecode(request.data as String), {
      'bank': 'bancolombia',
      'kind': 'savings',
      'last4': '4821',
      'alias': null,
    });
  });

  test('editar hace PATCH sin el banco', () async {
    final backend = StubBackend(
      (_) => StubResponse(200, _accountJson(alias: null)),
    );

    final updated = await AccountsApi(stubDio(backend)).update(
      'a-1',
      const AccountDraft(bank: 'bancolombia', kind: 'checking', alias: ' '),
    );

    expect(updated.alias, isNull);
    final request = backend.requests.single;
    expect(request.method, 'PATCH');
    expect(request.path, '/v1/accounts/a-1');
    expect(jsonDecode(request.data as String), {
      'kind': 'checking',
      'last4': null,
      'alias': null,
    });
  });

  test('borrar hace DELETE', () async {
    final backend = StubBackend((_) => const StubResponse(204));

    await AccountsApi(stubDio(backend)).delete('a-1');

    expect(backend.requests.single.method, 'DELETE');
    expect(backend.requests.single.path, '/v1/accounts/a-1');
  });

  test('los errores se traducen a AccountFailure', () async {
    Future<Object?> failure(StubHandler handler) async {
      try {
        await AccountsApi(
          stubDio(StubBackend(handler)),
        ).create(const AccountDraft(bank: 'nequi'));
      } on AccountFailure catch (e) {
        return e;
      }
      return null;
    }

    expect(
      await failure((_) => StubResponse.error(409, 'conflict')),
      isA<AccountDuplicate>(),
    );
    expect(
      await failure((_) => StubResponse.error(404, 'not_found')),
      isA<AccountGone>(),
    );
    expect(
      await failure((r) => throw connectionError(r)),
      isA<AccountOffline>(),
    );
    expect(
      await failure((_) => StubResponse.error(500, 'internal')),
      isA<AccountUnexpected>(),
    );
    expect(
      await failure((_) => const StubResponse(201, {'nope': true})),
      isA<AccountUnexpected>(),
    );
  });

  test('borrar sin red falla con AccountOffline', () async {
    final backend = StubBackend((r) => throw connectionError(r));

    await expectLater(
      AccountsApi(stubDio(backend)).delete('a-1'),
      throwsA(isA<AccountOffline>()),
    );
  });
}
