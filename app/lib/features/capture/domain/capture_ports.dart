import 'package:luka/features/capture/domain/captured_notification.dart';

/// Captura nativa de pagos y su cola local. En Android es el listener de
/// notificaciones; en iOS, que no deja leer notificaciones de otras apps,
/// es la cola de pagos con Apple Pay que llena una App Intent (spec 006
/// §3.3).
abstract interface class NotificationSource {
  /// Hay cola nativa que enviar. `false` donde no hay captura (web, tests).
  bool get isSupported;

  /// Lee notificaciones del sistema con permiso (solo Android): la UI de
  /// notificaciones solo existe con esto.
  bool get readsNotifications;

  /// El usuario dio acceso a las notificaciones en los ajustes del sistema.
  Future<bool> isPermissionGranted();

  /// Abre donde el usuario activa la captura: el ajuste de acceso a
  /// notificaciones (Android) o la app Atajos (iOS).
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
