import 'package:finanzia/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Única inicialización de `GoogleSignIn.instance` en la app.
///
/// google_sign_in 7 exige llamar `initialize` una sola vez antes de
/// cualquier otra operación. El login (`id_token`) y la conexión de Gmail
/// (`serverAuthCode`) comparten esta instancia: en Android, `authorizeServer`
/// pide acceso offline con el `serverClientId` que se pasó aquí.
class GoogleSignInSetup {
  GoogleSignInSetup({required this.serverClientId, GoogleSignIn? client})
    : client = client ?? GoogleSignIn.instance;

  /// Client ID web (audiencia del `id_token` y del `serverAuthCode`).
  /// `null` si el build no lo trae.
  final String? serverClientId;
  final GoogleSignIn client;
  Future<void>? _initialized;

  /// Inicializa la instancia la primera vez; las siguientes llamadas
  /// reutilizan el mismo `Future`.
  Future<GoogleSignIn> ensureInitialized() async {
    await (_initialized ??= client.initialize(serverClientId: serverClientId));
    return client;
  }
}

final googleSignInSetupProvider = Provider<GoogleSignInSetup>(
  (ref) => GoogleSignInSetup(
    serverClientId: ref.watch(appConfigProvider).googleServerClientId,
  ),
);
