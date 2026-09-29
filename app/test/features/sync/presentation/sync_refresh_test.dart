import 'dart:async';

import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/application/sync_engine.dart';
import 'package:finanzia/features/sync/presentation/sync_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

class _CountingCoordinator extends SyncCoordinator {
  _CountingCoordinator(this.cycle);

  final Completer<SyncRunResult> cycle;
  int calls = 0;

  @override
  SyncStatus build() => const SyncStatus();

  @override
  Future<SyncRunResult> sync() {
    calls++;
    return cycle.future;
  }
}

void main() {
  // Se crean dentro de cada test: el Completer tiene que vivir en la zona
  // del test (tiempo simulado) para que el indicador vea el ciclo terminar.
  late Completer<SyncRunResult> cycle;
  late _CountingCoordinator coordinator;

  Future<void> pump(WidgetTester tester, Widget child) {
    cycle = Completer<SyncRunResult>();
    coordinator = _CountingCoordinator(cycle);
    return tester.pumpApp(
      Scaffold(body: child),
      overrides: [syncCoordinatorProvider.overrideWith(() => coordinator)],
    );
  }

  Future<void> pullDown(WidgetTester tester, Finder from) async {
    await tester.fling(from, const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('deslizar una lista sincroniza y el indicador espera el ciclo', (
    tester,
  ) async {
    await pump(
      tester,
      SyncRefresh(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [ListTile(title: Text('movimiento'))],
        ),
      ),
    );

    await pullDown(tester, find.text('movimiento'));

    expect(coordinator.calls, 1);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    cycle.complete(SyncRunResult.synced);
    await tester.pumpAndSettle();
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('un estado sin lista (vacío o error) también se puede deslizar', (
    tester,
  ) async {
    await pump(
      tester,
      const SyncRefresh.fill(child: Center(child: Text('Nada por revisar'))),
    );

    await pullDown(tester, find.text('Nada por revisar'));

    expect(coordinator.calls, 1);
    cycle.complete(SyncRunResult.offline);
    await tester.pumpAndSettle();
  });
}
