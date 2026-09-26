import 'dart:async';

import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/domain/auth_repository.dart';
import 'package:finanzia/features/auth/domain/entities/user.dart';
import 'package:finanzia/features/capture/application/capture_flusher.dart';
import 'package:finanzia/features/capture/domain/capture_ports.dart';
import 'package:finanzia/features/capture/domain/captured_notification.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/domain/sync_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AuthRepository {}

class _MockRemote extends Mock implements CaptureRemote {}

/// Cola nativa en memoria.
class _FakeSource implements NotificationSource {
  _FakeSource({this.isSupported = true});

  @override
  final bool isSupported;

  final queue = <CapturedNotification>[];
  final configs = <CaptureConfig>[];
  final claims = <String>[];
  int clears = 0;

  @override
  Future<bool> isPermissionGranted() async => true;

  @override
  Future<void> openPermissionSettings() async {}

  @override
  Future<void> claimFor(String userId) async => claims.add(userId);

  @override
  Future<void> setConfig(CaptureConfig config) async => configs.add(config);

  @override
  Future<List<CapturedNotification>> pending(int limit) async =>
      queue.take(limit).toList();

  @override
  Future<void> remove(List<int> ids) async =>
      queue.removeWhere((n) => ids.contains(n.id));

  @override
  Future<void> clear() async {
    clears++;
    queue.clear();
  }
}

const _config = CaptureConfig(
  version: 1,
  bankingApps: ['com.bancolombia.app'],
  messagesApps: ['com.google.android.apps.messaging'],
  smsSenderPatterns: ['(?i)bancolombia'],
);

const _ana = User(
  id: 'u-1',
  email: 'ana@example.com',
  status: UserStatus.active,
  displayName: 'Ana',
);

CapturedNotification _n(int id) => CapturedNotification(
  id: id,
  package: 'com.bancolombia.app',
  channel: CaptureChannel.notification,
  postedAt: DateTime.utc(2026, 9, 25, 12).add(Duration(minutes: id)),
  utcOffset: const Duration(hours: -5),
  title: 'Bancolombia',
  text: 'Compraste \$$id.000',
);

IngestResult _ok(int accepted) =>
    (accepted: accepted, duplicates: 0, discarded: 0);

