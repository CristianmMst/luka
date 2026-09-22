import 'package:dio/dio.dart';
import 'package:finanzia/core/config/app_config.dart';
import 'package:finanzia/core/network/auth_interceptor.dart';
import 'package:finanzia/core/network/session_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Dio buildDio(String baseUrl) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
    ),
  );
  if (kDebugMode) {
    // Solo línea de petición y estado: headers y cuerpos llevan tokens.
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        logPrint: (line) => debugPrint(line.toString()),
      ),
    );
  }
  return dio;
}

/// Puerto de sesión que usa la red; lo implementa la feature `auth` y se
/// cablea en `lib/app/composition.dart`.
final sessionBridgeProvider = Provider<SessionBridge>(
  (ref) => throw UnimplementedError(
    'sessionBridgeProvider debe sobrescribirse en la composición de la app',
  ),
);

/// Cliente sin credenciales: `/v1/auth/*`.
final publicDioProvider = Provider<Dio>((ref) {
  final dio = buildDio(ref.watch(appConfigProvider).apiBaseUrl);
  ref.onDispose(dio.close);
  return dio;
});

/// Cliente autenticado para el resto de la API.
final apiDioProvider = Provider<Dio>((ref) {
  final dio = buildDio(ref.watch(appConfigProvider).apiBaseUrl);
  dio.interceptors.insert(
    0,
    AuthInterceptor(dio: dio, session: ref.watch(sessionBridgeProvider)),
  );
  ref.onDispose(dio.close);
  return dio;
});
