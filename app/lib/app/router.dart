import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/presentation/login_page.dart';
import 'package:finanzia/features/auth/presentation/splash_page.dart';
import 'package:finanzia/features/dashboard/presentation/dashboard_placeholder_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/';
  // Reservadas: /onboarding/* (F3.6, F4.4).
}

/// Session gate (spec 008 §2): decide a dónde ir según el estado de la
/// sesión. Función pura para poder probarla sin widgets.
String? redirectFor(AsyncValue<AuthState> auth, String location) {
  final target = switch (auth) {
    AsyncData(value: Authenticated()) =>
      location == Routes.splash || location == Routes.login
          ? Routes.home
          : null,
    AsyncData(value: Unauthenticated()) || AsyncError() => Routes.login,
    _ => Routes.splash,
  };
  return target == location ? null : target;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ValueNotifier<AsyncValue<AuthState>>(
    ref.read(authControllerProvider),
  );
  ref
    ..listen(authControllerProvider, (_, next) => authState.value = next)
    ..onDispose(authState.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authState,
    redirect: (context, state) =>
        redirectFor(authState.value, state.matchedLocation),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const DashboardPlaceholderPage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
