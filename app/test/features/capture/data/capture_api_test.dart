import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/capture/data/capture_api.dart';
import 'package:luka/features/capture/data/dtos/capture_dtos.dart';
import 'package:luka/features/capture/domain/captured_notification.dart';
import 'package:luka/features/sync/domain/sync_rules.dart';

import '../../../helpers/stub_backend.dart';

void main() {
  final notification = CapturedNotification(
    id: 7,
    package: 'com.google.android.apps.messaging',
    channel: CaptureChannel.smsNotification,
    postedAt: DateTime.utc(2026, 8, 5, 19, 30, 5),
    utcOffset: const Duration(hours: -5),
    title: 'Bancolombia',
    text: r'Bancolombia: Compraste $12.000 en EXITO',
  );

  test('GET /v1/config/capture se traduce a CaptureConfig', () async {
    final backend = StubBackend(
      (_) => const StubResponse(200, {
        'version': 1,
        'banking_apps': ['com.bancolombia.app'],
        'messages_apps': ['com.google.android.apps.messaging'],
        'sms_sender_patterns': ['(?i)bancolombia'],
        'email_senders': {
          'bancolombia': ['alertas@bancolombia.com.co'],
        },
      }),
    );

    final config = await CaptureApi(stubDio(backend)).config();

    expect(backend.requests.single.path, '/v1/config/capture');
    expect(
      config,
      const CaptureConfig(
        version: 1,
        bankingApps: ['com.bancolombia.app'],
        messagesApps: ['com.google.android.apps.messaging'],
        smsSenderPatterns: ['(?i)bancolombia'],
      ),
    );
  });

  test(
    'POST /v1/ingest/notifications con el contrato de spec 005 §5',
    () async {
      final backend = StubBackend(
        (_) => const StubResponse(200, {
          'accepted': 1,
          'duplicates': 0,
          'discarded': 0,
        }),
      );

      final result = await CaptureApi(stubDio(backend)).ingest([notification]);

      expect(result, (accepted: 1, duplicates: 0, discarded: 0));
      final request = backend.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/v1/ingest/notifications');
      expect(request.headers.containsKey('Idempotency-Key'), isFalse);
      final body = jsonDecode(request.data as String) as Map<String, dynamic>;
      expect(body, {
        'items': [
          {
            'package': 'com.google.android.apps.messaging',
            'channel': 'sms_notification',
            'posted_at': '2026-08-05T14:30:05-05:00',
            'title': 'Bancolombia',
            'text': r'Bancolombia: Compraste $12.000 en EXITO',
            'client_hash': notification.clientHash,
          },
        ],
      });
    },
  );

  test('posted_at conserva la zona del teléfono, incluso positiva', () {
    final item = notification.copyWith(
      channel: CaptureChannel.notification,
      title: null,
      utcOffset: const Duration(hours: 5, minutes: 30),
    );
    final json = IngestItemDto.fromDomain(item).toJson();
    expect(json['posted_at'], '2026-08-06T01:00:05+05:30');
    expect(json['channel'], 'notification');
    expect(json.containsKey('title'), isFalse);
  });

  test('un error HTTP se traduce a RemoteFailure', () async {
    final backend = StubBackend(
      (_) => StubResponse.error(429, 'rate_limited'),
    );
    await expectLater(
      CaptureApi(stubDio(backend)).ingest([notification]),
      throwsA(
        isA<RemoteFailure>().having((f) => f.statusCode, 'status', 429),
      ),
    );
  });

  test('sin red es RemoteFailure.network', () async {
    final backend = StubBackend((r) => throw connectionError(r));
    await expectLater(
      CaptureApi(stubDio(backend)).config(),
      throwsA(isA<RemoteFailure>().having((f) => f.isNetwork, 'net', isTrue)),
    );
  });

  test('una respuesta fuera de contrato es RemoteFailure', () async {
    final backend = StubBackend((_) => const StubResponse(200, {'nope': 1}));
    await expectLater(
      CaptureApi(stubDio(backend)).ingest([notification]),
      throwsA(isA<RemoteFailure>()),
    );
  });
}
