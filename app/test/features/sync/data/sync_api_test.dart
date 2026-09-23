import 'dart:convert';

import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/sync/data/sync_api.dart';
import 'package:finanzia/features/sync/domain/outbox_operation.dart';
import 'package:finanzia/features/sync/domain/sync_ports.dart';
import 'package:finanzia/features/sync/domain/sync_rules.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/stub_backend.dart';

Map<String, dynamic> _reviewJson({required String rawMessageId}) => {
  'raw_message_id': rawMessageId,
  'channel': 'sms',
  'bank': null,
  'sender': '85555',
  'received_at': '2026-09-22T15:00:00Z',
  'reason': 'sin_categoria',
  'partial_extract': <String, String>{},
  'text': null,
  'created_at': '2026-09-22T15:00:00Z',
};

void main() {
  test(
    'POST lleva Idempotency-Key y el reintento envía cuerpo idéntico',
    () async {
      var calls = 0;
      final backend = StubBackend((r) {
        calls++;
        if (calls == 1) throw connectionError(r);
        return StubResponse(201, transactionJson(id: 'srv-1'));
      });
      final api = SyncApi(stubDio(backend));
      final entry = OutboxEntry(
        seq: 1,
        idempotencyKey: 'k-1',
        attempts: 0,
        op: OutboxOperation.createTransaction(
          localId: 'l1',
          data: NewTransaction(
            amount: Cop.pesos(45000),
            direction: TxDirection.debit,
            occurredAt: DateTime.utc(2026, 9, 22, 15),
          ),
        ),
      );

      await expectLater(
        api.send(entry),
        throwsA(
          isA<RemoteFailure>().having((f) => f.isNetwork, 'network', isTrue),
        ),
      );
      final created = await api.send(entry);

      expect(created!.id, 'srv-1');
      final [first, second] = backend.requests;
      expect(first.headers['Idempotency-Key'], 'k-1');
      expect(second.data, first.data); // mismo String JSON
      expect(
        jsonDecode(first.data as String),
        containsPair('amount', '45000.00'),
      );
    },
  );

  test(
    'PATCH y DELETE no llevan Idempotency-Key; DELETE devuelve null',
    () async {
      final backend = StubBackend(
        (r) => r.method == 'DELETE'
            ? const StubResponse(204)
            : StubResponse(200, transactionJson(id: 't1')),
      );
      final api = SyncApi(stubDio(backend));

      final patched = await api.send(
        const OutboxEntry(
          seq: 1,
          idempotencyKey: 'k-2',
          attempts: 0,
          op: OutboxOperation.patchTransaction(
            id: 't1',
            patch: TransactionPatch(categoryId: 'c1'),
          ),
        ),
      );
      expect(patched!.id, 't1');
      expect(
        backend.requests.single.headers.containsKey('Idempotency-Key'),
        isFalse,
      );

      final deleted = await api.send(
        const OutboxEntry(
          seq: 2,
          idempotencyKey: 'k-3',
          attempts: 0,
          op: OutboxOperation.deleteTransaction(id: 't1'),
        ),
      );
      expect(deleted, isNull);
      expect(
        backend.requests.last.headers.containsKey('Idempotency-Key'),
        isFalse,
      );
    },
  );

  test(
    '409 con Retry-After se traduce a RemoteFailure con retryAfter',
    () async {
      final backend = StubBackend(
        (_) =>
            StubResponse.error(409, 'conflict', headers: {'retry-after': '1'}),
      );
      final api = SyncApi(stubDio(backend));

      await expectLater(
        api.send(
          const OutboxEntry(
            seq: 1,
            idempotencyKey: 'k-1',
            attempts: 0,
            op: OutboxOperation.deleteTransaction(id: 't1'),
          ),
        ),
        throwsA(
          isA<RemoteFailure>()
              .having((f) => f.statusCode, 'statusCode', 409)
              .having((f) => f.code, 'code', 'conflict')
              .having(
                (f) => f.retryAfter,
                'retryAfter',
                const Duration(seconds: 1),
              ),
        ),
      );
    },
  );

  test(
    'transactionsSince envía updated_since con zona, limit=200 y cursor',
    () async {
      final backend = StubBackend(
        (_) => StubResponse(200, {
          'items': [transactionJson(id: 't1')],
          'next_cursor': null,
        }),
      );
      final api = SyncApi(stubDio(backend));

      final page = await api.transactionsSince(
        DateTime.utc(2026, 9, 22, 10),
        cursor: 'cur-1',
      );

      final request = backend.requests.single;
      expect(
        request.queryParameters['updated_since'],
        '2026-09-22T10:00:00.000Z',
      );
      expect(request.queryParameters['limit'], 200);
      expect(request.queryParameters['cursor'], 'cur-1');
      expect(page.items.single.id, 't1');
      expect(page.nextCursor, isNull);
    },
  );

  test('openReview recorre todas las páginas', () async {
    var call = 0;
    final backend = StubBackend((_) {
      call++;
      if (call == 1) {
        return StubResponse(200, {
          'items': [_reviewJson(rawMessageId: 'r1')],
          'next_cursor': 'p2',
        });
      }
      return StubResponse(200, {
        'items': [_reviewJson(rawMessageId: 'r2')],
        'next_cursor': null,
      });
    });
    final api = SyncApi(stubDio(backend));

    final items = await api.openReview();

    expect(items.map((i) => i.rawMessageId), ['r1', 'r2']);
    expect(backend.requests, hasLength(2));
    expect(backend.requests[1].queryParameters['cursor'], 'p2');
  });

  test('categories y accounts parsean listas planas', () async {
    final backend = StubBackend(
      (r) => r.path == '/v1/categories'
          ? const StubResponse(200, [
              {
                'id': 'c1',
                'user_id': null,
                'slug': 'comida',
                'name': 'Comida',
                'icon': null,
                'color': null,
                'fiscal_tag': 'deducible',
                'is_system': true,
              },
            ])
          : const StubResponse(200, [
              {
                'id': 'a1',
                'bank': 'bancolombia',
                'kind': 'debito',
                'last4': '1234',
                'alias': null,
              },
            ]),
    );
    final api = SyncApi(stubDio(backend));

    final categories = await api.categories();
    final accounts = await api.accounts();

    expect(categories.single.id, 'c1');
    expect(accounts.single.id, 'a1');
  });

  group('fetchTransaction', () {
    test('200 devuelve la transacción del servidor', () async {
      final backend = StubBackend(
        (_) => StubResponse(200, transactionJson(id: 't1')),
      );
      final api = SyncApi(stubDio(backend));

      final fetched = await api.fetchTransaction('t1');

      expect(fetched!.id, 't1');
      final request = backend.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/v1/transactions/t1');
    });

    test('404 (no existe o es de otro usuario) devuelve null', () async {
      final backend = StubBackend(
        (_) => StubResponse.error(404, 'transaction_not_found'),
      );
      final api = SyncApi(stubDio(backend));

      expect(await api.fetchTransaction('t1'), isNull);
    });

    test('sin red falla con RemoteFailure.network', () async {
      final backend = StubBackend((r) => throw connectionError(r));
      final api = SyncApi(stubDio(backend));

      await expectLater(
        api.fetchTransaction('t1'),
        throwsA(
          isA<RemoteFailure>().having((f) => f.isNetwork, 'network', isTrue),
        ),
      );
    });
  });

  group('fetchTransactionDetail', () {
    test('200 devuelve la transaccion y sus sources', () async {
      final backend = StubBackend(
        (_) => StubResponse(200, {
          ...transactionJson(id: 't1', channels: ['email', 'manual']),
          'sources': [
            {
              'id': 's1',
              'channel': 'email',
              'raw_message_id': 'm1',
              'received_at': '2026-09-22T15:00:00Z',
            },
          ],
          'pair': null,
        }),
      );
      final api = SyncApi(stubDio(backend));

      final detail = await api.fetchTransactionDetail('t1');

      expect(detail!.tx.id, 't1');
      expect(detail.tx.channels, ['email', 'manual']);
      expect(detail.sources, hasLength(1));
      expect(detail.sources.single.channel, 'email');
      expect(detail.sources.single.receivedAt, DateTime.utc(2026, 9, 22, 15));
      final request = backend.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/v1/transactions/t1');
    });

    test('404 (no existe o es de otro usuario) devuelve null', () async {
      final backend = StubBackend(
        (_) => StubResponse.error(404, 'transaction_not_found'),
      );
      final api = SyncApi(stubDio(backend));

      expect(await api.fetchTransactionDetail('t1'), isNull);
    });

    test('sin red falla con RemoteFailure.network', () async {
      final backend = StubBackend((r) => throw connectionError(r));
      final api = SyncApi(stubDio(backend));

      await expectLater(
        api.fetchTransactionDetail('t1'),
        throwsA(
          isA<RemoteFailure>().having((f) => f.isNetwork, 'network', isTrue),
        ),
      );
    });
  });
}
