/// Rutas de la app (go_router). Viven en `core` para que las features
/// naveguen sin importar `lib/app/router.dart`, que a su vez las importa.
abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/';
  static const transactions = '/movimientos';
  static const register = '/registrar';
  static const review = '/revision';
  static const settings = '/ajustes';

  /// "Mis categorías" (F4.8a), a pantalla completa sobre Ajustes.
  static const settingsCategories = '/ajustes/categorias';

  /// "Mis cuentas" (F4.4), a pantalla completa sobre Ajustes.
  static const settingsAccounts = '/ajustes/cuentas';

  /// Paso "Conecta tu Gmail" tras el login (F3.6). El resto de
  /// `/onboarding/*` queda reservado para F4.4.
  static const onboardingGmail = '/onboarding/gmail';
}
