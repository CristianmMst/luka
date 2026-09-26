import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

/// `true` cuando hay alguna red: el estado inicial y luego cada cambio.
///
/// Admite varios oyentes (sync, envío de capturas…) y cada uno recibe su
/// propio estado inicial: el provider guarda una sola instancia del stream.
Stream<bool> connectivityStream(Connectivity connectivity) => _perListener(
  () => _connectivityResults(
    connectivity,
  ).map((r) => !r.contains(ConnectivityResult.none)).distinct(),
);

Stream<List<ConnectivityResult>> _connectivityResults(
  Connectivity connectivity,
) async* {
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
}

/// Emite al volver a primer plano y cada 15 min mientras la app está visible
/// (spec 008 §5). Admite varios oyentes, como [connectivityStream].
Stream<void> foregroundTicks() => _perListener(_foregroundTicks);

Stream<void> _foregroundTicks() {
  AppLifecycleListener? listener;
  Timer? timer;
  late final StreamController<void> controller;
  controller = StreamController<void>(
    onListen: () {
      listener = AppLifecycleListener(onResume: () => controller.add(null));
      timer = Timer.periodic(const Duration(minutes: 15), (_) {
        final visible =
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
        if (visible) controller.add(null);
      });
    },
    onCancel: () {
      listener?.dispose();
      timer?.cancel();
    },
  );
  return controller.stream;
}

/// Un stream que crea una fuente nueva por cada oyente.
Stream<T> _perListener<T>(Stream<T> Function() source) =>
    Stream<T>.multi((controller) {
      final sub = source().listen(
        controller.addSync,
        onError: controller.addErrorSync,
        onDone: controller.closeSync,
      );
      controller
        ..onPause = sub.pause
        ..onResume = sub.resume
        ..onCancel = sub.cancel;
    });
