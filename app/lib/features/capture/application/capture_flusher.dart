import 'dart:async';

import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/capture/domain/capture_ports.dart';
import 'package:finanzia/features/capture/domain/capture_rules.dart';
import 'package:finanzia/features/capture/domain/captured_notification.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/domain/sync_rules.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puertos de captura para la capa de aplicación; las implementaciones se
/// cablean en `lib/app/composition.dart`.
final notificationSourceProvider = Provider<NotificationSource>(
  (ref) => throw UnimplementedError(
    'notificationSourceProvider se sobrescribe en la composición',
  ),
);
final captureRemoteProvider = Provider<CaptureRemote>(
  (ref) => throw UnimplementedError(
    'captureRemoteProvider se sobrescribe en la composición',
  ),
);

final captureClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Tras un lote aceptado, el worker del backend todavía tiene que parsearlo:
/// el pull se pide unos segundos después para traer la transacción.
const _syncDelay = Duration(seconds: 5);

final captureSyncTriggerProvider = Provider<void Function()>((ref) {
  return () => Timer(_syncDelay, () {
    if (ref.mounted) {
      unawaited(ref.read(syncCoordinatorProvider.notifier).sync());
    }
  });
});

typedef _SendResult = ({int accepted, bool stop});

/// Vacía la cola del listener de notificaciones hacia
/// `POST /v1/ingest/notifications` (spec 006 §3.2) mientras la app está
/// viva: al entrar, al volver a primer plano, cada 15 min y al recuperar la
/// red. Lo capturado con la app cerrada espera en la cola nativa.
class CaptureFlusher extends Notifier<void> {
  String? _userId;
  Future<void>? _inflight;
  var _again = false;
  DateTime? _configFetchedAt;

  /// Como en el sync: solo una salida voluntaria de una sesión de este
  /// proceso borra la cola.
  var _signedIn = false;
  Future<void> _authQueue = Future.value();

  NotificationSource get _source => ref.read(notificationSourceProvider);

  @override
  void build() {
    if (!ref.read(notificationSourceProvider).isSupported) return;
    final subs = <StreamSubscription<Object?>>[
      ref.read(connectivityProvider).listen((online) {
        if (online) unawaited(flush());
      }),
      ref.read(foregroundTicksProvider).listen((_) => unawaited(flush())),
    ];
    ref
      ..onDispose(() {
        for (final s in subs) {
          unawaited(s.cancel());
        }
      })
      ..listen(
        authControllerProvider,
        (_, next) => Future.microtask(
          () => _authQueue = _authQueue
              .then((_) => _onAuth(next))
              // Solo el tipo (P1).
              .catchError(
                (Object e) => debugPrint('[capture] sesión: ${e.runtimeType}'),
              ),
        ),
        fireImmediately: true,
      );
  }

  Future<void> _onAuth(AsyncValue<AuthState> auth) async {
    if (!ref.mounted) return;
    switch (auth) {
      case AsyncData(value: Authenticated(:final user)):
        _userId = null;
        await _settleInflight();
        if (!ref.mounted) return;
        _signedIn = true;
        await _source.claimFor(user.id);
        if (!ref.mounted) return;
        _userId = user.id;
        _configFetchedAt = null;
        await flush();
      case AsyncData(value: Unauthenticated(:final sessionExpired)):
        _userId = null;
        await _settleInflight();
        if (!ref.mounted) return;
        // Salida voluntaria: nada capturado se queda en el teléfono y el
        // listener deja de capturar (P6).
        if (_signedIn && !sessionExpired) await _source.clear();
        _signedIn = false;
        _configFetchedAt = null;
      default:
        break;
    }
  }

  Future<void> _settleInflight() async {
    final inflight = _inflight;
    if (inflight != null) await inflight.catchError((Object _) {});
  }

  /// Un envío a la vez; si llega otra petición durante uno, corre otra
  /// vuelta al terminar.
  Future<void> flush() {
    if (_userId == null) return Future.value();
    final inflight = _inflight;
    if (inflight != null) {
      _again = true;
      return inflight;
    }
    return _inflight = _loop().whenComplete(() => _inflight = null);
  }

  Future<void> _loop() async {
    try {
      do {
        _again = false;
        await _run();
      } while (_again && ref.mounted);
    } on Object catch (e) {
      // Un fallo inesperado (canal nativo) se reintenta en el próximo
      // disparo. Solo el tipo (P1).
      debugPrint('[capture] envío: ${e.runtimeType}');
    }
  }

  Future<void> _run() async {
    await _refreshConfig();
    var accepted = 0;
    while (_userId != null && ref.mounted) {
      final batch = await _source.pending(ingestBatchLimit);
      if (batch.isEmpty) break;
      final sent = await _send(batch);
      accepted += sent.accepted;
      if (sent.stop) break;
    }
    if (accepted > 0 && ref.mounted) ref.read(captureSyncTriggerProvider)();
  }

  /// Sin config nueva el listener sigue con la última que guardó.
  Future<void> _refreshConfig() async {
    final now = ref.read(captureClockProvider)();
    final fetchedAt = _configFetchedAt;
    if (fetchedAt != null && now.difference(fetchedAt) < captureConfigMaxAge) {
      return;
    }
    try {
      final config = await ref.read(captureRemoteProvider).config();
      if (_userId == null || !ref.mounted) return;
      await _source.setConfig(config);
      _configFetchedAt = now;
    } on RemoteFailure {
      // Se reintenta en el próximo disparo.
    }
  }

  Future<_SendResult> _send(List<CapturedNotification> batch) async {
    try {
      final result = await ref.read(captureRemoteProvider).ingest(batch);
      await _source.remove([for (final n in batch) n.id]);
      return (accepted: result.accepted, stop: false);
    } on RemoteFailure catch (failure) {
      switch (classifyIngestFailure(failure)) {
        case IngestOutcome.retryLater || IngestOutcome.sessionEnded:
          return (accepted: 0, stop: true);
        case IngestOutcome.invalid when batch.length == 1:
          // Reenviarla no sirve: se descarta. Solo el código (P1).
          debugPrint('[capture] descartada: ${failure.code}');
          await _source.remove([batch.single.id]);
          return (accepted: 0, stop: false);
        case IngestOutcome.invalid:
          // Una sola notificación mala no debe tumbar el lote entero.
          var accepted = 0;
          for (final item in batch) {
            final sent = await _send([item]);
            accepted += sent.accepted;
            if (sent.stop) return (accepted: accepted, stop: true);
          }
          return (accepted: accepted, stop: false);
      }
    }
  }
}

final captureFlusherProvider = NotifierProvider<CaptureFlusher, void>(
  CaptureFlusher.new,
);
