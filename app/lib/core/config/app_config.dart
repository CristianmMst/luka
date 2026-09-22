import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cómo obtiene la app el `id_token` de Google.
///
/// `fake` genera tokens `fake:<sub>:<email>` que el backend acepta cuando
/// corre con `FINANZIA_GOOGLE_VERIFIER=fake` (solo desarrollo y tests).
enum AuthMode { google, fake }

/// Configuración de compilación, leída de `--dart-define`.
final class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.authMode,
    required this.fakeUserEmail,
    this.googleServerClientId,
  });

  factory AppConfig.fromEnvironment() {
    const clientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    return AppConfig(
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        // 10.0.2.2 es el host de la máquina visto desde el emulador Android.
        defaultValue: 'http://10.0.2.2:8000',
      ),
      authMode: const String.fromEnvironment('AUTH_MODE') == 'fake'
          ? AuthMode.fake
          : AuthMode.google,
      googleServerClientId: clientId.isEmpty ? null : clientId,
      fakeUserEmail: const String.fromEnvironment(
        'FAKE_USER_EMAIL',
        defaultValue: 'dev@finanzia.local',
      ),
    );
  }

  final String apiBaseUrl;
  final AuthMode authMode;

  /// Client ID web de Google Cloud; es la audiencia del `id_token` que
  /// verifica el backend.
  final String? googleServerClientId;

  final String fakeUserEmail;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
