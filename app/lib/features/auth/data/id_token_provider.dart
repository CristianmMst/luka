import 'package:finanzia/core/google/google_sign_in_setup.dart';
import 'package:finanzia/features/auth/domain/auth_failure.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Obtiene el `id_token` de Google que el backend canjea por una sesión.
/// Falla con `AuthFailure`.
abstract interface class IdTokenProvider {
  Future<String> obtainIdToken();

  Future<void> signOut();
}

/// Google Sign-In real (google_sign_in 7, Credential Manager en Android).
///
/// Usa la instancia compartida de [GoogleSignInSetup]: la conexión de Gmail
/// la reutiliza y `initialize` solo puede llamarse una vez.
class GoogleIdTokenProvider implements IdTokenProvider {
  GoogleIdTokenProvider(this._setup);

  final GoogleSignInSetup _setup;

  @override
  Future<String> obtainIdToken() async {
    if (_setup.serverClientId == null) {
      debugPrint('[auth] GOOGLE_SERVER_CLIENT_ID vacío en este build');
      throw const AuthMisconfigured(
        'Falta --dart-define=GOOGLE_SERVER_CLIENT_ID',
      );
    }
    try {
      final client = await _setup.ensureInitialized();
      if (!client.supportsAuthenticate()) {
        throw const AuthMisconfigured(
          'Esta plataforma no soporta authenticate()',
        );
      }
      final account = await client.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthUnexpected('Google sin id_token');
      return idToken;
    } on GoogleSignInException catch (e) {
      // Solo el código: `description`/`details` pueden traer el email de la
      // cuenta u otros datos de Google (spec 009 §5).
      debugPrint('[auth] GoogleSignInException ${e.code.name}');
      throw switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted => const AuthCancelled(),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          AuthMisconfigured(e.code.name),
        GoogleSignInExceptionCode.uiUnavailable ||
        GoogleSignInExceptionCode.userMismatch ||
        GoogleSignInExceptionCode.unknownError => AuthUnexpected(e),
      };
    }
  }

  @override
  Future<void> signOut() async {
    final client = await _setup.ensureInitialized();
    await client.signOut();
  }
}
