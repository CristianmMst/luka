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

  /// No description provided for @transactionsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar comercio, categoría o nota'**
  String get transactionsSearchHint;

  /// No description provided for @transactionsFilters.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get transactionsFilters;

  /// No description provided for @transactionsFiltersSemantics.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Filtros} =1{Filtros, 1 activo} other{Filtros, {count} activos}}'**
  String transactionsFiltersSemantics(int count);

  /// No description provided for @transactionsPeriodRange.
  ///
  /// In es, this message translates to:
  /// **'{from} – {to}'**
  String transactionsPeriodRange(String from, String to);

  /// No description provided for @transactionsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus movimientos.'**
  String get transactionsLoadError;

  /// No description provided for @transactionsRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get transactionsRetry;

  /// No description provided for @filterPeriod.
  ///
  /// In es, this message translates to:
  /// **'Periodo'**
  String get filterPeriod;

  /// No description provided for @filterPeriodThisMonth.
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get filterPeriodThisMonth;

  /// No description provided for @filterPeriodLastMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes pasado'**
  String get filterPeriodLastMonth;

  /// No description provided for @filterPeriodThisYear.
  ///
  /// In es, this message translates to:
  /// **'Este año'**
  String get filterPeriodThisYear;

  /// No description provided for @filterPeriodCustom.
  ///
  /// In es, this message translates to:
  /// **'Elegir fechas'**
  String get filterPeriodCustom;

  /// No description provided for @filterKind.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get filterKind;

  /// No description provided for @filterKindExpense.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get filterKindExpense;

  /// No description provided for @filterKindIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get filterKindIncome;

  /// No description provided for @filterKindTransfer.
  ///
  /// In es, this message translates to:
  /// **'Transferencias'**
  String get filterKindTransfer;

  /// No description provided for @filterOnlyExpenses.
  ///
  /// In es, this message translates to:
  /// **'Solo gastos'**
  String get filterOnlyExpenses;

  /// No description provided for @filterOnlyIncome.
  ///
  /// In es, this message translates to:
  /// **'Solo ingresos'**
  String get filterOnlyIncome;

  /// No description provided for @filterOnlyTransfers.
  ///
  /// In es, this message translates to:
  /// **'Solo transferencias'**
  String get filterOnlyTransfers;

  /// No description provided for @filterBank.
  ///
  /// In es, this message translates to:
  /// **'Banco'**
  String get filterBank;

  /// No description provided for @filterSource.
  ///
  /// In es, this message translates to:
  /// **'Fuente'**
  String get filterSource;

  /// No description provided for @filterCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get filterCategory;

  /// No description provided for @filterCategoryAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get filterCategoryAll;

  /// No description provided for @filterClear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get filterClear;

  /// No description provided for @filterApply.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Ver 1 movimiento} other{Ver {count} movimientos}}'**
  String filterApply(int count);

  /// No description provided for @filterApplyUncounted.
  ///
  /// In es, this message translates to:
  /// **'Ver movimientos'**
  String get filterApplyUncounted;

  /// No description provided for @bankBancolombia.
  ///
  /// In es, this message translates to:
  /// **'Bancolombia'**
  String get bankBancolombia;

  /// No description provided for @bankNequi.
  ///
  /// In es, this message translates to:
  /// **'Nequi'**
  String get bankNequi;

  /// No description provided for @bankDavivienda.
  ///
  /// In es, this message translates to:
  /// **'Davivienda'**
  String get bankDavivienda;

  /// No description provided for @bankDaviplata.
  ///
  /// In es, this message translates to:
  /// **'Daviplata'**
  String get bankDaviplata;

  /// No description provided for @bankBbva.
  ///
  /// In es, this message translates to:
  /// **'BBVA'**
  String get bankBbva;

  /// No description provided for @bankBancoBogota.
  ///
  /// In es, this message translates to:
  /// **'Banco de Bogotá'**
  String get bankBancoBogota;

  /// No description provided for @bankOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get bankOther;

  /// No description provided for @channelNotification.
  ///
  /// In es, this message translates to:
  /// **'Notificación'**
  String get channelNotification;

  /// No description provided for @channelSms.
  ///
  /// In es, this message translates to:
  /// **'SMS'**
  String get channelSms;

  /// No description provided for @channelEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get channelEmail;

  /// No description provided for @channelManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get channelManual;

  /// No description provided for @channelNfc.
  ///
  /// In es, this message translates to:
  /// **'NFC'**
  String get channelNfc;

  /// No description provided for @channelsSemantics.
  ///
  /// In es, this message translates to:
  /// **'Fuentes: {channels}'**
  String channelsSemantics(String channels);

  /// No description provided for @dayToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get dayYesterday;

  /// No description provided for @dayHeaderSemantics.
  ///
  /// In es, this message translates to:
  /// **'{day}, {date}'**
  String dayHeaderSemantics(String day, String date);

  /// No description provided for @dayExpensesSemantics.
  ///
  /// In es, this message translates to:
  /// **'gastos del día: {amount} pesos'**
  String dayExpensesSemantics(String amount);

  /// No description provided for @amountExpenseSemantics.
  ///
  /// In es, this message translates to:
  /// **'gasto de {amount} pesos'**
  String amountExpenseSemantics(String amount);

  /// No description provided for @amountIncomeSemantics.
  ///
  /// In es, this message translates to:
  /// **'ingreso de {amount} pesos'**
  String amountIncomeSemantics(String amount);

  /// No description provided for @amountTransferSemantics.
  ///
  /// In es, this message translates to:
  /// **'transferencia de {amount} pesos'**
  String amountTransferSemantics(String amount);

  /// No description provided for @txNoMerchant.
  ///
  /// In es, this message translates to:
  /// **'Sin comercio'**
  String get txNoMerchant;

  /// No description provided for @txNoCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get txNoCategory;

  /// No description provided for @txChangeCategorySemantics.
  ///
  /// In es, this message translates to:
  /// **'Cambiar categoría: {category}'**
  String txChangeCategorySemantics(String category);

  /// No description provided for @txSyncPending.
  ///
  /// In es, this message translates to:
  /// **'Por enviar'**
  String get txSyncPending;

  /// No description provided for @txSyncRejected.
  ///
  /// In es, this message translates to:
  /// **'No enviado'**
  String get txSyncRejected;

  /// No description provided for @categorySheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get categorySheetTitle;

  /// No description provided for @categorySheetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{merchant} · {amount}'**
  String categorySheetSubtitle(String merchant, String amount);

  /// No description provided for @categorySheetAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get categorySheetAll;

  /// No description provided for @categorySheetNew.
  ///
  /// In es, this message translates to:
  /// **'+ Nueva categoría'**
  String get categorySheetNew;

  /// No description provided for @merchantRuleTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Aplicar siempre a {merchant}?'**
  String merchantRuleTitle(String merchant);

  /// No description provided for @merchantRuleBodyBefore.
  ///
  /// In es, this message translates to:
  /// **'Los próximos movimientos de este comercio quedarán en '**
  String get merchantRuleBodyBefore;

  /// No description provided for @merchantRuleBodyAfter.
  ///
  /// In es, this message translates to:
  /// **'. Puedes cambiarlo cuando quieras.'**
  String get merchantRuleBodyAfter;

  /// No description provided for @merchantRuleAlways.
  ///
  /// In es, this message translates to:
  /// **'Siempre para {merchant}'**
  String merchantRuleAlways(String merchant);

  /// No description provided for @merchantRuleOnce.
  ///
  /// In es, this message translates to:
  /// **'Solo este movimiento'**
  String get merchantRuleOnce;

  /// No description provided for @offlineBanner.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión · ves tus datos guardados'**
  String get offlineBanner;

  /// No description provided for @rejectedTitle.
  ///
  /// In es, this message translates to:
  /// **'No se guardó un cambio'**
  String get rejectedTitle;

  /// No description provided for @rejectedBody.
  ///
  /// In es, this message translates to:
  /// **'{merchant} no quedó así en tu cuenta. Puedes intentarlo otra vez o dejarlo como estaba.'**
  String rejectedBody(String merchant);

  /// No description provided for @rejectedDiscard.
  ///
  /// In es, this message translates to:
  /// **'Dejar como estaba'**
  String get rejectedDiscard;

  /// No description provided for @rejectedRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get rejectedRetry;

  /// No description provided for @emptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay movimientos'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In es, this message translates to:
  /// **'Cuando llegue una notificación o un correo de tu banco, lo verás aquí. También puedes anotar un gasto a mano.'**
  String get emptyBody;

  /// No description provided for @emptyCta.
  ///
  /// In es, this message translates to:
  /// **'Registrar un gasto'**
  String get emptyCta;

  /// No description provided for @noResultsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ningún movimiento coincide'**
  String get noResultsTitle;

  /// No description provided for @noResultsTitleText.
  ///
  /// In es, this message translates to:
  /// **'Nada coincide con “{text}”'**
  String noResultsTitleText(String text);

  /// No description provided for @noResultsBody.
  ///
  /// In es, this message translates to:
  /// **'Con los filtros: {summary}.'**
  String noResultsBody(String summary);

  /// No description provided for @noResultsClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get noResultsClear;

  /// No description provided for @firstSyncLoading.
  ///
  /// In es, this message translates to:
  /// **'Trayendo tus movimientos…'**
  String get firstSyncLoading;
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
