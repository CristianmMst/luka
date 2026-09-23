import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuración de compilación, leída de `--dart-define`. Sin flags usa los
/// valores de desarrollo.
final class AppConfig {
  const AppConfig({required this.apiBaseUrl, this.googleServerClientId});

  factory AppConfig.fromEnvironment() {
    const clientId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: devGoogleServerClientId,
    );
    return AppConfig(
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        // Con `adb reverse tcp:8000 tcp:8000` el localhost del teléfono o
        // del emulador llega al backend de la máquina de desarrollo.
        defaultValue: 'http://localhost:8000',
      ),
      googleServerClientId: clientId.isEmpty ? null : clientId,
    );
  }

  /// Client ID web del proyecto de desarrollo `finanzia-509500`. No es un
  /// secreto: es la audiencia pública del `id_token`. Los builds de otros
  /// entornos lo sobrescriben con `--dart-define`.
  static const devGoogleServerClientId =
      '30065910946-hatnfnvkk8782gf8qgbii9qdlqf61jn4.apps.googleusercontent.com';

  final String apiBaseUrl;

  /// Client ID web de Google Cloud; es la audiencia del `id_token` que
  /// verifica el backend.
  final String? googleServerClientId;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
