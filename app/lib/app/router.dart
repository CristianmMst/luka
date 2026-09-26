import 'package:finanzia/core/routing/routes.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/auth/presentation/login_page.dart';
import 'package:finanzia/features/auth/presentation/splash_page.dart';
import 'package:finanzia/features/categories/presentation/my_categories_page.dart';
import 'package:finanzia/features/dashboard/presentation/dashboard_page.dart';
import 'package:finanzia/features/gmail/application/gmail_gate.dart';
import 'package:finanzia/features/gmail/presentation/gmail_onboarding_page.dart';
import 'package:finanzia/features/review/presentation/review_detail_page.dart';
import 'package:finanzia/features/review/presentation/review_page.dart';
import 'package:finanzia/features/shell/presentation/ajustes_page.dart';
import 'package:finanzia/features/shell/presentation/home_shell.dart';
import 'package:finanzia/features/transactions/presentation/registrar_page.dart';
import 'package:finanzia/features/transactions/presentation/transaction_detail_page.dart';
import 'package:finanzia/features/transactions/presentation/transactions_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

export 'package:finanzia/core/routing/routes.dart';

/// Session gate (spec 008 §2): decide a dónde ir según el estado de la
/// sesión y, al salir del splash o del login, según [gmail]. Función pura
/// para poder probarla sin widgets.
///
/// El paso de Gmail solo se decide al salir del splash o del login: en el
/// resto de rutas (incluida `/onboarding/gmail` por deep link) no se
/// redirige, así que desconectar Gmail en Ajustes no saca al usuario de ahí
/// y no hay rebote entre Inicio y el onboarding.
String? redirectFor(
  AsyncValue<AuthState> auth,
  String location, {
  required GmailGate gmail,
}) {
  final target = switch (auth) {
    AsyncData(value: Authenticated()) =>
      location == Routes.splash || location == Routes.login
          ? switch (gmail) {
              // Espera en el splash: ir a Inicio y luego saltar al
              // onboarding sería un rebote visible.
              GmailGate.pending => Routes.splash,
              GmailGate.prompt => Routes.onboardingGmail,
              GmailGate.skip => Routes.home,
            }
          : null,
    AsyncData(value: Unauthenticated()) || AsyncError() => Routes.login,
    _ => Routes.splash,
  };
  return target == location ? null : target;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Solo avisa al router que vuelva a evaluar el gate; el redirect lee la
  // sesión y el gate de Gmail en ese momento, así nunca ve un gate viejo
  // justo después de un cambio de sesión.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authControllerProvider, (_, _) => refresh.value++)
    ..listen(gmailGateProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  // Los detalles (movimiento y mensaje en revisión) se apilan sobre el
  // navegador raíz: a pantalla completa, sin la barra inferior del shell
  // (diseño DetalleA).
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(
      ref.read(authControllerProvider),
      state.matchedLocation,
      gmail: ref.read(gmailGateProvider),
    ),
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
        path: Routes.onboardingGmail,
        builder: (context, state) => const GmailOnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.transactions,
                builder: (context, state) => const TransactionsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => TransactionDetailPage(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.register,
                builder: (context, state) => const RegistrarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.review,
                builder: (context, state) => const ReviewPage(),
                routes: [
                  GoRoute(
                    path: ':rawMessageId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => ReviewDetailPage(
                      rawMessageId: state.pathParameters['rawMessageId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const AjustesPage(),
                routes: [
                  GoRoute(
                    path: 'categorias',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const MyCategoriesPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
