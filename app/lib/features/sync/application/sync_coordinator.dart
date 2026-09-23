import 'dart:async';

import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/sync/application/sync_engine.dart';
import 'package:finanzia/features/sync/domain/outbox_operation.dart';
import 'package:finanzia/features/sync/domain/sync_ports.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'sync_coordinator.freezed.dart';

/// Puertos de sync para la capa de aplicación; las implementaciones se
/// cablean en `lib/app/composition.dart`.
final syncStoreProvider = Provider<SyncStore>(
  (ref) => throw UnimplementedError(
    'syncStoreProvider se sobrescribe en la composición',
  ),
);
final syncRemoteProvider = Provider<SyncRemote>(
  (ref) => throw UnimplementedError(
    'syncRemoteProvider se sobrescribe en la composición',
  ),
);

/// `true` cuando hay red (connectivity_plus en `data`).
final connectivityProvider = Provider<Stream<bool>>(
  (ref) => throw UnimplementedError(
    'connectivityProvider se sobrescribe en la composición',
  ),
);

/// Emite al volver a primer plano y cada 15 min mientras la app está visible
/// (spec 008 §5).
final foregroundTicksProvider = Provider<Stream<void>>(
  (ref) => throw UnimplementedError(
    'foregroundTicksProvider se sobrescribe en la composición',
  ),
);

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    store: ref.watch(syncStoreProvider),
    remote: ref.watch(syncRemoteProvider),
  ),
);

/// Ítems abiertos de la cola de revisión, para el badge de "Revisión" en la
/// barra de navegación (spec 008 §7).
final openReviewCountProvider = StreamProvider<int>(
  (ref) => ref.watch(syncStoreProvider).watchOpenReviewCount(),
);

@freezed
abstract class SyncStatus with _$SyncStatus {
  const factory SyncStatus({
    @Default(false) bool running,
    @Default(false) bool offline,
    @Default(0) int pending,
    @Default(0) int rejected,
    DateTime? lastSyncedAt,
  }) = _SyncStatus;
}

/// Dispara la sincronización según la sesión, la red y el primer plano, y
/// expone su estado a la UI.
class SyncCoordinator extends Notifier<SyncStatus> {
  String? _userId;
  Future<SyncRunResult>? _inflight;
  var _again = false;

  /// Hubo sesión en este proceso: solo entonces una salida voluntaria borra
  /// la base (al arrancar sin sesión se conserva, p. ej. tras expirar).
  var _signedIn = false;

  /// Serializa los cambios de sesión para que un cambio no pise al anterior.
  Future<void> _authQueue = Future.value();

  SyncStore get _store => ref.read(syncStoreProvider);

  @override
  SyncStatus build() {
    final subs = <StreamSubscription<Object?>>[
      _store.watchCounters().listen(
        (c) => state = state.copyWith(
          pending: c.pending,
          rejected: c.rejected,
          lastSyncedAt: c.lastSyncedAt,
        ),
      ),
      ref.read(connectivityProvider).listen((online) {
        state = state.copyWith(offline: !online);
        if (online) unawaited(sync());
      }),
      ref.read(foregroundTicksProvider).listen((_) => unawaited(sync())),
    ];
    ref
      ..onDispose(() {
        for (final s in subs) {
          unawaited(s.cancel());
        }
      })
      ..listen(
        authControllerProvider,
        // Microtask: no tocar `state` antes de que build() devuelva.
        (_, next) => Future.microtask(
          () => _authQueue = _authQueue
              .then((_) => _onAuth(next))
              // Un fallo no debe envenenar la cola: los siguientes cambios
              // de sesión se atienden igual. Solo el tipo (P1).
              .catchError(
                (Object e) => debugPrint('[sync] sesión: ${e.runtimeType}'),
              ),
        ),
        fireImmediately: true,
      );
    return const SyncStatus();
  }

  Future<void> _onAuth(AsyncValue<AuthState> auth) async {
    if (!ref.mounted) return;
    switch (auth) {
      case AsyncData(value: Authenticated(:final user)):
        _userId = null;
        // Un ciclo del usuario anterior no debe escribir tras el claim.
        await _settleInflight();
        if (!ref.mounted) return;
        // Antes del claim: si falla, una salida voluntaria igual borra (P6).
        _signedIn = true;
        await _store.claimFor(user.id);
        if (!ref.mounted) return;
        _userId = user.id;
        await sync();
      case AsyncData(value: Unauthenticated(:final sessionExpired)):
        _userId = null;
        await _settleInflight();
        if (!ref.mounted) return;
        // Salida voluntaria: no dejar datos en el teléfono (P6). Si la
        // sesión expiró, o la app arrancó sin sesión, se conservan; claimFor
        // borra si entra otro usuario.
        if (_signedIn && !sessionExpired) await _store.clearAll();
        _signedIn = false;
      default:
        break;
    }
  }

  /// Espera el ciclo en curso, si hay, sin propagar su error.
  Future<void> _settleInflight() async {
    final inflight = _inflight;
    if (inflight != null) {
      await inflight.catchError((Object _) => SyncRunResult.skipped);
    }
  }

  /// Un ciclo a la vez; si llega otra petición durante uno, corre otro al
  /// terminar.
  Future<SyncRunResult> sync() {
    if (_userId == null) return Future.value(SyncRunResult.skipped);
    final inflight = _inflight;
    if (inflight != null) {
      _again = true;
      return inflight;
    }
    return _inflight = _loop().whenComplete(() => _inflight = null);
  }

  Future<SyncRunResult> _loop() async {
    state = state.copyWith(running: true);
    var result = SyncRunResult.offline;
    try {
      do {
        _again = false;
        result = await ref.read(syncEngineProvider).run();
      } while (_again && result == SyncRunResult.synced && ref.mounted);
    } on Object catch (e) {
      // Error inesperado del motor: se reintenta en el próximo disparo como
      // si no hubiera red. Solo el tipo (P1).
      debugPrint('[sync] ciclo: ${e.runtimeType}');
      result = SyncRunResult.offline;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          running: false,
          offline: result == SyncRunResult.offline,
        );
      }
    }
    return result;
  }

  /// Guarda una operación hecha por el usuario y la envía en cuanto se pueda.
  Future<void> enqueue(OutboxOperation op) async {
    await _store.enqueue(op);
    if (ref.mounted) unawaited(sync());
  }

  /// Reenvía las operaciones rechazadas que tocan [id].
  Future<void> retryRejected(String id) async {
    await _store.retryRejected(id);
    if (ref.mounted) unawaited(sync());
  }

  /// Descarta las operaciones rechazadas que tocan [id] y deja sus filas
  /// como las tiene el servidor. Sin red quedan como están.
  Future<void> discardRejected(String id) async {
    final discarded = await _store.discardRejected(id);
    // Ni las creaciones descartadas (ya quitadas en local) ni las que
    // siguen rechazadas existen en el servidor.
    final localOnly = {
      for (final op in discarded)
        if (op.createsRecord) op.targetId,
      ...await _store.rejectedCreates(),
    };
    final remote = ref.read(syncRemoteProvider);
    for (final op in discarded) {
      await restoreAfterReject(
        store: _store,
        remote: remote,
        op: op,
        rejectedCreates: localOnly,
      );
    }
  }

  String newLocalId() => const Uuid().v4();
}

final syncCoordinatorProvider = NotifierProvider<SyncCoordinator, SyncStatus>(
  SyncCoordinator.new,
);
