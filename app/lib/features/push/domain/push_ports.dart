// `freezed_annotation` reexporta `package:meta` (`@immutable`).
import 'package:freezed_annotation/freezed_annotation.dart';

/// Estado del permiso de notificaciones del sistema (Android 13+ e iOS).
enum PushPermission { granted, denied, notDetermined }

/// Tipo de `data` de los recordatorios de gastos fijos (spec 011 §5).
const recurringDueType = 'recurring_due';

/// Un aviso push que el usuario tocó o que llegó con la app abierta.
@immutable
final class PushOpen {
  const PushOpen({required this.occurrenceId});

  /// El `data` del aviso, o `null` si no es un recordatorio de gasto fijo.
  static PushOpen? fromData(Map<String, Object?> data) {
    final id = data['occurrence_id'];
    if (data['type'] != recurringDueType || id is! String || id.isEmpty) {
      return null;
    }
    return PushOpen(occurrenceId: id);
  }

  final String occurrenceId;

  @override
  bool operator ==(Object other) =>
      other is PushOpen && other.occurrenceId == occurrenceId;

  @override
  int get hashCode => occurrenceId.hashCode;
}

/// Firebase Cloud Messaging en el teléfono (spec 008 §4.3).
abstract interface class PushService {
  /// `false` si Firebase no está configurado: la app funciona sin push.
  bool get isAvailable;

  /// `android` o `ios`, como lo espera `PUT /devices/push-token`.
  String get platform;

  Future<PushPermission> permission();
  Future<PushPermission> requestPermission();

  /// Token de FCM de este teléfono; `null` si no hay.
  Future<String?> token();
  Stream<String> get onTokenRefresh;

  /// El aviso que abrió la app en frío, si lo hubo.
  Future<PushOpen?> initialOpen();

  /// Avisos tocados con la app en segundo plano.
  Stream<PushOpen> get onOpened;

  /// Avisos que llegan con la app abierta (el sistema no los muestra).
  Stream<PushOpen> get onForeground;
  Future<void> deleteToken();
}

/// `PUT/DELETE /v1/devices/push-token` (spec 005 §10). Los fallos se
/// ignoran: se reintenta en el próximo arranque.
abstract interface class PushTokenRemote {
  Future<void> register(String token, String platform);
  Future<void> unregister(String token);
}

/// Si ya se mostró la explicación del permiso (spec 008 §3.8).
abstract interface class PushPrefs {
  Future<bool> permissionAsked();
  Future<void> markPermissionAsked();
}

/// Push sin Firebase configurado (spec 011 §6): no hay token ni avisos.
final class DisabledPushService implements PushService {
  const DisabledPushService();

  @override
  bool get isAvailable => false;

  @override
  String get platform => 'android';

  @override
  Future<PushPermission> permission() async => PushPermission.denied;

  @override
  Future<PushPermission> requestPermission() async => PushPermission.denied;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<PushOpen?> initialOpen() async => null;

  @override
  Stream<PushOpen> get onOpened => const Stream.empty();

  @override
  Stream<PushOpen> get onForeground => const Stream.empty();

  @override
  Future<void> deleteToken() async {}
}
