import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/push/domain/push_ports.dart';

/// Puertos de push; se sobrescriben en `lib/app/composition.dart`.
/// Sin Firebase la app corre con [DisabledPushService]; la composición lo
/// reemplaza por el de Firebase.
final pushServiceProvider = Provider<PushService>(
  (ref) => const DisabledPushService(),
);
final pushTokenRemoteProvider = Provider<PushTokenRemote>(
  (ref) => throw UnimplementedError(
    'pushTokenRemoteProvider se sobrescribe en la composición',
  ),
);
final pushPrefsProvider = Provider<PushPrefs>(
  (ref) => throw UnimplementedError(
    'pushPrefsProvider se sobrescribe en la composición',
  ),
);

/// Estado visible del push: el permiso y el aviso que falta abrir.
@immutable
final class PushState {
  const PushState({
    this.permission = PushPermission.notDetermined,
    this.pendingOpen,
    this.foreground,
  });

  final PushPermission permission;

  /// Aviso tocado que la app todavía no abrió (se abre con sesión).
  final PushOpen? pendingOpen;

  /// Último aviso que llegó con la app abierta (se muestra como snackbar).
  final PushOpen? foreground;

  PushState copyWith({
    PushPermission? permission,
    PushOpen? pendingOpen,
    bool clearPending = false,
    PushOpen? foreground,
    bool clearForeground = false,
  }) => PushState(
    permission: permission ?? this.permission,
    pendingOpen: clearPending ? null : pendingOpen ?? this.pendingOpen,
    foreground: clearForeground ? null : foreground ?? this.foreground,
  );
}

/// Registra el token de FCM con sesión, lo borra al salir y guarda los
/// avisos tocados para abrir `/gastos-fijos` (spec 008 §4.2). Sin Firebase
/// configurado no hace nada.
class PushRegistrar extends Notifier<PushState> {
  String? _registered;
  var _signedIn = false;

  PushService get _service => ref.read(pushServiceProvider);

  @override
  PushState build() {
    final service = ref.read(pushServiceProvider);
    if (!service.isAvailable) return const PushState();
    final subs = <StreamSubscription<Object?>>[
      service.onTokenRefresh.listen((token) => unawaited(_register(token))),
      service.onOpened.listen(
        (open) => state = state.copyWith(pendingOpen: open),
      ),
      service.onForeground.listen(
        (open) => state = state.copyWith(foreground: open),
      ),
    ];
    ref
      ..onDispose(() {
        for (final s in subs) {
          unawaited(s.cancel());
        }
      })
      ..listen(
        authControllerProvider,
        (_, next) => unawaited(_onAuth(next)),
        fireImmediately: true,
      );
    unawaited(_loadInitial());
    return const PushState();
  }

  Future<void> _loadInitial() async {
    try {
      final permission = await _service.permission();
      final open = await _service.initialOpen();
      if (!ref.mounted) return;
      state = state.copyWith(permission: permission, pendingOpen: open);
    } on Object catch (e) {
      debugPrint('[push] inicio: ${e.runtimeType}');
    }
  }

  Future<void> _onAuth(AsyncValue<AuthState> auth) async {
    switch (auth) {
      case AsyncData(value: Authenticated()):
        _signedIn = true;
        await _registerCurrent();
      case AsyncData(value: Unauthenticated()):
        _signedIn = false;
        _registered = null;
      default:
        break;
    }
  }

  Future<void> _registerCurrent() async {
    try {
      if (await _service.permission() != PushPermission.granted) return;
      final token = await _service.token();
      if (token != null) await _register(token);
    } on Object catch (e) {
      debugPrint('[push] token: ${e.runtimeType}');
    }
  }

  Future<void> _register(String token) async {
    if (!_signedIn || !ref.mounted) return;
    try {
      await ref
          .read(pushTokenRemoteProvider)
          .register(token, _service.platform);
      _registered = token;
    } on Object catch (e) {
      // Se reintenta en el próximo arranque. Nunca el token (P1).
      debugPrint('[push] registro: ${e.runtimeType}');
    }
  }

  /// Pide el permiso del sistema y, si se concede, registra el token.
  Future<PushPermission> requestPermission() async {
    if (!_service.isAvailable) return PushPermission.denied;
    await ref.read(pushPrefsProvider).markPermissionAsked();
    final permission = await _service.requestPermission();
    if (!ref.mounted) return permission;
    state = state.copyWith(permission: permission);
    if (permission == PushPermission.granted) await _registerCurrent();
    return permission;
  }

  /// `true` si hay que mostrar la explicación antes de pedir el permiso.
  Future<bool> shouldExplainPermission() async {
    if (!_service.isAvailable) return false;
    if (await _service.permission() == PushPermission.granted) return false;
    return !await ref.read(pushPrefsProvider).permissionAsked();
  }

  /// Vuelve a leer el permiso (al volver de los ajustes del sistema).
  Future<void> refreshPermission() async {
    if (!_service.isAvailable) return;
    final permission = await _service.permission();
    if (ref.mounted) state = state.copyWith(permission: permission);
  }

  /// Borra el token en el servidor y en FCM antes de cerrar la sesión, para
  /// que un teléfono compartido no reciba avisos de la cuenta anterior.
  Future<void> unregister() async {
    if (!_service.isAvailable) return;
    final token = _registered ?? await _service.token();
    if (token != null) {
      await ref.read(pushTokenRemoteProvider).unregister(token);
    }
    await _service.deleteToken();
    _registered = null;
  }

  void consumeOpen() => state = state.copyWith(clearPending: true);

  void consumeForeground() => state = state.copyWith(clearForeground: true);
}

final pushRegistrarProvider = NotifierProvider<PushRegistrar, PushState>(
  PushRegistrar.new,
);
