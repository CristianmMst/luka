import 'dart:async';

import 'package:finanzia/core/network/api_exception.dart';
import 'package:finanzia/core/network/session_bridge.dart';
import 'package:finanzia/features/auth/data/auth_api.dart';
import 'package:finanzia/features/auth/data/dtos/session_dto.dart';
import 'package:finanzia/features/auth/data/token_store.dart';

/// Dueño único de los tokens: los guarda, los renueva y avisa cuando la
/// sesión termina. Implementa el puerto que usa el interceptor de red.
class SessionManager implements SessionBridge {
  SessionManager({
    required TokenStore store,
    required AuthApi api,
    String? deviceInfo,
    DateTime Function()? now,
  }) : _store = store,
       _api = api,
       _deviceInfo = deviceInfo,
       _now = now ?? DateTime.now;

  final TokenStore _store;
  final AuthApi _api;
  final String? _deviceInfo;
  final DateTime Function() _now;

  final _expired = StreamController<void>.broadcast();
  Future<RefreshOutcome>? _inflightRefresh;
  StoredSession? _cache;
  bool _cacheLoaded = false;

  Stream<void> get expired => _expired.stream;

  Future<StoredSession?> current() async {
    if (!_cacheLoaded) {
      _cache = await _store.read();
      _cacheLoaded = true;
    }
    return _cache;
  }

  Future<StoredSession> save(SessionDto dto) async {
    final session = StoredSession.fromDto(dto, _now());
    await _store.write(session);
    _cache = session;
    _cacheLoaded = true;
    return session;
  }

  Future<void> clear() async {
    _cache = null;
    _cacheLoaded = true;
    await _store.clear();
  }

  /// `true` si el access token vence en menos de [margin].
  bool isAccessExpiring(
    StoredSession session, {
    Duration margin = const Duration(seconds: 60),
  }) => !session.accessExpiresAt.isAfter(_now().toUtc().add(margin));

  @override
  Future<String?> accessToken() async => (await current())?.accessToken;

  @override
  Future<RefreshOutcome> refresh() {
    return _inflightRefresh ??= _refresh().whenComplete(
      () => _inflightRefresh = null,
    );
  }

  Future<RefreshOutcome> _refresh() async {
    final session = await current();
    if (session == null) return RefreshOutcome.rejected;
    try {
      await save(
        await _api.refresh(
          refreshToken: session.refreshToken,
          deviceInfo: _deviceInfo,
        ),
      );
      return RefreshOutcome.refreshed;
    } on ApiException catch (e) {
      return switch (e.code) {
        ApiErrorCode.unauthorized ||
        ApiErrorCode.tokenExpired ||
        ApiErrorCode.forbidden ||
        ApiErrorCode.validationError => RefreshOutcome.rejected,
        _ => RefreshOutcome.unavailable,
      };
    }
  }

  @override
  Future<void> expire() async {
    // Sin sesión guardada no hay nada que terminar (p. ej. tras un logout).
    if (await current() == null) return;
    await clear();
    _expired.add(null);
  }

  Future<void> dispose() => _expired.close();
}
