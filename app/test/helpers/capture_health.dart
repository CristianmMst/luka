import 'package:flutter_riverpod/misc.dart';
import 'package:luka/features/capture/application/capture_health.dart';

/// [CaptureHealthController] con un valor fijo, sin escuchar Gmail, el
/// acceso a notificaciones ni el primer plano.
class FixedCaptureHealth extends CaptureHealthController {
  FixedCaptureHealth(this.value);

  final CaptureHealth value;

  @override
  CaptureHealth build() => value;
}

/// La captura sana: el Inicio no muestra la franja de captura detenida.
Override captureHealthOk() => captureHealthProvider.overrideWith(
  () => FixedCaptureHealth(CaptureHealth.ok),
);
