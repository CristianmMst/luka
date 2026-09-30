import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/gmail/domain/gmail_connection.dart';
import 'package:luka/features/gmail/domain/gmail_failure.dart';

void main() {
  group('GmailConnectionInfo', () {
    test('disconnected no tiene cuenta ni fechas', () {
      const info = GmailConnectionInfo.disconnected;
      expect(info.status, GmailStatus.disconnected);
      expect(info.email, isNull);
      expect(info.lastSyncAt, isNull);
      expect(info.watchExpiresAt, isNull);
      expect(info.isConnected, isFalse);
      expect(info.needsReconnect, isFalse);
    });

    test('active está conectada y no pide reconectar', () {
      const info = GmailConnectionInfo(
        status: GmailStatus.active,
        email: 'ana@gmail.com',
      );
      expect(info.isConnected, isTrue);
      expect(info.needsReconnect, isFalse);
    });

    test('revoked y error piden reconectar', () {
      for (final status in [GmailStatus.revoked, GmailStatus.error]) {
        final info = GmailConnectionInfo(status: status);
        expect(info.isConnected, isTrue, reason: '$status');
        expect(info.needsReconnect, isTrue, reason: '$status');
      }
    });

    test('igualdad por valor', () {
      final at = DateTime.utc(2026, 9, 30);
      expect(
        GmailConnectionInfo(status: GmailStatus.active, watchExpiresAt: at),
        GmailConnectionInfo(status: GmailStatus.active, watchExpiresAt: at),
      );
    });
  });

  group('GmailFailure', () {
    test('rate limited conserva el retry-after', () {
      const failure = GmailRateLimited(Duration(seconds: 30));
      expect(failure.retryAfter, const Duration(seconds: 30));
      expect(const GmailRateLimited().retryAfter, isNull);
    });

    test('los fallos llevan su detalle', () {
      expect(const GmailMisconfigured('x').detail, 'x');
      expect(const GmailUnexpected('boom').cause, 'boom');
      expect(const GmailUnexpected().cause, isNull);
    });
  });
}
