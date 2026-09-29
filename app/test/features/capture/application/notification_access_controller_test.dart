import 'dart:async';

import 'package:finanzia/features/capture/application/capture_flusher.dart';
import 'package:finanzia/features/capture/application/notification_access_controller.dart';
import 'package:finanzia/features/capture/domain/capture_ports.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSource extends Mock implements NotificationSource {}

void main() {
  late _MockSource source;
  late StreamController<void> ticks;
  late ProviderContainer container;

  setUp(() {
    source = _MockSource();
    ticks = StreamController<void>.broadcast();
    when(() => source.isSupported).thenReturn(true);
    when(() => source.readsNotifications).thenReturn(true);
    when(() => source.isPermissionGranted()).thenAnswer((_) async => false);
    when(() => source.openPermissionSettings()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        notificationSourceProvider.overrideWithValue(source),
        foregroundTicksProvider.overrideWithValue(ticks.stream),
      ],
    );
    addTearDown(container.dispose);
    container.listen(notificationAccessProvider, (_, _) {});
  });

  test('lee el permiso del sistema', () async {
    expect(
      await container.read(notificationAccessProvider.future),
      NotificationAccess.denied,
    );
  });

  test('al volver a primer plano vuelve a consultar (AC-3.4)', () async {
    await container.read(notificationAccessProvider.future);
    when(() => source.isPermissionGranted()).thenAnswer((_) async => true);

    ticks.add(null);
    await pumpEventQueue();

    expect(
      container.read(notificationAccessProvider).value,
      NotificationAccess.granted,
    );
  });

  test('abre el ajuste del sistema', () async {
    await container.read(notificationAccessProvider.future);
    await container.read(notificationAccessProvider.notifier).openSettings();
    verify(() => source.openPermissionSettings()).called(1);
  });

  test('sin listener es unsupported y no consulta', () async {
    await container.read(notificationAccessProvider.future);
    clearInteractions(source);
    when(() => source.isSupported).thenReturn(false);
    when(() => source.readsNotifications).thenReturn(false);
    container.invalidate(notificationAccessProvider);

    expect(
      await container.read(notificationAccessProvider.future),
      NotificationAccess.unsupported,
    );
    verifyNever(() => source.isPermissionGranted());
  });

  test('Android lee notificaciones: no hay captura de Apple Pay', () {
    expect(container.read(notificationCaptureSupportedProvider), isTrue);
    expect(container.read(walletCaptureSupportedProvider), isFalse);
  });

  test('iOS: cola de Apple Pay sin listener de notificaciones', () async {
    when(() => source.readsNotifications).thenReturn(false);
    container
      ..invalidate(notificationCaptureSupportedProvider)
      ..invalidate(walletCaptureSupportedProvider)
      ..invalidate(notificationAccessProvider);

    expect(container.read(notificationCaptureSupportedProvider), isFalse);
    expect(container.read(walletCaptureSupportedProvider), isTrue);
    expect(
      await container.read(notificationAccessProvider.future),
      NotificationAccess.unsupported,
    );
  });
}
