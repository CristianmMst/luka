import 'package:finanzia/features/auth/domain/auth_failure.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Obtiene el `id_token` de Google que el backend canjea por una sesión.
/// Falla con `AuthFailure`.
abstract interface class IdTokenProvider {
  Future<String> obtainIdToken();

  Future<void> signOut();
}

/// Google Sign-In real (google_sign_in 7, Credential Manager en Android).
class GoogleIdTokenProvider implements IdTokenProvider {
  GoogleIdTokenProvider({required String? serverClientId, GoogleSignIn? client})
    : _serverClientId = serverClientId,
      _client = client ?? GoogleSignIn.instance;

  final String? _serverClientId;
  final GoogleSignIn _client;
  Future<void>? _initialized;

  Future<void> _ensureInitialized() =>
      _initialized ??= _client.initialize(serverClientId: _serverClientId);

  @override
  Future<String> obtainIdToken() async {
    if (_serverClientId == null) {
      throw const AuthMisconfigured(
        'Falta --dart-define=GOOGLE_SERVER_CLIENT_ID',
      );
    }
    try {
      await _ensureInitialized();
      if (!_client.supportsAuthenticate()) {
        throw const AuthMisconfigured(
          'Esta plataforma no soporta authenticate()',
        );
      }
      final account = await _client.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthUnexpected('Google sin id_token');
      return idToken;
    } on GoogleSignInException catch (e) {
      throw switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted => const AuthCancelled(),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          AuthMisconfigured(e.description ?? e.code.name),
        GoogleSignInExceptionCode.uiUnavailable ||
        GoogleSignInExceptionCode.userMismatch ||
        GoogleSignInExceptionCode.unknownError => AuthUnexpected(e),
      };
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await _client.signOut();
  }
}

/// Doble de desarrollo: genera `fake:<sub>:<email>`, que el backend acepta
/// con `FINANZIA_GOOGLE_VERIFIER=fake`. Nunca se usa en producción (el
/// backend rechaza ese verificador con `env=prod`).
class FakeIdTokenProvider implements IdTokenProvider {
  const FakeIdTokenProvider({required this.email});

  final String email;

  @override
  Future<String> obtainIdToken() async {
    final sub = 'dev-${email.split('@').first}';
    return 'fake:$sub:$email';
  }

  @override
  Future<void> signOut() async {}
}
