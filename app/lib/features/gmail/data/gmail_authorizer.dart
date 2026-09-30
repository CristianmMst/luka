import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:luka/core/google/google_sign_in_setup.dart';
import 'package:luka/features/gmail/domain/gmail_failure.dart';

/// Pide al usuario permiso de lectura de Gmail y devuelve el
/// `serverAuthCode` que el backend canjea por el refresh token. Falla con
/// `GmailFailure`; cancelar lanza [GmailConsentCancelled].
///
/// Usa google_sign_in 7 sobre la instancia compartida de
/// [GoogleSignInSetup].
///
/// En Android, `authorizeServer` arma el `AuthorizationRequest` con
/// `requestOfflineAccess(serverClientId)` y `Prompt.CONSENT`
/// (google_sign_in_android 7.2), así que Google muestra el consentimiento y
/// emite un refresh token nuevo en cada canje. Por eso `initialize` debe
/// haber recibido el `serverClientId`.
class GmailAuthorizer {
  GmailAuthorizer(this._setup);

  final GoogleSignInSetup _setup;

  static const scopes = ['https://www.googleapis.com/auth/gmail.readonly'];

  Future<String> obtainServerAuthCode() async {
    if (_setup.serverClientId == null) {
      throw const GmailMisconfigured(GmailErrorCode.missingClientId);
    }
    try {
      final client = await _setup.ensureInitialized();
      final authorization = await client.authorizationClient.authorizeServer(
        scopes,
      );
      // `null`: la plataforma no entregó código. Sin él no hay conexión.
      if (authorization == null) {
        throw const GmailUnexpected(null, GmailErrorCode.noServerAuthCode);
      }
      return authorization.serverAuthCode;
    } on GoogleSignInException catch (e) {
      // Solo el código: la descripción puede traer la cuenta.
      debugPrint('[gmail] GoogleSignInException ${e.code.name}');
      throw switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted => const GmailConsentCancelled(),
        GoogleSignInExceptionCode.clientConfigurationError =>
          const GmailMisconfigured(GmailErrorCode.clientConfiguration),
        GoogleSignInExceptionCode.providerConfigurationError =>
          const GmailMisconfigured(GmailErrorCode.providerConfiguration),
        GoogleSignInExceptionCode.uiUnavailable => GmailUnexpected(
          e.code,
          GmailErrorCode.uiUnavailable,
        ),
        GoogleSignInExceptionCode.userMismatch => GmailUnexpected(
          e.code,
          GmailErrorCode.userMismatch,
        ),
        GoogleSignInExceptionCode.unknownError => GmailUnexpected(
          e.code,
          GmailErrorCode.googleUnknown,
        ),
      };
    }
  }
}
