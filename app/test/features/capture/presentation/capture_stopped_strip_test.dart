import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/capture/application/capture_health.dart';
import 'package:luka/features/capture/domain/capture_ports.dart';
import 'package:luka/features/capture/presentation/widgets/capture_stopped_strip.dart';
import 'package:luka/features/gmail/application/gmail_controller.dart';
import 'package:luka/features/gmail/domain/gmail_connection.dart';
import 'package:luka/features/gmail/domain/gmail_failure.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/capture_health.dart';
import '../../../helpers/pump_app.dart';

class _MockSource extends Mock implements NotificationSource {}

class _FakeGmail extends GmailController {
  _FakeGmail({required this.connects, this.failure});

  final bool connects;
  final GmailFailure? failure;
  int calls = 0;

  @override
  Future<GmailState> build() async => GmailState(
    info: const GmailConnectionInfo(status: GmailStatus.revoked),
    failure: failure,
  );

  @override
  Future<bool> connect() async {
    calls++;
    return connects;
  }
}

void main() {
  late _MockSource source;

  setUp(() {
    source = _MockSource();
    when(() => source.isSupported).thenReturn(true);
    when(() => source.readsNotifications).thenReturn(true);
    when(() => source.isPermissionGranted()).thenAnswer((_) async => false);
    when(() => source.openPermissionSettings()).thenAnswer((_) async {});
  });

  Future<void> pumpStrip(
    WidgetTester tester,
    CaptureHealth health, {
    List<Override> overrides = const [],
  }) async {
    await tester.pumpApp(
      const Scaffold(body: CaptureStoppedStrip()),
      overrides: [
        captureHealthProvider.overrideWith(() => FixedCaptureHealth(health)),
        notificationSourceProvider.overrideWithValue(source),
        foregroundTicksProvider.overrideWithValue(const Stream.empty()),
        ...overrides,
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('con la captura sana no ocupa espacio', (tester) async {
    await pumpStrip(tester, CaptureHealth.ok);

    expect(tester.getSize(find.byType(CaptureStoppedStrip)).height, 0);
  });

  testWidgets('acceso perdido: "Reactivar" pasa por la divulgación y abre '
      'el ajuste', (tester) async {
    await pumpStrip(tester, CaptureHealth.notificationsLost);

    expect(find.bySemanticsLabel('Captura detenida. Reactivar'), findsOne);
    expect(
      tester.getSize(find.byType(InkWell)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ir a los ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir a los ajustes'));
    await tester.pumpAndSettle();

    verify(() => source.openPermissionSettings()).called(1);
  });

  testWidgets('Gmail revocado: "Reconectar" conecta', (tester) async {
    final gmail = _FakeGmail(connects: true);
    await pumpStrip(
      tester,
      CaptureHealth.gmailRevoked,
      overrides: [gmailControllerProvider.overrideWith(() => gmail)],
    );

    expect(find.bySemanticsLabel('Gmail se desconectó. Reconectar'), findsOne);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(gmail.calls, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('si reconectar falla, lo dice', (tester) async {
    final gmail = _FakeGmail(
      connects: false,
      failure: const GmailNetworkFailure(),
    );
    await pumpStrip(
      tester,
      CaptureHealth.gmailRevoked,
      overrides: [gmailControllerProvider.overrideWith(() => gmail)],
    );

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos reconectar Gmail. Inténtalo desde Ajustes.'),
      findsOneWidget,
    );
  });
}
