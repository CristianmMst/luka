import 'package:finanzia/features/capture/domain/captured_notification.dart';

/// Listener de notificaciones del sistema y su cola local. En Android es
/// código nativo; en iOS no existe (Apple no deja leer notificaciones de
/// otras apps) y todo es no-op.
abstract interface class NotificationSource {
  /// `false` en plataformas sin listener: la UI no muestra la sección.
  bool get isSupported;

  /// El usuario dio acceso a las notificaciones en los ajustes del sistema.
  Future<bool> isPermissionGranted();

  /// Abre el ajuste del sistema de acceso a notificaciones.
  Future<void> openPermissionSettings();

  /// Deja la cola al usuario [userId]: si lo capturado era de otro, lo
  /// borra junto con la config.
  Future<void> claimFor(String userId);

  /// Guarda la config con la que filtra el listener.
  Future<void> setConfig(CaptureConfig config);

  /// Las primeras [limit] notificaciones pendientes, de la más antigua a la
  /// más nueva.
  Future<List<CapturedNotification>> pending(int limit);

  /// Saca de la cola las notificaciones ya enviadas (o descartadas).
  Future<void> remove(List<int> ids);

  /// Borra la cola y la config: sin config el listener no captura nada.
  Future<void> clear();
}

/// Endpoints de captura del backend. Falla con `RemoteFailure`.
abstract interface class CaptureRemote {
  /// `GET /v1/config/capture`.
  Future<CaptureConfig> config();

  /// `POST /v1/ingest/notifications` con hasta `ingestBatchLimit` ítems.
  Future<IngestResult> ingest(List<CapturedNotification> items);
}
