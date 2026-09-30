import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:luka/features/push/data/firebase_options.dart';
import 'package:luka/features/push/domain/push_ports.dart';

/// Inicializa Firebase si hay opciones para la plataforma; `false` si no
/// (la app sigue sin push). Se llama en `main()` antes de `runApp`.
Future<bool> initFirebase() async {
  final options = firebaseOptionsFor(defaultTargetPlatform);
  if (options == null) return false;
  try {
    await Firebase.initializeApp(options: options);
    return true;
  } on Object catch (e) {
    // Solo el tipo (P1).
    debugPrint('[push] Firebase no inició: ${e.runtimeType}');
    return false;
  }
}

/// [PushService] sobre `firebase_messaging` (spec 008 §4.3).
class FirebasePushService implements PushService {
  FirebasePushService({required bool available}) : _available = available;

  final bool _available;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  bool get isAvailable => _available;

  @override
  String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  @override
  Future<PushPermission> permission() async {
    if (!_available) return PushPermission.denied;
    final settings = await _messaging.getNotificationSettings();
    return _map(settings.authorizationStatus);
  }

  @override
  Future<PushPermission> requestPermission() async {
    if (!_available) return PushPermission.denied;
    final settings = await _messaging.requestPermission();
    return _map(settings.authorizationStatus);
  }

  @override
  Future<String?> token() async => _available ? _messaging.getToken() : null;

  @override
  Stream<String> get onTokenRefresh =>
      _available ? _messaging.onTokenRefresh : const Stream.empty();

  @override
  Future<PushOpen?> initialOpen() async {
    if (!_available) return null;
    final message = await _messaging.getInitialMessage();
    return message == null ? null : PushOpen.fromData(message.data);
  }

  @override
  Stream<PushOpen> get onOpened => _available
      ? FirebaseMessaging.onMessageOpenedApp
            .map((m) => PushOpen.fromData(m.data))
            .where((open) => open != null)
            .cast<PushOpen>()
      : const Stream.empty();

  @override
  Stream<PushOpen> get onForeground => _available
      ? FirebaseMessaging.onMessage
            .map((m) => PushOpen.fromData(m.data))
            .where((open) => open != null)
            .cast<PushOpen>()
      : const Stream.empty();

  @override
  Future<void> deleteToken() async {
    if (_available) await _messaging.deleteToken();
  }

  static PushPermission _map(AuthorizationStatus status) => switch (status) {
    AuthorizationStatus.authorized ||
    AuthorizationStatus.provisional => PushPermission.granted,
    AuthorizationStatus.denied ||
    AuthorizationStatus.deniedPermanently => PushPermission.denied,
    AuthorizationStatus.notDetermined => PushPermission.notDetermined,
  };
}
