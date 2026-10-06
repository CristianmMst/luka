import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/features/accounts/presentation/my_accounts_page.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/auth/presentation/login_page.dart';
import 'package:luka/features/auth/presentation/splash_page.dart';
import 'package:luka/features/categories/presentation/my_categories_page.dart';
import 'package:luka/features/dashboard/presentation/dashboard_page.dart';
import 'package:luka/features/gmail/presentation/gmail_onboarding_page.dart';
import 'package:luka/features/nfc/presentation/nfc_format.dart';
import 'package:luka/features/nfc/presentation/nfc_tags_page.dart';
import 'package:luka/features/nfc/presentation/quick_add_page.dart';
import 'package:luka/features/onboarding/application/onboarding_gate.dart';
import 'package:luka/features/onboarding/presentation/accounts_onboarding_page.dart';
import 'package:luka/features/onboarding/presentation/apple_pay_onboarding_page.dart';
import 'package:luka/features/onboarding/presentation/notifications_onboarding_page.dart';
import 'package:luka/features/onboarding/presentation/onboarding_navigation.dart';
import 'package:luka/features/recurring/presentation/recurring_page.dart';
import 'package:luka/features/review/presentation/review_detail_page.dart';
import 'package:luka/features/review/presentation/review_page.dart';
import 'package:luka/features/shell/presentation/ajustes_page.dart';
import 'package:luka/features/shell/presentation/home_shell.dart';
import 'package:luka/features/transactions/presentation/registrar_page.dart';
import 'package:luka/features/transactions/presentation/transaction_detail_page.dart';
import 'package:luka/features/transactions/presentation/transaction_edit_page.dart';
import 'package:luka/features/transactions/presentation/transactions_page.dart';

export 'package:luka/core/routing/routes.dart';

/// Session gate (spec 008 §2): decide a dónde ir según el estado de la
/// sesión y, al salir del splash o del login, según [onboarding]. Función
/// pura para poder probarla sin widgets.
///
/// El onboarding solo se decide al salir del splash o del login: en el
/// resto de rutas (incluido `/onboarding/*` por deep link) no se redirige,
/// así que avanzar entre pasos o desconectar Gmail en Ajustes no saca al
/// usuario de donde está y no hay rebote entre Inicio y el onboarding.
///
/// [pendingDeepLink] es un registro rápido que llegó (por un tag NFC) antes
/// de que hubiera sesión lista: al salir del splash o del login sin
/// onboarding pendiente se abre ese en vez de Inicio.
String? redirectFor(
  AsyncValue<AuthState> auth,
  String location, {
  required OnboardingGate onboarding,
  String? pendingDeepLink,
}) {
  final target = switch (auth) {
    AsyncData(value: Authenticated()) =>
      location == Routes.splash || location == Routes.login
          ? switch (onboarding) {
              // Espera en el splash: ir a Inicio y luego saltar al
              // onboarding sería un rebote visible.
              OnboardingPending() => Routes.splash,
              OnboardingShow(:final step) => onboardingRoute(step),
              OnboardingSkip() => pendingDeepLink ?? Routes.home,
            }
          : null,
    AsyncData(value: Unauthenticated()) || AsyncError() => Routes.login,
    _ => Routes.splash,
  };
  return target == location ? null : target;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Solo avisa al router que vuelva a evaluar el gate; el redirect lee la
  // sesión y el gate del onboarding en ese momento, así nunca ve un gate viejo
  // justo después de un cambio de sesión.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authControllerProvider, (_, _) => refresh.value++)
    ..listen(onboardingGateProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  // Los detalles (movimiento y mensaje en revisión) se apilan sobre el
  // navegador raíz: a pantalla completa, sin la barra inferior del shell
  // (diseño DetalleA).
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  String? pendingDeepLink;
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final onboarding = ref.read(onboardingGateProvider);
      // Enlace externo `luka://quick-add?tag=…` (tag NFC, spec 006 §5).
      final deepLink = quickAddLocation(state.uri);
      if (deepLink != null) {
        final ready =
            auth is AsyncData<AuthState> &&
            auth.value is Authenticated &&
            onboarding is OnboardingSkip;
        if (ready) return deepLink;
        // Sin sesión lista: se guarda y se abre al salir del splash/login.
        pendingDeepLink = deepLink;
        return redirectFor(auth, Routes.splash, onboarding: onboarding) ??
            Routes.splash;
      }
      final target = redirectFor(
        auth,
        state.matchedLocation,
        onboarding: onboarding,
        pendingDeepLink: pendingDeepLink,
      );
      if (target != null && target == pendingDeepLink) pendingDeepLink = null;
      return target;
    },
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
        path: Routes.recurring,
        builder: (context, state) => RecurringPage(
          highlightId: state.uri.queryParameters['ocurrencia'],
        ),
      ),
      GoRoute(
        path: Routes.onboardingGmail,
        builder: (context, state) => const GmailOnboardingPage(),
      ),
      GoRoute(
        path: Routes.onboardingNotifications,
        builder: (context, state) => const NotificationsOnboardingPage(),
      ),
      GoRoute(
        path: Routes.onboardingApplePay,
        builder: (context, state) => const ApplePayOnboardingPage(),
      ),
      GoRoute(
        path: Routes.onboardingAccounts,
        builder: (context, state) => const AccountsOnboardingPage(),
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
                routes: [
                  GoRoute(
                    path: Routes.quickAdd.substring(1),
                    parentNavigatorKey: rootNavigatorKey,
                    // Hoja sobre la app (diseño B): no tapa lo de abajo.
                    pageBuilder: (context, state) => QuickAddPage.page(
                      tagId: state.uri.queryParameters['tag'] ?? '',
                    ),
                  ),
                ],
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
                    routes: [
                      GoRoute(
                        path: 'editar',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) => TransactionEditPage(
                          id: state.pathParameters['id']!,
                        ),
                      ),
                    ],
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
                      // "Usar $X" de la lista: el monto ya puesto.
                      initialAmountCents: int.tryParse(
                        state.uri.queryParameters['monto'] ?? '',
                      ),
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
                  GoRoute(
                    path: 'cuentas',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const MyAccountsPage(),
                  ),
                  GoRoute(
                    path: 'tags-nfc',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const NfcTagsPage(),
                  ),
                  GoRoute(
                    path: 'apple-pay',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        const ApplePayOnboardingPage(inOnboarding: false),
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
