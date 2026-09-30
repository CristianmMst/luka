import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/domain/auth_repository.dart';
import 'package:luka/features/auth/domain/entities/user.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/capture/application/capture_health.dart';
import 'package:luka/features/capture/application/notification_access_controller.dart';
import 'package:luka/features/capture/domain/capture_grant_store.dart';
import 'package:luka/features/capture/domain/capture_ports.dart';
import 'package:luka/features/gmail/application/gmail_controller.dart';
import 'package:luka/features/gmail/domain/gmail_connection.dart';
import 'package:luka/features/gmail/domain/gmail_repository.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockGmail extends Mock implements GmailRepository {}

class _MockSource extends Mock implements NotificationSource {}

class _MockGrants extends Mock implements CaptureGrantStore {}

const _ana = User(
  id: 'u-1',
  email: 'ana@example.com',
  status: UserStatus.active,
);

const _active = GmailConnectionInfo(status: GmailStatus.active);

void main() {
  late _MockAuth auth;
  late _MockGmail gmail;
  late _MockSource source;
  late _MockGrants grants;
  late StreamController<void> ticks;
  late DateTime now;
  late bool granted;
  late ProviderContainer container;

  setUp(() {
    auth = _MockAuth();
    gmail = _MockGmail();
    source = _MockSource();
    grants = _MockGrants();
    ticks = StreamController<void>.broadcast();
    now = DateTime.utc(2026, 9, 28, 12);
    granted = false;
    when(() => auth.restoreSession()).thenAnswer((_) async => _ana);
    when(() => auth.sessionExpired).thenAnswer((_) => const Stream.empty());
    when(() => gmail.status()).thenAnswer((_) async => _active);
    when(() => source.isSupported).thenReturn(true);
    when(() => source.readsNotifications).thenReturn(true);
    when(() => source.isPermissionGranted()).thenAnswer((_) async => false);
    when(() => grants.wasGranted(any())).thenAnswer((_) async => granted);
    when(() => grants.markGranted(any())).thenAnswer((_) async {
      granted = true;
    });
  });

  tearDown(() async {
    container.dispose();
    await ticks.close();
  });

  Future<void> settle() async {
    await pumpEventQueue();
    await container.read(gmailControllerProvider.future);
    await container.read(notificationAccessProvider.future);
    await container.read(captureWasGrantedProvider.future);
    await pumpEventQueue();
  }

  Future<CaptureHealth> health() async {
    container =
        ProviderContainer(
            overrides: [
              authRepositoryProvider.overrideWithValue(auth),
              gmailRepositoryProvider.overrideWithValue(gmail),
              notificationSourceProvider.overrideWithValue(source),
              captureGrantStoreProvider.overrideWithValue(grants),
              foregroundTicksProvider.overrideWithValue(ticks.stream),
              captureClockProvider.overrideWithValue(() => now),
            ],
          )
          // El Inicio la escucha así: la mantiene viva.
          ..listen(captureHealthProvider, (_, _) {});
    await settle();
    return container.read(captureHealthProvider);
  }

  Future<CaptureHealth> resume() async {
    ticks.add(null);
    await settle();
    return container.read(captureHealthProvider);
  }

  test('sin nada roto → ok', () async {
    when(() => source.isPermissionGranted()).thenAnswer((_) async => true);
    expect(await health(), CaptureHealth.ok);
  });

  test('quien nunca dio el acceso no ve "se detuvo"', () async {
    expect(await health(), CaptureHealth.ok);
    verifyNever(() => grants.markGranted(any()));
  });

  test('ver el acceso concedido lo recuerda; perderlo lo avisa', () async {
    when(() => source.isPermissionGranted()).thenAnswer((_) async => true);
    expect(await health(), CaptureHealth.ok);
    verify(() => grants.markGranted('u-1')).called(1);

    when(() => source.isPermissionGranted()).thenAnswer((_) async => false);
    expect(await resume(), CaptureHealth.notificationsLost);

    when(() => source.isPermissionGranted()).thenAnswer((_) async => true);
    expect(await resume(), CaptureHealth.ok);
  });

  test('concedido en una sesión anterior y perdido → avisa al abrir', () async {
    granted = true;
    expect(await health(), CaptureHealth.notificationsLost);
  });

  test('conceder mientras la app corre también se recuerda', () async {
    expect(await health(), CaptureHealth.ok);

    when(() => source.isPermissionGranted()).thenAnswer((_) async => true);
    await resume();

    verify(() => grants.markGranted('u-1')).called(1);
    expect(container.read(captureWasGrantedProvider).value, isTrue);
  });

  test('Gmail revocado → avisa, y va antes que notificaciones', () async {
    granted = true;
    when(() => gmail.status()).thenAnswer(
      (_) async => const GmailConnectionInfo(status: GmailStatus.revoked),
    );
    expect(await health(), CaptureHealth.gmailRevoked);
  });

  test('Gmail con error no avisa: el backend lo reintenta solo', () async {
    when(() => source.isPermissionGranted()).thenAnswer((_) async => true);
    when(() => gmail.status()).thenAnswer(
      (_) async => const GmailConnectionInfo(status: GmailStatus.error),
    );
    expect(await health(), CaptureHealth.ok);
  });

  test('en iOS no hay acceso que perder', () async {
    granted = true;
    when(() => source.isSupported).thenReturn(false);
    when(() => source.readsNotifications).thenReturn(false);
    expect(await health(), CaptureHealth.ok);
  });

  test('al volver a primer plano relee Gmail como mucho cada 15 min', () async {
    when(() => source.isPermissionGranted()).thenAnswer((_) async => true);
    expect(await health(), CaptureHealth.ok);
    verify(() => gmail.status()).called(1);

    now = now.add(const Duration(minutes: 5));
    await resume();
    verifyNever(() => gmail.status());

    when(() => gmail.status()).thenAnswer(
      (_) async => const GmailConnectionInfo(status: GmailStatus.revoked),
    );
    now = now.add(CaptureHealthController.gmailRecheck);
    expect(await resume(), CaptureHealth.gmailRevoked);
    verify(() => gmail.status()).called(1);

    now = now.add(const Duration(minutes: 1));
    await resume();
    verifyNever(() => gmail.status());
  });
}