void main() {
  late _MockRepository repository;
  late _MockRemote remote;
  late _FakeSource source;
  late StreamController<void> expired;
  late StreamController<bool> connectivity;
  late StreamController<void> ticks;
  late DateTime now;
  late int syncRequests;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(<CapturedNotification>[]));

  ProviderContainer build({_FakeSource? customSource}) {
    source = customSource ?? source;
    final c = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        notificationSourceProvider.overrideWithValue(source),
        captureRemoteProvider.overrideWithValue(remote),
        connectivityProvider.overrideWithValue(connectivity.stream),
        foregroundTicksProvider.overrideWithValue(ticks.stream),
        captureClockProvider.overrideWithValue(() => now),
        captureSyncTriggerProvider.overrideWithValue(() => syncRequests++),
      ],
    );
    addTearDown(c.dispose);
    c.listen(captureFlusherProvider, (_, _) {});
    return c;
  }

  Future<void> signIn() async {
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).signedIn(_ana);
    await pumpEventQueue();
  }

  setUp(() {
    repository = _MockRepository();
    remote = _MockRemote();
    source = _FakeSource();
    expired = StreamController<void>.broadcast();
    connectivity = StreamController<bool>.broadcast();
    ticks = StreamController<void>.broadcast();
    now = DateTime.utc(2026, 9, 25, 12);
    syncRequests = 0;

    when(() => repository.sessionExpired).thenAnswer((_) => expired.stream);
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    when(() => repository.signOut()).thenAnswer((_) async {});
    when(() => remote.config()).thenAnswer((_) async => _config);
    when(() => remote.ingest(any())).thenAnswer(
      (inv) async => _ok(
        (inv.positionalArguments.single as List<CapturedNotification>).length,
      ),
    );
    container = build();
  });

  test('al entrar reclama la cola, baja la config y vacía por lotes', () async {
    source.queue.addAll([for (var i = 1; i <= 53; i++) _n(i)]);

    await signIn();

    expect(source.claims, ['u-1']);
    expect(source.configs, [_config]);
    final batches = verify(() => remote.ingest(captureAny())).captured;
    expect([for (final b in batches) (b as List).length], [50, 3]);
    expect(source.queue, isEmpty);
    expect(syncRequests, 1);
  });

  test('sin nada aceptado no pide sync', () async {
    source.queue.add(_n(1));
    when(
      () => remote.ingest(any()),
    ).thenAnswer((_) async => (accepted: 0, duplicates: 1, discarded: 0));

    await signIn();

    expect(source.queue, isEmpty);
    expect(syncRequests, 0);
  });

  test('sin sesión no envía nada', () async {
    source.queue.add(_n(1));
    await container.read(authControllerProvider.future);
    await container.read(captureFlusherProvider.notifier).flush();

    verifyNever(() => remote.ingest(any()));
    expect(source.queue, hasLength(1));
  });

  test('sin red deja el lote en la cola y para', () async {
    source.queue.addAll([_n(1), _n(2)]);
    when(
      () => remote.ingest(any()),
    ).thenThrow(const RemoteFailure.network());

    await signIn();

    verify(() => remote.ingest(any())).called(1);
    expect(source.queue, hasLength(2));
  });

  test('un 401 para sin tocar la cola', () async {
    source.queue.add(_n(1));
    when(
      () => remote.ingest(any()),
    ).thenThrow(const RemoteFailure(statusCode: 401, code: 'unauthorized'));

    await signIn();

    expect(source.queue, hasLength(1));
  });

  test(
    'un lote inválido se reintenta ítem por ítem y descarta el malo',
    () async {
      source.queue.addAll([_n(1), _n(2), _n(3)]);
      when(() => remote.ingest(any())).thenAnswer((inv) async {
        final items =
            inv.positionalArguments.single as List<CapturedNotification>;
        if (items.any((n) => n.id == 2)) {
          throw const RemoteFailure(statusCode: 400, code: 'validationError');
        }
        return _ok(items.length);
      });

      await signIn();

      expect(source.queue, isEmpty);
      // Lote completo + 3 individuales.
      verify(() => remote.ingest(any())).called(4);
      expect(syncRequests, 1);
    },
  );

  test('si se cae la red a mitad del reintento individual, para', () async {
    source.queue.addAll([_n(1), _n(2)]);
    var calls = 0;
    when(() => remote.ingest(any())).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        throw const RemoteFailure(statusCode: 400, code: 'validationError');
      }
      throw const RemoteFailure.network();
    });

    await signIn();

    expect(calls, 2);
    expect(source.queue, hasLength(2));
  });

  test(
    'si la config falla, igual envía con la que tenga el listener',
    () async {
      source.queue.add(_n(1));
      when(() => remote.config()).thenThrow(const RemoteFailure.network());

      await signIn();

      expect(source.configs, isEmpty);
      expect(source.queue, isEmpty);
    },
  );

  test('la config se vuelve a pedir solo pasada una hora', () async {
    await signIn();
    verify(() => remote.config()).called(1);

    now = now.add(const Duration(minutes: 59));
    ticks.add(null);
    await pumpEventQueue();
    verifyNever(() => remote.config());

    now = now.add(const Duration(minutes: 1));
    ticks.add(null);
    await pumpEventQueue();
    verify(() => remote.config()).called(1);
  });

  test('volver a primer plano o recuperar la red vacía la cola', () async {
    await signIn();

    source.queue.add(_n(1));
    ticks.add(null);
    await pumpEventQueue();
    expect(source.queue, isEmpty);

    source.queue.add(_n(2));
    connectivity.add(true);
    await pumpEventQueue();
    expect(source.queue, isEmpty);

    source.queue.add(_n(3));
    connectivity.add(false);
    await pumpEventQueue();
    expect(source.queue, hasLength(1));
  });

  test('un flush durante otro corre una vuelta más al terminar', () async {
    await signIn();
    final gate = Completer<IngestResult>();
    when(() => remote.ingest(any())).thenAnswer((_) => gate.future);
    source.queue.add(_n(1));

    final flusher = container.read(captureFlusherProvider.notifier);
    final first = flusher.flush();
    await pumpEventQueue();
    source.queue.add(_n(2));
    final second = flusher.flush();
    when(() => remote.ingest(any())).thenAnswer((_) async => _ok(1));
    gate.complete(_ok(1));
    await Future.wait([first, second]);

    expect(source.queue, isEmpty);
  });

  test('cerrar sesión borra la cola y la config (P6)', () async {
    await signIn();
    source.queue.add(_n(1));
    when(
      () => remote.ingest(any()),
    ).thenThrow(const RemoteFailure.network());

    await container.read(authControllerProvider.notifier).signOut();
    await pumpEventQueue();

    expect(source.clears, 1);
    expect(source.queue, isEmpty);
  });

  test('si la sesión expira, la cola se conserva', () async {
    await signIn();
    source.queue.add(_n(1));
    when(
      () => remote.ingest(any()),
    ).thenThrow(const RemoteFailure.network());

    expired.add(null);
    await pumpEventQueue();

    expect(source.clears, 0);
    expect(source.queue, hasLength(1));
  });

  test('sin listener (iOS) no hace nada', () async {
    container = build(customSource: _FakeSource(isSupported: false));

    await signIn();

    expect(source.claims, isEmpty);
    verifyNever(() => remote.config());
    verifyNever(() => remote.ingest(any()));
  });
}
