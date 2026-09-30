import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/recurring/data/recurring_api.dart';
import 'package:luka/features/recurring/domain/recurring_draft.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/recurring_ports.dart';

import '../../../helpers/stub_backend.dart';

Map<String, dynamic> _expenseJson({bool active = true}) => {
  'id': 'e-1',
  'name': 'Spotify',
  'merchant_keyword': 'spotify',
  'expected_amount': '16900.00',
  'amount_tolerance_pct': 10,
  'day_of_month': 22,
  'category_id': null,
  'account_id': null,
  'remind_days_before': 1,
  'active': active,
  'created_at': '2026-10-01T12:00:00+00:00',
  'updated_at': '2026-10-01T12:00:00+00:00',
};

Map<String, dynamic> _occurrenceJson({String status = 'paid'}) => {
  'id': 'o-1',
  'recurring_expense': {
    'id': 'e-1',
    'name': 'Spotify',
    'merchant_keyword': 'spotify',
    'expected_amount': '16900.00',
    'category_id': 'c-1',
    'active': true,
  },
  'period': '2026-10',
  'due_date': '2026-10-22',
  'status': status,
  'matched_by': status == 'paid' ? 'auto' : null,
  'paid_at': status == 'paid' ? '2026-10-22T12:14:03+00:00' : null,
  'reminded_at': null,
  'transaction': status == 'paid'
      ? {
          'id': 't-1',
          'merchant': 'SPOTIFY P3A9C1',
          'amount': '16900.00',
          'occurred_at': '2026-10-22T12:12:00+00:00',
        }
      : null,
};

const _draft = RecurringDraft(
  name: 'Spotify',
  merchantKeyword: 'spotify',
  expectedAmount: Cop(1690000),
  dayOfMonth: 22,
);

void main() {
  test('crear hace POST con el cuerpo de la spec 005 §10', () async {
    final backend = StubBackend((_) => StubResponse(201, _expenseJson()));

    final created = await RecurringApi(stubDio(backend)).create(_draft);

    expect(created.expectedAmount, const Cop(1690000));
    final request = backend.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/v1/recurring-expenses');
    expect(jsonDecode(request.data as String), {
      'name': 'Spotify',
      'merchant_keyword': 'spotify',
      'expected_amount': '16900.00',
      'day_of_month': 22,
      'amount_tolerance_pct': 10,
      'remind_days_before': 1,
      'category_id': null,
      'account_id': null,
    });
  });

  test('pausar hace PATCH solo con active', () async {
    final backend = StubBackend(
      (_) => StubResponse(200, _expenseJson(active: false)),
    );

    final paused = await RecurringApi(
      stubDio(backend),
    ).setActive('e-1', active: false);

    expect(paused.active, isFalse);
    expect(backend.requests.single.method, 'PATCH');
    expect(jsonDecode(backend.requests.single.data as String), {
      'active': false,
    });
  });

  test('ocurrencias pide el rango AAAA-MM y trae el movimiento', () async {
    final backend = StubBackend((_) => StubResponse(200, [_occurrenceJson()]));

    final items = await RecurringApi(
      stubDio(backend),
    ).occurrences(ColombiaMonth(2026, 9), ColombiaMonth(2026, 11));

    final request = backend.requests.single;
    expect(request.path, '/v1/recurring-occurrences');
    expect(request.queryParameters, {'from': '2026-09', 'to': '2026-11'});
    final occ = items.single;
    expect(occ.status, OccurrenceStatus.paid);
    expect(occ.dueDate, DateTime.utc(2026, 10, 22));
    expect(occ.categoryId, 'c-1');
    expect(occ.transactionMerchant, 'SPOTIFY P3A9C1');
    expect(occ.transactionAmount, const Cop(1690000));
  });

  test(
    'marcar pagado manda el movimiento; deshacer y omitir no mandan cuerpo',
    () async {
      final backend = StubBackend(
        (_) => StubResponse(200, _occurrenceJson(status: 'pending')),
      );
      final api = RecurringApi(stubDio(backend));

      await api.markPaid('o-1', transactionId: 't-1');
      await api.unmark('o-1');
      await api.skip('o-1');

      expect(backend.requests.map((r) => r.path), [
        '/v1/recurring-occurrences/o-1/mark-paid',
        '/v1/recurring-occurrences/o-1/unmark',
        '/v1/recurring-occurrences/o-1/skip',
      ]);
      expect(jsonDecode(backend.requests.first.data as String), {
        'transaction_id': 't-1',
      });
      expect(backend.requests[1].data, isNull);
    },
  );

  test('traduce los errores a RecurringFailure', () async {
    Future<void> expectFailure(StubResponse response, Matcher matcher) async {
      final api = RecurringApi(stubDio(StubBackend((_) => response)));
      await expectLater(api.delete('e-1'), throwsA(matcher));
    }

    await expectFailure(
      StubResponse.error(404, 'not_found'),
      isA<RecurringGone>(),
    );
    await expectFailure(
      StubResponse.error(409, 'conflict'),
      isA<RecurringConflict>(),
    );
    await expectFailure(
      StubResponse.error(500, 'internal'),
      isA<RecurringUnexpected>().having((f) => f.statusCode, 'status', 500),
    );
    final offline = RecurringApi(
      stubDio(StubBackend((request) => throw connectionError(request))),
    );
    await expectLater(offline.expenses(), throwsA(isA<RecurringOffline>()));
  });

  test('una respuesta fuera de contrato es RecurringUnexpected', () async {
    final backend = StubBackend((_) => const StubResponse(200, {'id': 1}));

    await expectLater(
      RecurringApi(stubDio(backend)).create(_draft),
      throwsA(isA<RecurringUnexpected>()),
    );
  });
}
