import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/capture/domain/capture_rules.dart';
import 'package:luka/features/capture/domain/captured_notification.dart';
import 'package:luka/features/sync/domain/sync_rules.dart';

void main() {
  final postedAt = DateTime.utc(2026, 9, 25, 19, 30, 12);

  CapturedNotification item({
    String package = 'com.bancolombia.app',
    DateTime? at,
    String text = r'Compraste $12.000 en EXITO',
  }) => CapturedNotification(
    id: 1,
    package: package,
    channel: CaptureChannel.notification,
    postedAt: at ?? postedAt,
    utcOffset: const Duration(hours: -5),
    title: 'Bancolombia',
    text: text,
  );

  group('clientHash', () {
    test('es sha256 hex en minúsculas de paquete|minuto|texto', () {
      final minute = postedAt.millisecondsSinceEpoch ~/ 60000;
      final expected = sha256
          .convert(
            utf8.encode(
              'com.bancolombia.app|$minute|Compraste \$12.000 en EXITO',
            ),
          )
          .toString();

      expect(item().clientHash, expected);
      expect(item().clientHash, matches(RegExp(r'^[a-f0-9]{64}$')));
    });

    test('la misma notificación re-publicada en el mismo minuto no cambia', () {
      final later = postedAt.add(const Duration(seconds: 40));
      expect(item(at: later).clientHash, item().clientHash);
    });

    test('otro minuto, otro texto u otro paquete dan otro hash', () {
      final base = item().clientHash;
      expect(
        item(at: postedAt.add(const Duration(minutes: 1))).clientHash,
        isNot(base),
      );
      expect(item(text: r'Compraste $13.000').clientHash, isNot(base));
      expect(item(package: 'com.nequi.MobileApp').clientHash, isNot(base));
    });

    test('no depende de la zona del dispositivo, solo del instante', () {
      final local = item().copyWith(utcOffset: Duration.zero);
      expect(local.clientHash, item().clientHash);
    });
  });

  group('classifyIngestFailure', () {
    test('red, 429, 5xx y 409 con Retry-After se reintentan', () {
      expect(
        classifyIngestFailure(const RemoteFailure.network()),
        IngestOutcome.retryLater,
      );
      for (final status in [429, 500, 503]) {
        expect(
          classifyIngestFailure(RemoteFailure(statusCode: status)),
          IngestOutcome.retryLater,
        );
      }
      expect(
        classifyIngestFailure(
          const RemoteFailure(
            statusCode: 409,
            retryAfter: Duration(seconds: 1),
          ),
        ),
        IngestOutcome.retryLater,
      );
    });

    test('401 termina el ciclo', () {
      expect(
        classifyIngestFailure(const RemoteFailure(statusCode: 401)),
        IngestOutcome.sessionEnded,
      );
    });

    test('otro 4xx es un lote inválido', () {
      for (final status in [400, 409, 413]) {
        expect(
          classifyIngestFailure(RemoteFailure(statusCode: status)),
          IngestOutcome.invalid,
        );
      }
    });
  });
}
