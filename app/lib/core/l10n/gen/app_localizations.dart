import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'finanzia'**
  String get appName;

  /// No description provided for @splashRestoring.
  ///
  /// In es, this message translates to:
  /// **'Restaurando tu sesión'**
  String get splashRestoring;

  /// No description provided for @loginHeadline.
  ///
  /// In es, this message translates to:
  /// **'Tus gastos se anotan solos.'**
  String get loginHeadline;

  /// No description provided for @loginBody.
  ///
  /// In es, this message translates to:
  /// **'finanzia lee las notificaciones y correos de tu banco y deja cada compra registrada una sola vez.'**
  String get loginBody;

  /// No description provided for @loginContinueWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get loginContinueWithGoogle;

  /// No description provided for @loginConnecting.
  ///
  /// In es, this message translates to:
  /// **'Conectando con Google…'**
  String get loginConnecting;

  /// No description provided for @loginRetryWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Reintentar con Google'**
  String get loginRetryWithGoogle;

  /// No description provided for @loginLegalPrefix.
  ///
  /// In es, this message translates to:
  /// **'Al continuar aceptas los '**
  String get loginLegalPrefix;

  /// No description provided for @loginLegalTerms.
  ///
  /// In es, this message translates to:
  /// **'Términos'**
  String get loginLegalTerms;

  /// No description provided for @loginLegalJoin.
  ///
  /// In es, this message translates to:
  /// **' y la '**
  String get loginLegalJoin;

  /// No description provided for @loginLegalPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Política de tratamiento de datos'**
  String get loginLegalPrivacy;

  /// No description provided for @loginLegalSuffix.
  ///
  /// In es, this message translates to:
  /// **'.'**
  String get loginLegalSuffix;

  /// No description provided for @tickerNotificationSource.
  ///
  /// In es, this message translates to:
  /// **'NOTIFICACIÓN · BANCOLOMBIA'**
  String get tickerNotificationSource;

  /// No description provided for @tickerNotificationText.
  ///
  /// In es, this message translates to:
  /// **'Compra en La Espiga'**
  String get tickerNotificationText;

  /// No description provided for @tickerEmailSource.
  ///
  /// In es, this message translates to:
  /// **'CORREO · BANCOLOMBIA'**
  String get tickerEmailSource;

  /// No description provided for @tickerEmailText.
  ///
  /// In es, this message translates to:
  /// **'Compraste en La Espiga'**
  String get tickerEmailText;

  /// No description provided for @tickerResultTitle.
  ///
  /// In es, this message translates to:
  /// **'1 registro'**
  String get tickerResultTitle;

  /// No description provided for @tickerResultSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mercado · sin duplicados'**
  String get tickerResultSubtitle;

  /// No description provided for @tickerSemantics.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo: una notificación y un correo de la misma compra de {amount} quedan como un solo registro.'**
  String tickerSemantics(String amount);

  /// No description provided for @errorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu internet e inténtalo de nuevo.'**
  String get errorNetwork;

  /// No description provided for @errorRateLimited.
  ///
  /// In es, this message translates to:
  /// **'Hiciste muchos intentos seguidos. Podrás volver a intentarlo en {countdown}.'**
  String errorRateLimited(String countdown);

  /// No description provided for @errorRateLimitedNoWait.
  ///
  /// In es, this message translates to:
  /// **'Hiciste muchos intentos seguidos. Espera un momento y vuelve a intentarlo.'**
  String get errorRateLimitedNoWait;

  /// No description provided for @errorRejected.
  ///
  /// In es, this message translates to:
  /// **'Google no confirmó tu cuenta. Inténtalo de nuevo o usa otra cuenta.'**
  String get errorRejected;

  /// No description provided for @errorMisconfigured.
  ///
  /// In es, this message translates to:
  /// **'El inicio de sesión con Google no está configurado en esta versión de la app.'**
  String get errorMisconfigured;

  /// No description provided for @errorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar sesión. Inténtalo de nuevo en unos minutos.'**
  String get errorUnexpected;

  /// No description provided for @sessionExpiredNotice.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión se cerró para proteger tu cuenta. Inicia sesión de nuevo para seguir.'**
  String get sessionExpiredNotice;

  /// No description provided for @homeGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homePlaceholderBody.
  ///
  /// In es, this message translates to:
  /// **'Ya iniciaste sesión. El resumen de tus gastos llega en la siguiente fase.'**
  String get homePlaceholderBody;

  /// No description provided for @homeSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get homeSignOut;

  /// No description provided for @syncStatusSynced.
  ///
  /// In es, this message translates to:
  /// **'Sincronizado · {pending, plural, =0{al día} =1{1 pendiente} other{{pending} pendientes}}'**
  String syncStatusSynced(int pending);

  /// No description provided for @syncStatusOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión · los cambios se enviarán al volver'**
  String get syncStatusOffline;

  /// No description provided for @syncStatusRunning.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando…'**
  String get syncStatusRunning;

  /// No description provided for @syncStatusNever.
  ///
  /// In es, this message translates to:
  /// **'Aún no sincronizado'**
  String get syncStatusNever;

  /// No description provided for @syncStatusRejected.
  ///
  /// In es, this message translates to:
  /// **'{rejected, plural, =1{1 cambio no se pudo enviar} other{{rejected} cambios no se pudieron enviar}}'**
  String syncStatusRejected(int rejected);

  /// No description provided for @navHomeLabel.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHomeLabel;

  /// No description provided for @navTransactionsLabel.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get navTransactionsLabel;

  /// No description provided for @navRegisterLabel.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get navRegisterLabel;

  /// No description provided for @navReviewLabel.
  ///
  /// In es, this message translates to:
  /// **'Revisión'**
  String get navReviewLabel;

  /// No description provided for @navSettingsLabel.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettingsLabel;

  /// No description provided for @reviewBadgeSemantics.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 por revisar} other{{count} por revisar}}'**
  String reviewBadgeSemantics(int count);

  /// No description provided for @shellComingSoonBody.
  ///
  /// In es, this message translates to:
  /// **'Llega pronto'**
  String get shellComingSoonBody;

  /// No description provided for @transactionDetailPlaceholderBody.
  ///
  /// In es, this message translates to:
  /// **'Detalle del movimiento'**
  String get transactionDetailPlaceholderBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
