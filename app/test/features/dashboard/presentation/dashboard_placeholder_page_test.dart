import 'dart:async';

import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/auth_repository.dart';
import 'package:finanzia/features/dashboard/presentation/dashboard_placeholder_page.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AuthRepository {}

class _FixedCoordinator extends SyncCoordinator {
  _FixedCoordinator(this._status);

  final SyncStatus _status;

  @override
  SyncStatus build() => _status;
}

void main() {
  late _MockRepository repository;
  late StreamController<void> expired;
  final synced = DateTime.utc(2026, 9, 23, 12);

  setUp(() {
    repository = _MockRepository();
    expired = StreamController<void>.broadcast();
    when(() => repository.sessionExpired).thenAnswer((_) => expired.stream);
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
  });

  tearDown(() => expired.close());

  final table = <(String, SyncStatus, String)>[
    (
      'en curso',
      const SyncStatus(running: true, rejected: 2),
      'Sincronizando…',
    ),
    (
      'sin red',
      const SyncStatus(offline: true),
      'Sin conexión · los cambios se enviarán al volver',
    ),
    (
      'nunca sincronizó',
      const SyncStatus(),
      'Aún no sincronizado',
    ),
    (
      'al día',
      SyncStatus(lastSyncedAt: synced),
      'Sincronizado · al día',
    ),
    (
      'con pendientes',
      SyncStatus(lastSyncedAt: synced, pending: 3),
      'Sincronizado · 3 pendientes',
    ),
    (
      'un rechazado',
      SyncStatus(lastSyncedAt: synced, rejected: 1),
      '1 cambio no se pudo enviar',
    ),
    (
      'varios rechazados, aunque nunca sincronizó',
      const SyncStatus(rejected: 4),
      '4 cambios no se pudieron enviar',
    ),
  ];

  for (final (name, status, text) in table) {
    testWidgets('línea de sync: $name', (tester) async {
      await tester.pumpApp(
        const DashboardPlaceholderPage(),
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          syncCoordinatorProvider.overrideWith(
            () => _FixedCoordinator(status),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(text), findsOneWidget);
    });
  }
}
