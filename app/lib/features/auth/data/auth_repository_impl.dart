import 'package:luka/core/network/api_exception.dart';
import 'package:luka/core/network/session_bridge.dart';
import 'package:luka/features/auth/data/auth_api.dart';
import 'package:luka/features/auth/data/id_token_provider.dart';
import 'package:luka/features/auth/data/session_manager.dart';
import 'package:luka/features/auth/domain/auth_failure.dart';
import 'package:luka/features/auth/domain/auth_repository.dart';
import 'package:luka/features/auth/domain/entities/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required IdTokenProvider idTokens,
    required AuthApi api,
    required SessionManager session,
    String? deviceInfo,
  }) : _idTokens = idTokens,
       _api = api,
       _session = session,
       _deviceInfo = deviceInfo;

  final IdTokenProvider _idTokens;
  final AuthApi _api;
  final SessionManager _session;
  final String? _deviceInfo;

  @override
  Stream<void> get sessionExpired => _session.expired;

  @override
  Future<User> signInWithGoogle() async {
    final idToken = await _idTokens.obtainIdToken();
    try {
      final dto = await _api.loginWithGoogle(
        idToken: idToken,
        deviceInfo: _deviceInfo,
      );
      await _session.save(dto);
      return dto.user.toDomain();
    } on ApiException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<User?> restoreSession() async {
    final stored = await _session.current();
    if (stored == null) return null;
    if (!_session.isAccessExpiring(stored)) return stored.user.toDomain();

    switch (await _session.refresh()) {
      case RefreshOutcome.refreshed:
        return (await _session.current())?.user.toDomain();
      case RefreshOutcome.rejected:
        await _session.clear();
        return null;
      case RefreshOutcome.unavailable:
        // Sin red: se entra con el perfil en caché; el primer request
        // autenticado volverá a intentar el refresh.
        return stored.user.toDomain();
    }
  }

  @override
  Future<void> signOut() async {
    var stored = await _session.current();
    if (stored != null && _session.isAccessExpiring(stored)) {
      // Con un access vencido el logout daría 401 y el refresh token
      // quedaría vivo en el backend.
      if (await _session.refresh() == RefreshOutcome.refreshed) {
        stored = await _session.current();
      }
    }
    await _session.clear();
    if (stored != null) {
      try {
        await _api.logout(
          accessToken: stored.accessToken,
          refreshToken: stored.refreshToken,
        );
      } on ApiException {
        // Best effort: la sesión local ya se borró.
      }
    }
    try {
      await _idTokens.signOut();
    } on Object {
      // Cerrar sesión en Google no debe impedir salir de la app.
    }
  }

  AuthFailure _toFailure(ApiException e) => switch (e.code) {
    ApiErrorCode.network => const AuthNetworkFailure(),
    ApiErrorCode.rateLimited => AuthRateLimited(e.retryAfter),
    ApiErrorCode.unauthorized ||
    ApiErrorCode.tokenExpired ||
    ApiErrorCode.forbidden ||
    ApiErrorCode.validationError => const AuthRejected(),
    _ => AuthUnexpected(e),
  };
}
