import 'dart:async';

import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/auth_repository.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/application/sync_engine.dart';
import 'package:finanzia/features/sync/domain/outbox_operation.dart';
import 'package:finanzia/features/sync/domain/sync_ports.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AuthRepository {}

class _MockStore extends Mock implements SyncStore {}

class _MockRemote extends Mock implements SyncRemote {}

class _Engine extends Mock implements SyncEngine {}

const _ana = User(
  id: 'u-1',
  email: 'ana@example.com',
  status: UserStatus.active,
  displayName: 'Ana',
);

void main() {
  late _MockRepository repository;
  late _MockStore store;
  late _Engine engine;
  late StreamController<void> expired;
  late StreamController<SyncCounters> counters;
  late StreamController<bool> connectivity;
  late StreamController<void> ticks;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const OutboxOperation.deleteTransaction(id: 'f'));
  });

  setUp(() {
    repository = _MockRepository();
    store = _MockStore();
    engine = _Engine();
    expired = StreamController<void>.broadcast();
    counters = StreamController<SyncCounters>.broadcast();
    connectivity = StreamController<bool>.broadcast();
    ticks = StreamController<void>.broadcast();

    when(() => repository.sessionExpired).thenAnswer((_) => expired.stream);
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    when(() => repository.signOut()).thenAnswer((_) async {});
    when(() => store.watchCounters()).thenAnswer((_) => counters.stream);
    when(() => store.claimFor(any())).thenAnswer((_) async {});
    when(() => store.clearAll()).thenAnswer((_) async {});
    when(() => store.enqueue(any())).thenAnswer((_) async {});
    when(() => engine.run()).thenAnswer((_) async => SyncRunResult.synced);

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        syncStoreProvider.overrideWithValue(store),
        syncRemoteProvider.overrideWithValue(_MockRemote()),
        syncEngineProvider.overrideWithValue(engine),
        connectivityProvider.overrideWithValue(connectivity.stream),
        foregroundTicksProvider.overrideWithValue(ticks.stream),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await expired.close();
    await counters.close();
    await connectivity.close();
    await ticks.close();
  });

  SyncCoordinator coordinator() =>
      container.read(syncCoordinatorProvider.notifier);

  SyncStatus status() => container.read(syncCoordinatorProvider);

  /// Monta el coordinador (como `FinanziaApp`) y deja resolver la sesión.
  Future<void> start({User? user}) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => user);
    container.listen(syncCoordinatorProvider, (_, _) {});
    await pumpEventQueue();
  }

  test(
    'al autenticarse reclama la base para el usuario y sincroniza',
    () async {
      await start(user: _ana);

      verifyInOrder([() => store.claimFor('u-1'), () => engine.run()]);
      verifyNoMoreInteractions(engine);
      expect(status().running, isFalse);
      expect(status().offline, isFalse);
    },
  );

  test('sin sesión no sincroniza', () async {
    await start();

    ticks.add(null);
    connectivity.add(true);
    await pumpEventQueue();

    expect(await coordinator().sync(), SyncRunResult.skipped);
    verifyNever(() => engine.run());
    verifyNever(() => store.claimFor(any()));
  });

  test('signOut borra la base', () async {
    await start(user: _ana);

    await container.read(authControllerProvider.notifier).signOut();
    await pumpEventQueue();

    verify(() => store.clearAll()).called(1);
    clearInteractions(engine);
    ticks.add(null);
    await pumpEventQueue();
    verifyNever(() => engine.run());
  });

  test('arrancar sin sesión no borra la base', () async {
    await start();

    verifyNever(() => store.clearAll());
  });

  test(
    'signOut con un ciclo en curso espera a que termine para borrar',
    () async {
      await start(user: _ana);
      final cycle = Completer<SyncRunResult>();
      when(() => engine.run()).thenAnswer((_) => cycle.future);
      final inflight = coordinator().sync();

      await container.read(authControllerProvider.notifier).signOut();
      await pumpEventQueue();
      verifyNever(() => store.clearAll());

      cycle.complete(SyncRunResult.synced);
      await inflight;
      await pumpEventQueue();
      verify(() => store.clearAll()).called(1);
    },
  );

  test('otro usuario entra tras el ciclo en curso y el borrado', () async {
    const bea = User(
      id: 'u-2',
      email: 'bea@example.com',
      status: UserStatus.active,
    );
    await start(user: _ana);
    final cycle = Completer<SyncRunResult>();
    when(() => engine.run()).thenAnswer((_) => cycle.future);
    unawaited(coordinator().sync());

    await container.read(authControllerProvider.notifier).signOut();
    container.read(authControllerProvider.notifier).signedIn(bea);
    await pumpEventQueue();
    verifyNever(() => store.claimFor('u-2'));

    when(() => engine.run()).thenAnswer((_) async => SyncRunResult.synced);
    cycle.complete(SyncRunResult.synced);
    await pumpEventQueue();
    verifyInOrder([
      () => store.clearAll(),
      () => store.claimFor('u-2'),
      () => engine.run(),
    ]);
  });

  test('un ciclo fallido no bloquea el cambio de sesión', () async {
    await start(user: _ana);
    final cycle = Completer<SyncRunResult>();
    when(() => engine.run()).thenAnswer((_) => cycle.future);
    unawaited(
      coordinator().sync().catchError((Object _) => SyncRunResult.skipped),
    );

    await container.read(authControllerProvider.notifier).signOut();
    cycle.completeError(StateError('fallo'));
    await pumpEventQueue();

    verify(() => store.clearAll()).called(1);
  });

  test('sesión expirada conserva la base y deja de sincronizar', () async {
    await start(user: _ana);

    expired.add(null);
    await pumpEventQueue();

    verifyNever(() => store.clearAll());
    expect(await coordinator().sync(), SyncRunResult.skipped);
  });

  test('reconectar y cada tick disparan sync', () async {
    await start(user: _ana);

    connectivity.add(true);
    await pumpEventQueue();
    ticks.add(null);
    await pumpEventQueue();

    verify(() => engine.run()).called(3);
    expect(status().offline, isFalse);
  });

  test('sin red marca offline y no dispara', () async {
    await start(user: _ana);
    clearInteractions(engine);

    connectivity.add(false);
    await pumpEventQueue();

    expect(status().offline, isTrue);
    verifyNever(() => engine.run());

    connectivity.add(true);
    await pumpEventQueue();
    expect(status().offline, isFalse);
    verify(() => engine.run()).called(1);
  });

  test('un ciclo que no llega al servidor deja el estado offline', () async {
    when(() => engine.run()).thenAnswer((_) async => SyncRunResult.offline);
    await start(user: _ana);

    expect(status().offline, isTrue);
    expect(status().running, isFalse);
  });

  test(
    'single-flight: llamadas concurrentes comparten ciclo '
    'y piden uno más al terminar',
    () async {
      await start(user: _ana);
      clearInteractions(engine);
      final cycle = Completer<SyncRunResult>();
      when(() => engine.run()).thenAnswer((_) => cycle.future);

      final first = coordinator().sync();
      final second = coordinator().sync();
      final third = coordinator().sync();
      await pumpEventQueue();
      expect(status().running, isTrue);
      verify(() => engine.run()).called(1);

      cycle.complete(SyncRunResult.synced);
      final results = await Future.wait<SyncRunResult>([
        first,
        second,
        third,
      ]);

      expect(results, everyElement(SyncRunResult.synced));
      verify(() => engine.run()).called(1);
      expect(status().running, isFalse);
    },
  );

  test(
    'si el ciclo no sincroniza no repite aunque haya otra petición',
    () async {
      await start(user: _ana);
      clearInteractions(engine);
      final cycle = Completer<SyncRunResult>();
      when(() => engine.run()).thenAnswer((_) => cycle.future);

      final first = coordinator().sync();
      unawaited(coordinator().sync());
      cycle.complete(SyncRunResult.offline);

      expect(await first, SyncRunResult.offline);
      verify(() => engine.run()).called(1);
    },
  );

  test('enqueue guarda y dispara sync', () async {
    await start(user: _ana);
    clearInteractions(engine);
    const op = OutboxOperation.deleteTransaction(id: 't-1');

    await coordinator().enqueue(op);
    await pumpEventQueue();

    verifyInOrder([() => store.enqueue(op), () => engine.run()]);
  });

  test('watchCounters alimenta pending/rejected/lastSyncedAt', () async {
    await start(user: _ana);
    final at = DateTime.utc(2026, 9, 23, 10);

    counters.add((pending: 3, rejected: 1, lastSyncedAt: at));
    await pumpEventQueue();

    expect(
      status(),
      SyncStatus(pending: 3, rejected: 1, lastSyncedAt: at),
    );
  });

  test('newLocalId genera UUID v4 distintos', () async {
    await start();
    final a = coordinator().newLocalId();
    final b = coordinator().newLocalId();

    expect(a, isNot(b));
    expect(
      a,
      matches(
        RegExp(
          '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
          r'[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('syncEngineProvider arma el motor con los puertos', () {
    final c = ProviderContainer(
      overrides: [
        syncStoreProvider.overrideWithValue(store),
        syncRemoteProvider.overrideWithValue(_MockRemote()),
      ],
    );
    addTearDown(c.dispose);

    expect(c.read(syncEngineProvider), isA<SyncEngine>());
  });
}
