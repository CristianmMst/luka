import 'package:finanzia/features/capture/data/method_channel_notification_source.dart';
import 'package:finanzia/features/capture/domain/captured_notification.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('co.finanzia/capture');
  final calls = <MethodCall>[];
  late Object? Function(MethodCall) reply;
  final source = MethodChannelNotificationSource();

  setUp(() {
    calls.clear();
    reply = (_) => null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return reply(call);
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('es soportado y consulta el permiso', () async {
    reply = (_) => true;
    expect(source.isSupported, isTrue);
    expect(await source.isPermissionGranted(), isTrue);
    expect(calls.single.method, 'isPermissionGranted');
  });

  test('pending decodifica las filas de la cola nativa', () async {
    reply = (_) => [
      {
        'id': 3,
        'package': 'com.google.android.apps.messaging',
        'channel': 'sms_notification',
        'postedAtMs': DateTime.utc(2026, 9, 25, 17).millisecondsSinceEpoch,
        'offsetMinutes': -300,
        'title': 'Bancolombia',
        'text': r'Compraste $5.000',
      },
      {
        'id': 4,
        'package': 'com.nequi.MobileApp',
        'channel': 'notification',
        'postedAtMs': DateTime.utc(2026, 9, 25, 18).millisecondsSinceEpoch,
        'offsetMinutes': -300,
        'title': null,
        'text': r'Recibiste $20.000',
      },
    ];

    final items = await source.pending(50);

    expect(calls.single.method, 'pending');
    expect(calls.single.arguments, {'limit': 50});
    expect(items, [
      CapturedNotification(
        id: 3,
        package: 'com.google.android.apps.messaging',
        channel: CaptureChannel.smsNotification,
        postedAt: DateTime.utc(2026, 9, 25, 17),
        utcOffset: const Duration(hours: -5),
        title: 'Bancolombia',
        text: r'Compraste $5.000',
      ),
      CapturedNotification(
        id: 4,
        package: 'com.nequi.MobileApp',
        channel: CaptureChannel.notification,
        postedAt: DateTime.utc(2026, 9, 25, 18),
        utcOffset: const Duration(hours: -5),
        text: r'Recibiste $20.000',
      ),
    ]);
    expect(items.first.postedAt.isUtc, isTrue);
  });

  test('setConfig, claimFor, remove, clear y abrir ajustes', () async {
    await source.setConfig(
      const CaptureConfig(
        version: 2,
        bankingApps: ['com.bancolombia.app'],
        messagesApps: ['com.google.android.apps.messaging'],
        smsSenderPatterns: ['(?i)bancolombia'],
      ),
    );
    await source.claimFor('u-1');
    await source.remove([1, 2]);
    await source.clear();
    await source.openPermissionSettings();

    expect(
      [for (final c in calls) c.method],
      [
        'setConfig',
        'claimFor',
        'remove',
        'clear',
        'openPermissionSettings',
      ],
    );
    expect(calls[0].arguments, {
      'bankingApps': ['com.bancolombia.app'],
      'messagesApps': ['com.google.android.apps.messaging'],
      'smsSenderPatterns': ['(?i)bancolombia'],
    });
    expect(calls[1].arguments, {'userId': 'u-1'});
    expect(calls[2].arguments, {
      'ids': [1, 2],
    });
  });

  test('una fila con canal desconocido falla en vez de adivinar', () async {
    reply = (_) => [
      {
        'id': 1,
        'package': 'x',
        'channel': 'otro',
        'postedAtMs': 0,
        'offsetMinutes': 0,
        'title': null,
        'text': 't',
      },
    ];
    await expectLater(source.pending(1), throwsA(isA<FormatException>()));
  });

  test('el no-op de iOS no llama al canal', () async {
    const noop = NoopNotificationSource();
    expect(noop.isSupported, isFalse);
    expect(await noop.isPermissionGranted(), isFalse);
    expect(await noop.pending(50), isEmpty);
    await noop.setConfig(
      const CaptureConfig(
        version: 1,
        bankingApps: [],
        messagesApps: [],
        smsSenderPatterns: [],
      ),
    );
    await noop.claimFor('u');
    await noop.remove([1]);
    await noop.clear();
    await noop.openPermissionSettings();
    expect(calls, isEmpty);
  });
}
