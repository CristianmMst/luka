import 'package:finanzia/core/network/api_exception.dart';
import 'package:finanzia/features/gmail/data/gmail_api.dart';
import 'package:finanzia/features/gmail/data/gmail_authorizer.dart';
import 'package:finanzia/features/gmail/domain/gmail_connection.dart';
import 'package:finanzia/features/gmail/domain/gmail_failure.dart';
import 'package:finanzia/features/gmail/domain/gmail_repository.dart';

class GmailRepositoryImpl implements GmailRepository {
  GmailRepositoryImpl({
    required GmailAuthorizer authorizer,
    required GmailApi api,
  }) : _authorizer = authorizer,
       _api = api;

  final GmailAuthorizer _authorizer;
  final GmailApi _api;

  @override
  Future<GmailConnectionInfo> status() async {
    try {
      return (await _api.status()).toDomain();
    } on ApiException catch (e) {
      throw _toFailure(e);
    }
  }

  /// Si el backend responde que faltó el refresh token no se reintenta
  /// solo: sería abrir otra vez el consentimiento sin que el usuario lo
  /// pidiera. La pantalla ofrece "vuelve a intentarlo".
  @override
  Future<GmailConnectionInfo> connect() async {
    final code = await _authorizer.obtainServerAuthCode();
    try {
      return (await _api.connect(code)).toDomain();
    } on ApiException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _api.disconnect();
    } on ApiException catch (e) {
      throw _toFailure(e);
    }
  }

  GmailFailure _toFailure(ApiException e) => switch (e.code) {
    ApiErrorCode.network => const GmailNetworkFailure(),
    ApiErrorCode.rateLimited => GmailRateLimited(e.retryAfter),
    ApiErrorCode.upstreamUnavailable => const GmailUpstreamUnavailable(),
    ApiErrorCode.validationError when e.field == 'server_auth_code' =>
      _codeFailure(e.message ?? ''),
    _ => GmailUnexpected(e),
  };

  /// Los tres rechazos del código llegan como `400 validation_error` con
  /// `field: server_auth_code`; solo el mensaje los distingue
  /// (`ingestion/infrastructure/api/errors.py`).
  static GmailFailure _codeFailure(String message) {
    if (message.contains('refresh token')) {
      return const GmailRefreshTokenMissing();
    }
    if (message.contains('permiso de Gmail')) return const GmailScopeDenied();
    return const GmailCodeRejected();
  }
}
