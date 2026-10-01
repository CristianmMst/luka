import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/application/sync_engine.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/rejected_change.dart';
import 'package:luka/features/sync/presentation/sync_format.dart';
import 'package:luka/features/sync/presentation/sync_sheet.dart';

import '../../../helpers/pump_app.dart';

class _Coordinator extends SyncCoordinator {
  _Coordinator(this._status);

  final SyncStatus _status;
  final retried = <String>[];
  final discarded = <String>[];
  int syncs = 0;

  @override
  SyncStatus build() => _status;

  @override
  Future<SyncRunResult> sync() async {
    syncs++;
    return SyncRunResult.synced;
  }

  @override
  Future<void> retryRejected(String id) async => retried.add(id);

  @override
  Future<void> discardRejected(String id) async => discarded.add(id);
}

final _now = DateTime(2026, 9, 29, 12);

final _changes = [
  const RejectedChange(
    seq: 1,
    op: OutboxOperation.deleteTransaction(id: 'tx-1'),
    reason: 'not_found',
    merchant: 'Éxito',
    amountCents: 4590000,
    direction: 'debit',
  ),
  const RejectedChange(
    seq: 2,
    op: OutboxOperation.discardReview(rawMessageId: 'raw-1'),
    reason: '500',
  ),
];

void main() {
  Future<_Coordinator> pumpSheet(
    WidgetTester tester, {
    List<RejectedChange> changes = const [],
    SyncStatus status = const SyncStatus(),
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final coordinator = _Coordinator(
      status.copyWith(lastSyncedAt: _now.subtract(const Duration(minutes: 3))),
    );
    await tester.pumpApp(
      Scaffold(body: SyncSheet(now: () => _now)),
      themeMode: themeMode,
      overrides: [
        syncCoordinatorProvider.overrideWith(() => coordinator),
        rejectedChangesProvider.overrideWith((ref) => Stream.value(changes)),
      ],
    );
    await tester.pumpAndSettle();
    return coordinator;
  }

  group('syncAgo', () {
    testWidgets('minutos, horas y días', (tester) async {
      await tester.pumpApp(const SizedBox());
      final l10n = AppLocalizations.of(tester.element(find.byType(SizedBox)));
      final now = DateTime(2026, 9, 29, 12);
      String ago(Duration d) => syncAgo(l10n, now.subtract(d), now);

      expect(ago(const Duration(seconds: 20)), 'hace un momento');
      expect(ago(const Duration(minutes: 3)), 'hace 3 min');
      expect(ago(const Duration(hours: 2)), 'hace 2 h');
      expect(ago(const Duration(days: 1)), 'hace 1 día');
      expect(ago(const Duration(days: 4)), 'hace 4 días');
    });
  });

  testWidgets('sin rechazados dice que todo está enviado', (tester) async {
    await pumpSheet(tester);

    expect(find.text('hace 3 min'), findsOneWidget);
    expect(find.text('Todo está enviado.'), findsOneWidget);
  });

  testWidgets('"Sincronizar ahora" corre un ciclo', (tester) async {
    final coordinator = await pumpSheet(tester);

    await tester.tap(find.text('Sincronizar ahora'));
    await tester.pump();

    expect(coordinator.syncs, 1);
  });

  testWidgets('lista los rechazados con su motivo y los resuelve', (
    tester,
  ) async {
    final coordinator = await pumpSheet(tester, changes: _changes);

    expect(find.text('2 cambios no se pudieron enviar'), findsOneWidget);
    expect(
      find.textContaining('Eliminar un movimiento · Éxito'),
      findsOneWidget,
    );
    expect(find.text('Lo que usaba ya no existe.'), findsOneWidget);
    expect(find.text('Descartar de Revisión'), findsOneWidget);
    expect(find.text('El servidor no lo aceptó.'), findsOneWidget);

    await tester.tap(find.byTooltip('Reintentar: Eliminar un movimiento'));
    await tester.tap(find.byTooltip('Descartar: Descartar de Revisión'));
    await tester.pump();

    expect(coordinator.retried, ['tx-1']);
    expect(coordinator.discarded, ['raw-1']);
  });

  testWidgets('las acciones miden 48 dp o más', (tester) async {
    await pumpSheet(tester, changes: _changes);

    final size = tester.getSize(
      find.byTooltip('Reintentar: Eliminar un movimiento'),
    );
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  group('goldens', () {
    setUpAll(loadBrandFonts);

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('sincronizacion ${mode.name}', tags: ['golden'], (
        tester,
      ) async {
        await pumpSheet(tester, themeMode: mode);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/sync_sheet_${mode.name}.png'),
        );
      });
    }
  });
}
