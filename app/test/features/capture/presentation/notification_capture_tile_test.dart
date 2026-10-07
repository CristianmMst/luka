import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/capture/domain/capture_ports.dart';
import 'package:luka/features/capture/presentation/widgets/notification_capture_tile.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockSource extends Mock implements NotificationSource {}

void main() {
  late _MockSource source;
  late StreamController<void> ticks;

  setUp(() {
    source = _MockSource();
    ticks = StreamController<void>.broadcast();
    when(() => source.isSupported).thenReturn(true);
    when(() => source.readsNotifications).thenReturn(true);
    when(() => source.isPermissionGranted()).thenAnswer((_) async => false);
    when(() => source.openPermissionSettings()).thenAnswer((_) async {});
  });

  Future<void> pumpTile(WidgetTester tester) async {
    await tester.pumpApp(
      const Scaffold(body: NotificationCaptureTile()),
      overrides: [
        notificationSourceProvider.overrideWithValue(source),
        foregroundTicksProvider.overrideWithValue(ticks.stream),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('inactivo: la divulgación va antes del ajuste del sistema', (
    tester,
  ) async {
    await pumpTile(tester);
    expect(find.text('Notificaciones del banco'), findsOneWidget);
    expect(find.textContaining('Inactivo'), findsOneWidget);

    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();

    expect(find.text('Registra tus pagos al instante'), findsOneWidget);
    expect(find.textContaining('Ignoramos todo lo demás'), findsOneWidget);
    verifyNever(() => source.openPermissionSettings());

    await tester.ensureVisible(find.text('Ir a los ajustes'));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Ir a los ajustes'));
    await tester.pumpAndSettle();
    verify(() => source.openPermissionSettings()).called(1);
    expect(find.text('Registra tus pagos al instante'), findsNothing);
  });

  testWidgets('"Ahora no" cierra sin abrir el ajuste', (tester) async {
    await pumpTile(tester);
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    verifyNever(() => source.openPermissionSettings());
  });

  testWidgets('al volver del ajuste queda activo y ofrece administrar', (
    tester,
  ) async {
    await pumpTile(tester);
    when(() => source.isPermissionGranted()).thenAnswer((_) async => true);

    ticks.add(null);
    await tester.pumpAndSettle();

    expect(find.textContaining('Activo'), findsOneWidget);
    await tester.tap(find.text('Administrar'));
    await tester.pumpAndSettle();
    // Ya dio el permiso: va directo al ajuste, sin divulgación.
    verify(() => source.openPermissionSettings()).called(1);
  });

  testWidgets('sin listener (iOS) no muestra nada', (tester) async {
    when(() => source.isSupported).thenReturn(false);
    when(() => source.readsNotifications).thenReturn(false);
    await pumpTile(tester);
    expect(find.text('Notificaciones del banco'), findsNothing);
  });
}
