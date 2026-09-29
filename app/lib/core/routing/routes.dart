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

  /// "Tags NFC" (F4.5b), a pantalla completa sobre Ajustes.
  static const settingsNfcTags = '/ajustes/tags-nfc';

  /// Registro rápido de un tag NFC (F4.5b): `/rapido?tag=<uuid>`, sobre el
  /// Inicio. Llega por el enlace `finanzia://quick-add?tag=<uuid>`.
  static const quickAdd = '/rapido';

  /// Pasos del onboarding tras el login (F3.6, F4.4), fuera del shell.
  static const onboardingGmail = '/onboarding/gmail';
  static const onboardingNotifications = '/onboarding/notificaciones';
  static const onboardingAccounts = '/onboarding/cuentas';
}
