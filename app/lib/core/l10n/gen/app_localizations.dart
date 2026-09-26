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

  /// No description provided for @homeSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get homeSignOut;

  /// No description provided for @dashboardPreviousMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes anterior'**
  String get dashboardPreviousMonth;

  /// No description provided for @dashboardNextMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes siguiente'**
  String get dashboardNextMonth;

  /// No description provided for @dashboardBalance.
  ///
  /// In es, this message translates to:
  /// **'Balance del mes'**
  String get dashboardBalance;

  /// No description provided for @dashboardBalanceSemantics.
  ///
  /// In es, this message translates to:
  /// **'{sign, select, positive{Balance del mes: más {amount} pesos} negative{Balance del mes: menos {amount} pesos} other{Balance del mes: {amount} pesos}}'**
  String dashboardBalanceSemantics(String sign, String amount);

  /// No description provided for @dashboardExpenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get dashboardExpenses;

  /// No description provided for @dashboardIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get dashboardIncome;

  /// No description provided for @dashboardTileSemantics.
  ///
  /// In es, this message translates to:
  /// **'{label}: {amount} pesos. {delta}'**
  String dashboardTileSemantics(String label, String amount, String delta);

  /// No description provided for @dashboardDeltaUp.
  ///
  /// In es, this message translates to:
  /// **'↑ {percent} % vs {month}'**
  String dashboardDeltaUp(int percent, String month);

  /// No description provided for @dashboardDeltaDown.
  ///
  /// In es, this message translates to:
  /// **'↓ {percent} % vs {month}'**
  String dashboardDeltaDown(int percent, String month);

  /// No description provided for @dashboardDeltaSame.
  ///
  /// In es, this message translates to:
  /// **'= igual que {month}'**
  String dashboardDeltaSame(String month);

  /// No description provided for @dashboardDeltaNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos de {month}'**
  String dashboardDeltaNoData(String month);

  /// No description provided for @dashboardDeltaUpSemantics.
  ///
  /// In es, this message translates to:
  /// **'{percent} % más que {month}'**
  String dashboardDeltaUpSemantics(int percent, String month);

  /// No description provided for @dashboardDeltaDownSemantics.
  ///
  /// In es, this message translates to:
  /// **'{percent} % menos que {month}'**
  String dashboardDeltaDownSemantics(int percent, String month);

  /// No description provided for @dashboardDeltaSameSemantics.
  ///
  /// In es, this message translates to:
  /// **'Igual que {month}'**
  String dashboardDeltaSameSemantics(String month);

  /// No description provided for @dashboardTopTitle.
  ///
  /// In es, this message translates to:
  /// **'En qué se fue'**
  String get dashboardTopTitle;

  /// No description provided for @dashboardTopSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Top 5 del gasto'**
  String get dashboardTopSubtitle;

  /// No description provided for @dashboardCategoryPercent.
  ///
  /// In es, this message translates to:
  /// **'{percent} %'**
  String dashboardCategoryPercent(int percent);

  /// No description provided for @dashboardCategorySemantics.
  ///
  /// In es, this message translates to:
  /// **'{name}, {percent} % del gasto, {amount}'**
  String dashboardCategorySemantics(String name, int percent, String amount);

  /// No description provided for @dashboardOtherCategories.
  ///
  /// In es, this message translates to:
  /// **'Otras categorías'**
  String get dashboardOtherCategories;

  /// No description provided for @dashboardOtherAmount.
  ///
  /// In es, this message translates to:
  /// **'{amount} · {percent} %'**
  String dashboardOtherAmount(String amount, int percent);

  /// No description provided for @dashboardOtherSemantics.
  ///
  /// In es, this message translates to:
  /// **'Otras categorías, {percent} % del gasto, {amount}'**
  String dashboardOtherSemantics(int percent, String amount);

  /// No description provided for @dashboardNoExpenses.
  ///
  /// In es, this message translates to:
  /// **'Sin gastos en {month}.'**
  String dashboardNoExpenses(String month);

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin movimientos en {month}'**
  String dashboardEmptyTitle(String month);

  /// No description provided for @dashboardEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Cuando lleguen pagos o ingresos de ese mes, aquí verás en qué se fue tu plata.'**
  String get dashboardEmptyBody;

  /// No description provided for @dashboardBackToMonth.
  ///
  /// In es, this message translates to:
  /// **'Volver a {month}'**
  String dashboardBackToMonth(String month);

  /// No description provided for @dashboardFirstSyncTitle.
  ///
  /// In es, this message translates to:
  /// **'Trayendo tus movimientos'**
  String get dashboardFirstSyncTitle;

  /// No description provided for @dashboardFirstSyncBody.
  ///
  /// In es, this message translates to:
  /// **'La primera vez tarda un poco. Tu resumen aparece apenas termine.'**
  String get dashboardFirstSyncBody;

  /// No description provided for @dashboardOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión — datos locales'**
  String get dashboardOffline;

  /// No description provided for @dashboardLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer el resumen guardado en el teléfono.'**
  String get dashboardLoadError;

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

  /// No description provided for @accountKindSavings.
  ///
  /// In es, this message translates to:
  /// **'ahorros'**
  String get accountKindSavings;

  /// No description provided for @accountKindChecking.
  ///
  /// In es, this message translates to:
  /// **'corriente'**
  String get accountKindChecking;

  /// No description provided for @accountKindCreditCard.
  ///
  /// In es, this message translates to:
  /// **'tarjeta de crédito'**
  String get accountKindCreditCard;

  /// No description provided for @accountKindWallet.
  ///
  /// In es, this message translates to:
  /// **'billetera'**
  String get accountKindWallet;

  /// Cuenta vinculada sin últimos 4: banco y tipo de cuenta en minúscula.
  ///
  /// In es, this message translates to:
  /// **'{bank} {kind}'**
  String accountLabel(String bank, String kind);

  /// Cuenta vinculada: banco, tipo de cuenta en minúscula y últimos 4.
  ///
  /// In es, this message translates to:
  /// **'{bank} {kind} ···{last4}'**
  String accountLabelWithLast4(String bank, String kind, String last4);

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

  /// No description provided for @detailTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimiento'**
  String get detailTitle;

  /// No description provided for @detailBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get detailBack;

  /// No description provided for @detailNotFound.
  ///
  /// In es, this message translates to:
  /// **'Este movimiento ya no existe.'**
  String get detailNotFound;

  /// No description provided for @detailLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar este movimiento.'**
  String get detailLoadError;

  /// No description provided for @detailTransferBadge.
  ///
  /// In es, this message translates to:
  /// **'TRANSFERENCIA PROPIA'**
  String get detailTransferBadge;

  /// No description provided for @detailTransferNote.
  ///
  /// In es, this message translates to:
  /// **'No cuenta como gasto ni como ingreso'**
  String get detailTransferNote;

  /// No description provided for @detailCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get detailCategory;

  /// No description provided for @detailAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get detailAccount;

  /// No description provided for @detailNoAccount.
  ///
  /// In es, this message translates to:
  /// **'Sin cuenta'**
  String get detailNoAccount;

  /// No description provided for @detailKind.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get detailKind;

  /// No description provided for @detailKindExpense.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get detailKindExpense;

  /// No description provided for @detailKindIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingreso'**
  String get detailKindIncome;

  /// No description provided for @detailKindTransfer.
  ///
  /// In es, this message translates to:
  /// **'Transferencia propia'**
  String get detailKindTransfer;

  /// No description provided for @detailParsedBy.
  ///
  /// In es, this message translates to:
  /// **'Leído con'**
  String get detailParsedBy;

  /// No description provided for @parsedByRule.
  ///
  /// In es, this message translates to:
  /// **'Plantilla {bank}'**
  String parsedByRule(String bank);

  /// No description provided for @parsedByLlm.
  ///
  /// In es, this message translates to:
  /// **'Lectura automática'**
  String get parsedByLlm;

  /// No description provided for @parsedByManual.
  ///
  /// In es, this message translates to:
  /// **'Registro manual'**
  String get parsedByManual;

  /// No description provided for @detailSources.
  ///
  /// In es, this message translates to:
  /// **'Fuentes'**
  String get detailSources;

  /// No description provided for @detailSourcesCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 canal} other{{count} canales}}'**
  String detailSourcesCount(int count);

  /// No description provided for @sourceNotification.
  ///
  /// In es, this message translates to:
  /// **'Notificación del banco'**
  String get sourceNotification;

  /// No description provided for @sourceSms.
  ///
  /// In es, this message translates to:
  /// **'SMS del banco'**
  String get sourceSms;

  /// No description provided for @sourceEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo del banco'**
  String get sourceEmail;

  /// No description provided for @sourceManual.
  ///
  /// In es, this message translates to:
  /// **'Registro manual'**
  String get sourceManual;

  /// No description provided for @sourceNfc.
  ///
  /// In es, this message translates to:
  /// **'Etiqueta NFC'**
  String get sourceNfc;

  /// No description provided for @sourceReceived.
  ///
  /// In es, this message translates to:
  /// **'{gender, select, female{Recibida {when}} male{Recibido {when}} other{Registrado {when}}}'**
  String sourceReceived(String gender, String when);

  /// No description provided for @sourcesSeal.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 registro con 1 fuente} other{1 registro con {count} fuentes, sin duplicados}}'**
  String sourcesSeal(int count);

  /// No description provided for @sourcesOffline.
  ///
  /// In es, this message translates to:
  /// **'Las fuentes se consultan con conexión. El resto del movimiento está guardado en tu teléfono.'**
  String get sourcesOffline;

  /// No description provided for @sourcesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Las fuentes aparecen cuando el movimiento llega a tu cuenta en el servidor.'**
  String get sourcesEmpty;

  /// No description provided for @detailMarkTransfer.
  ///
  /// In es, this message translates to:
  /// **'Marcar como transferencia propia'**
  String get detailMarkTransfer;

  /// No description provided for @detailUnmarkTransfer.
  ///
  /// In es, this message translates to:
  /// **'No es una transferencia'**
  String get detailUnmarkTransfer;

  /// No description provided for @detailPairLabel.
  ///
  /// In es, this message translates to:
  /// **'La otra parte'**
  String get detailPairLabel;

  /// No description provided for @detailPairValue.
  ///
  /// In es, this message translates to:
  /// **'{account} · {direction, select, credit{recibida} other{enviada}} {time}'**
  String detailPairValue(String account, String direction, String time);

  /// No description provided for @detailPairSemantics.
  ///
  /// In es, this message translates to:
  /// **'Abrir la otra parte: {value}'**
  String detailPairSemantics(String value);

  /// No description provided for @detailNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get detailNotes;

  /// No description provided for @detailNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Agrega una nota para ti'**
  String get detailNotesHint;

  /// No description provided for @emptyPeriodTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin movimientos este mes'**
  String get emptyPeriodTitle;

  /// No description provided for @emptyPeriodBody.
  ///
  /// In es, this message translates to:
  /// **'Tus movimientos anteriores siguen guardados. Revisa el mes pasado o cambia los filtros.'**
  String get emptyPeriodBody;

  /// No description provided for @emptyPeriodLastMonth.
  ///
  /// In es, this message translates to:
  /// **'Ver mes pasado'**
  String get emptyPeriodLastMonth;

  /// No description provided for @emptyPeriodFilters.
  ///
  /// In es, this message translates to:
  /// **'Cambiar filtros'**
  String get emptyPeriodFilters;

  /// No description provided for @gmailHeroLabel.
  ///
  /// In es, this message translates to:
  /// **'SOLO ALERTAS DE TUS BANCOS'**
  String get gmailHeroLabel;

  /// No description provided for @gmailHeroBanks.
  ///
  /// In es, this message translates to:
  /// **'Bancolombia · Nequi · Davivienda · BBVA'**
  String get gmailHeroBanks;

  /// No description provided for @gmailHeroSemantics.
  ///
  /// In es, this message translates to:
  /// **'finanzia solo lee los correos de alerta de bancos como Bancolombia, Nequi, Davivienda y BBVA.'**
  String get gmailHeroSemantics;

  /// No description provided for @gmailOnboardingTitle.
  ///
  /// In es, this message translates to:
  /// **'Conecta tu Gmail'**
  String get gmailOnboardingTitle;

  /// No description provided for @gmailOnboardingBody.
  ///
  /// In es, this message translates to:
  /// **'Tus compras quedan registradas solas, sin duplicados.'**
  String get gmailOnboardingBody;

  /// No description provided for @gmailReadsLabel.
  ///
  /// In es, this message translates to:
  /// **'Lee'**
  String get gmailReadsLabel;

  /// No description provided for @gmailReads.
  ///
  /// In es, this message translates to:
  /// **'Correos de alertas de tus bancos (Bancolombia, Nequi…).'**
  String get gmailReads;

  /// No description provided for @gmailNeverReadsLabel.
  ///
  /// In es, this message translates to:
  /// **'Nunca lee'**
  String get gmailNeverReadsLabel;

  /// No description provided for @gmailNeverReads.
  ///
  /// In es, this message translates to:
  /// **'Tu correo personal, contactos ni adjuntos.'**
  String get gmailNeverReads;

  /// No description provided for @gmailConnect.
  ///
  /// In es, this message translates to:
  /// **'Conectar Gmail'**
  String get gmailConnect;

  /// No description provided for @gmailConnecting.
  ///
  /// In es, this message translates to:
  /// **'Conectando Gmail…'**
  String get gmailConnecting;

  /// No description provided for @gmailRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get gmailRetry;

  /// No description provided for @gmailNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get gmailNotNow;

  /// No description provided for @gmailRevokeNote.
  ///
  /// In es, this message translates to:
  /// **'Puedes quitar el permiso cuando quieras desde Ajustes o desde tu cuenta de Google.'**
  String get gmailRevokeNote;

  /// No description provided for @gmailErrorRejected.
  ///
  /// In es, this message translates to:
  /// **'Google no aceptó la autorización. Inténtalo de nuevo.'**
  String get gmailErrorRejected;

  /// No description provided for @gmailErrorScopeDenied.
  ///
  /// In es, this message translates to:
  /// **'Para conectar Gmail, marca el permiso de lectura de correos en la pantalla de Google.'**
  String get gmailErrorScopeDenied;

  /// No description provided for @gmailErrorUpstream.
  ///
  /// In es, this message translates to:
  /// **'No pudimos hablar con Google. Inténtalo de nuevo en unos minutos.'**
  String get gmailErrorUpstream;

  /// No description provided for @gmailErrorMisconfigured.
  ///
  /// In es, this message translates to:
  /// **'La conexión con Gmail no está configurada en esta versión de la app.'**
  String get gmailErrorMisconfigured;

  /// No description provided for @gmailErrorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'No pudimos conectar Gmail. Inténtalo de nuevo.'**
  String get gmailErrorUnexpected;

  /// No description provided for @gmailConnectedInactive.
  ///
  /// In es, this message translates to:
  /// **'Conectado, pero no pudimos activar la captura; reintenta desde Ajustes.'**
  String get gmailConnectedInactive;

  /// No description provided for @settingsGmailTitle.
  ///
  /// In es, this message translates to:
  /// **'Gmail'**
  String get settingsGmailTitle;

  /// No description provided for @settingsGmailConnected.
  ///
  /// In es, this message translates to:
  /// **'Conectado · {email}'**
  String settingsGmailConnected(String email);

  /// No description provided for @settingsGmailConnectedNoEmail.
  ///
  /// In es, this message translates to:
  /// **'Conectado'**
  String get settingsGmailConnectedNoEmail;

  /// No description provided for @settingsGmailRevoked.
  ///
  /// In es, this message translates to:
  /// **'Google quitó el permiso. Reconecta para seguir capturando.'**
  String get settingsGmailRevoked;

  /// No description provided for @settingsGmailError.
  ///
  /// In es, this message translates to:
  /// **'La captura de correos se detuvo. Reconecta para reanudarla.'**
  String get settingsGmailError;

  /// No description provided for @settingsGmailDisconnected.
  ///
  /// In es, this message translates to:
  /// **'Sin conectar · tus compras por correo no se registran'**
  String get settingsGmailDisconnected;

  /// No description provided for @settingsGmailLoading.
  ///
  /// In es, this message translates to:
  /// **'Consultando Gmail…'**
  String get settingsGmailLoading;

  /// No description provided for @settingsGmailUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No pudimos consultar el estado de Gmail.'**
  String get settingsGmailUnavailable;

  /// No description provided for @settingsGmailConnect.
  ///
  /// In es, this message translates to:
  /// **'Conectar'**
  String get settingsGmailConnect;

  /// No description provided for @settingsGmailReconnect.
  ///
  /// In es, this message translates to:
  /// **'Reconectar'**
  String get settingsGmailReconnect;

  /// No description provided for @settingsGmailDisconnect.
  ///
  /// In es, this message translates to:
  /// **'Desconectar'**
  String get settingsGmailDisconnect;

  /// No description provided for @settingsGmailRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get settingsGmailRetry;

  /// No description provided for @settingsGmailActionSemantics.
  ///
  /// In es, this message translates to:
  /// **'{action} Gmail'**
  String settingsGmailActionSemantics(String action);

  /// No description provided for @settingsGmailDisconnectTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Desconectar Gmail?'**
  String get settingsGmailDisconnectTitle;

  /// No description provided for @settingsGmailDisconnectBody.
  ///
  /// In es, this message translates to:
  /// **'Dejamos de leer los correos de tus bancos. Los movimientos que ya tienes se quedan.'**
  String get settingsGmailDisconnectBody;

  /// No description provided for @settingsGmailDisconnectConfirm.
  ///
  /// In es, this message translates to:
  /// **'Desconectar'**
  String get settingsGmailDisconnectConfirm;

  /// No description provided for @settingsGmailDisconnectCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get settingsGmailDisconnectCancel;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones del banco'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsActive.
  ///
  /// In es, this message translates to:
  /// **'Activo · registramos tus pagos apenas llegan'**
  String get settingsNotificationsActive;

  /// No description provided for @settingsNotificationsInactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivo · los pagos que te notifica el banco no se registran'**
  String get settingsNotificationsInactive;

  /// No description provided for @settingsNotificationsLoading.
  ///
  /// In es, this message translates to:
  /// **'Consultando el permiso…'**
  String get settingsNotificationsLoading;

  /// No description provided for @settingsNotificationsEnable.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get settingsNotificationsEnable;

  /// No description provided for @settingsNotificationsManage.
  ///
  /// In es, this message translates to:
  /// **'Administrar'**
  String get settingsNotificationsManage;

  /// No description provided for @settingsNotificationsActionSemantics.
  ///
  /// In es, this message translates to:
  /// **'{action} notificaciones del banco'**
  String settingsNotificationsActionSemantics(String action);

  /// No description provided for @notificationDisclosureTitle.
  ///
  /// In es, this message translates to:
  /// **'Registra tus pagos al instante'**
  String get notificationDisclosureTitle;

  /// No description provided for @notificationDisclosureBody.
  ///
  /// In es, this message translates to:
  /// **'Con el acceso a notificaciones, finanzia registra cada compra o transferencia apenas tu banco te avisa, sin que escribas nada.'**
  String get notificationDisclosureBody;

  /// No description provided for @notificationDisclosureReads.
  ///
  /// In es, this message translates to:
  /// **'Leemos solo las notificaciones de las apps de tus bancos y los SMS que envían tus bancos.'**
  String get notificationDisclosureReads;

  /// No description provided for @notificationDisclosureIgnores.
  ///
  /// In es, this message translates to:
  /// **'Ignoramos todo lo demás: chats, correos y SMS de otras personas no se guardan ni salen de tu teléfono.'**
  String get notificationDisclosureIgnores;

  /// No description provided for @notificationDisclosureRevoke.
  ///
  /// In es, this message translates to:
  /// **'Puedes quitar el permiso cuando quieras en los ajustes del teléfono.'**
  String get notificationDisclosureRevoke;

  /// No description provided for @notificationDisclosureContinue.
  ///
  /// In es, this message translates to:
  /// **'Ir a los ajustes'**
  String get notificationDisclosureContinue;

  /// No description provided for @notificationDisclosureCancel.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get notificationDisclosureCancel;

  /// No description provided for @reviewSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Todo al día} =1{1 mensaje por revisar} other{{count} mensajes por revisar}}'**
  String reviewSubtitle(int count);

  /// No description provided for @reviewReasonNoTemplate.
  ///
  /// In es, this message translates to:
  /// **'No reconocimos el formato'**
  String get reviewReasonNoTemplate;

  /// No description provided for @reviewReasonLlmDisabled.
  ///
  /// In es, this message translates to:
  /// **'Falta lectura automática'**
  String get reviewReasonLlmDisabled;

  /// No description provided for @reviewReasonLlmUnreliable.
  ///
  /// In es, this message translates to:
  /// **'La lectura no fue confiable'**
  String get reviewReasonLlmUnreliable;

  /// No description provided for @reviewReasonOther.
  ///
  /// In es, this message translates to:
  /// **'Necesita tu ayuda'**
  String get reviewReasonOther;

  /// No description provided for @reviewNoText.
  ///
  /// In es, this message translates to:
  /// **'El texto de este mensaje ya no está disponible.'**
  String get reviewNoText;

  /// No description provided for @reviewEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Nada por revisar'**
  String get reviewEmptyTitle;

  /// No description provided for @reviewEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Cuando no podamos leer solos un mensaje de tu banco, aparece aquí para que lo completes.'**
  String get reviewEmptyBody;

  /// No description provided for @reviewLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar los mensajes por revisar.'**
  String get reviewLoadError;

  /// No description provided for @reviewRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get reviewRetry;

  /// No description provided for @reviewCardSemantics.
  ///
  /// In es, this message translates to:
  /// **'Revisar mensaje de {source}, {date}. {reason}'**
  String reviewCardSemantics(String source, String date, String reason);

  /// No description provided for @reviewDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisar mensaje'**
  String get reviewDetailTitle;

  /// No description provided for @reviewNotFound.
  ///
  /// In es, this message translates to:
  /// **'Este mensaje ya no está por revisar.'**
  String get reviewNotFound;

  /// No description provided for @reviewMessageLabel.
  ///
  /// In es, this message translates to:
  /// **'Mensaje del banco'**
  String get reviewMessageLabel;

  /// No description provided for @reviewAmountsHint.
  ///
  /// In es, this message translates to:
  /// **'Toca un monto para usarlo'**
  String get reviewAmountsHint;

  /// No description provided for @reviewShowFullMessage.
  ///
  /// In es, this message translates to:
  /// **'Ver mensaje completo'**
  String get reviewShowFullMessage;

  /// No description provided for @reviewShowLessMessage.
  ///
  /// In es, this message translates to:
  /// **'Ver menos'**
  String get reviewShowLessMessage;

  /// No description provided for @reviewAmountSemantics.
  ///
  /// In es, this message translates to:
  /// **'{amount} pesos'**
  String reviewAmountSemantics(String amount);

  /// No description provided for @reviewUseAmountSemantics.
  ///
  /// In es, this message translates to:
  /// **'Usar {amount} pesos como monto'**
  String reviewUseAmountSemantics(String amount);

  /// No description provided for @reviewFormTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear movimiento'**
  String get reviewFormTitle;

  /// No description provided for @reviewAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get reviewAmountLabel;

  /// No description provided for @reviewAmountRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el monto'**
  String get reviewAmountRequired;

  /// No description provided for @reviewDirectionRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige si es un gasto o un ingreso'**
  String get reviewDirectionRequired;

  /// No description provided for @reviewDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get reviewDateLabel;

  /// No description provided for @reviewTimeLabel.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get reviewTimeLabel;

  /// No description provided for @reviewDateRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige la fecha'**
  String get reviewDateRequired;

  /// No description provided for @reviewDateFromReceived.
  ///
  /// In es, this message translates to:
  /// **'Es la fecha en que llegó el mensaje; cámbiala si no coincide.'**
  String get reviewDateFromReceived;

  /// No description provided for @reviewChangeSemantics.
  ///
  /// In es, this message translates to:
  /// **'{field}: {value}. Cambiar'**
  String reviewChangeSemantics(String field, String value);

  /// No description provided for @reviewMerchantLabel.
  ///
  /// In es, this message translates to:
  /// **'Comercio'**
  String get reviewMerchantLabel;

  /// No description provided for @reviewMerchantHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get reviewMerchantHint;

  /// No description provided for @registerNotesLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get registerNotesLabel;

  /// No description provided for @reviewConvert.
  ///
  /// In es, this message translates to:
  /// **'Crear movimiento'**
  String get reviewConvert;

  /// No description provided for @reviewDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get reviewDiscard;

  /// No description provided for @reviewDiscardTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar este mensaje?'**
  String get reviewDiscardTitle;

  /// No description provided for @reviewDiscardBody.
  ///
  /// In es, this message translates to:
  /// **'Sale de Revisión y no se crea ningún movimiento.'**
  String get reviewDiscardBody;

  /// No description provided for @reviewDiscardConfirm.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get reviewDiscardConfirm;

  /// No description provided for @reviewDiscardCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get reviewDiscardCancel;

  /// No description provided for @reviewConverted.
  ///
  /// In es, this message translates to:
  /// **'Movimiento creado'**
  String get reviewConverted;

  /// No description provided for @reviewDiscarded.
  ///
  /// In es, this message translates to:
  /// **'Descartado'**
  String get reviewDiscarded;

  /// No description provided for @reviewSaveError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el cambio. Intenta de nuevo.'**
  String get reviewSaveError;

  /// No description provided for @registerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Anota un gasto o un ingreso a mano.'**
  String get registerSubtitle;

  /// No description provided for @registerSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar movimiento'**
  String get registerSave;

  /// No description provided for @registerSaved.
  ///
  /// In es, this message translates to:
  /// **'Movimiento guardado'**
  String get registerSaved;

  /// No description provided for @registerSavedOffline.
  ///
  /// In es, this message translates to:
  /// **'Movimiento guardado. Se enviará cuando haya conexión.'**
  String get registerSavedOffline;

  /// No description provided for @registerAmountRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un monto mayor a \$0.'**
  String get registerAmountRequired;

  /// No description provided for @registerSaveError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el movimiento. Intenta de nuevo.'**
  String get registerSaveError;

  /// No description provided for @categoryFormNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva categoría'**
  String get categoryFormNewTitle;

  /// No description provided for @categoryFormEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar categoría'**
  String get categoryFormEditTitle;

  /// No description provided for @categoryFormName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get categoryFormName;

  /// No description provided for @categoryFormNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Mascotas'**
  String get categoryFormNameHint;

  /// No description provided for @categoryFormIcon.
  ///
  /// In es, this message translates to:
  /// **'Ícono'**
  String get categoryFormIcon;

  /// No description provided for @categoryFormColor.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get categoryFormColor;

  /// No description provided for @categoryFormPurpose.
  ///
  /// In es, this message translates to:
  /// **'¿Para qué la usas?'**
  String get categoryFormPurpose;

  /// No description provided for @categoryFormCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear categoría'**
  String get categoryFormCreate;

  /// No description provided for @categoryFormSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get categoryFormSave;

  /// No description provided for @categoryFormCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get categoryFormCancel;

  /// No description provided for @categoryNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre.'**
  String get categoryNameRequired;

  /// No description provided for @categoryNameTooLong.
  ///
  /// In es, this message translates to:
  /// **'Máximo 80 caracteres.'**
  String get categoryNameTooLong;

  /// No description provided for @categoryErrorDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una categoría con ese nombre (tuya o de finanzia).'**
  String get categoryErrorDuplicate;

  /// No description provided for @categoryErrorOffline.
  ///
  /// In es, this message translates to:
  /// **'Necesitas conexión para crear, editar o borrar categorías.'**
  String get categoryErrorOffline;

  /// No description provided for @categoryErrorGone.
  ///
  /// In es, this message translates to:
  /// **'Esa categoría ya no existe.'**
  String get categoryErrorGone;

  /// No description provided for @categoryErrorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar la categoría. Intenta de nuevo.'**
  String get categoryErrorUnexpected;

  /// No description provided for @categoryIconSemantics.
  ///
  /// In es, this message translates to:
  /// **'Ícono {name}'**
  String categoryIconSemantics(String name);

  /// No description provided for @categoryColorSemantics.
  ///
  /// In es, this message translates to:
  /// **'Color {name}'**
  String categoryColorSemantics(String name);

  /// No description provided for @categoryIconLabel.
  ///
  /// In es, this message translates to:
  /// **'Etiqueta'**
  String get categoryIconLabel;

  /// No description provided for @categoryIconPets.
  ///
  /// In es, this message translates to:
  /// **'Mascota'**
  String get categoryIconPets;

  /// No description provided for @categoryIconCart.
  ///
  /// In es, this message translates to:
  /// **'Mercado'**
  String get categoryIconCart;

  /// No description provided for @categoryIconHome.
  ///
  /// In es, this message translates to:
  /// **'Hogar'**
  String get categoryIconHome;

  /// No description provided for @categoryIconHealth.
  ///
  /// In es, this message translates to:
  /// **'Salud'**
  String get categoryIconHealth;

  /// No description provided for @categoryIconCar.
  ///
  /// In es, this message translates to:
  /// **'Carro'**
  String get categoryIconCar;

  /// No description provided for @categoryIconCoffee.
  ///
  /// In es, this message translates to:
  /// **'Café'**
  String get categoryIconCoffee;

  /// No description provided for @categoryIconBook.
  ///
  /// In es, this message translates to:
  /// **'Libro'**
  String get categoryIconBook;

  /// No description provided for @categoryIconGift.
  ///
  /// In es, this message translates to:
  /// **'Regalo'**
  String get categoryIconGift;

  /// No description provided for @categoryIconFlight.
  ///
  /// In es, this message translates to:
  /// **'Viaje'**
  String get categoryIconFlight;

  /// No description provided for @categoryIconPhone.
  ///
  /// In es, this message translates to:
  /// **'Celular'**
  String get categoryIconPhone;

  /// No description provided for @categoryIconBolt.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get categoryIconBolt;

  /// No description provided for @categoryIconMusic.
  ///
  /// In es, this message translates to:
  /// **'Música'**
  String get categoryIconMusic;

  /// No description provided for @categoryIconFitness.
  ///
  /// In es, this message translates to:
  /// **'Deporte'**
  String get categoryIconFitness;

  /// No description provided for @categoryIconClothes.
  ///
  /// In es, this message translates to:
  /// **'Ropa'**
  String get categoryIconClothes;

  /// No description provided for @categoryIconSchool.
  ///
  /// In es, this message translates to:
  /// **'Estudio'**
  String get categoryIconSchool;

  /// No description provided for @categoryColorEmerald.
  ///
  /// In es, this message translates to:
  /// **'Esmeralda'**
  String get categoryColorEmerald;

  /// No description provided for @categoryColorGreen.
  ///
  /// In es, this message translates to:
  /// **'Verde'**
  String get categoryColorGreen;

  /// No description provided for @categoryColorSlate.
  ///
  /// In es, this message translates to:
  /// **'Pizarra'**
  String get categoryColorSlate;

  /// No description provided for @categoryColorTerracotta.
  ///
  /// In es, this message translates to:
  /// **'Terracota'**
  String get categoryColorTerracotta;

  /// No description provided for @categoryColorOchre.
  ///
  /// In es, this message translates to:
  /// **'Ocre'**
  String get categoryColorOchre;

  /// No description provided for @categoryColorPurple.
  ///
  /// In es, this message translates to:
  /// **'Morado'**
  String get categoryColorPurple;

  /// No description provided for @categoryColorRose.
  ///
  /// In es, this message translates to:
  /// **'Rosa'**
  String get categoryColorRose;

  /// No description provided for @categoryColorGraphite.
  ///
  /// In es, this message translates to:
  /// **'Grafito'**
  String get categoryColorGraphite;

  /// No description provided for @fiscalSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Para qué la usas?'**
  String get fiscalSheetTitle;

  /// No description provided for @fiscalSheetBody.
  ///
  /// In es, this message translates to:
  /// **'Define cómo cuenta en tu reporte de renta. Si no sabes, deja «Gasto personal».'**
  String get fiscalSheetBody;

  /// No description provided for @fiscalGroupExpenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get fiscalGroupExpenses;

  /// No description provided for @fiscalGroupContributions.
  ///
  /// In es, this message translates to:
  /// **'Aportes'**
  String get fiscalGroupContributions;

  /// No description provided for @fiscalGroupIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get fiscalGroupIncome;

  /// No description provided for @fiscalNoDeducible.
  ///
  /// In es, this message translates to:
  /// **'Gasto personal'**
  String get fiscalNoDeducible;

  /// No description provided for @fiscalNoDeducibleHint.
  ///
  /// In es, this message translates to:
  /// **'No cuenta en la declaración'**
  String get fiscalNoDeducibleHint;

  /// No description provided for @fiscalDeducibleSalud.
  ///
  /// In es, this message translates to:
  /// **'Salud prepagada o seguros de salud'**
  String get fiscalDeducibleSalud;

  /// No description provided for @fiscalDeducibleSaludHint.
  ///
  /// In es, this message translates to:
  /// **'Puede restar en la renta'**
  String get fiscalDeducibleSaludHint;

  /// No description provided for @fiscalDeducibleVivienda.
  ///
  /// In es, this message translates to:
  /// **'Intereses de crédito de vivienda'**
  String get fiscalDeducibleVivienda;

  /// No description provided for @fiscalDeducibleViviendaHint.
  ///
  /// In es, this message translates to:
  /// **'Puede restar en la renta'**
  String get fiscalDeducibleViviendaHint;

  /// No description provided for @fiscalDonacion.
  ///
  /// In es, this message translates to:
  /// **'Donaciones'**
  String get fiscalDonacion;

  /// No description provided for @fiscalDonacionHint.
  ///
  /// In es, this message translates to:
  /// **'A entidades sin ánimo de lucro'**
  String get fiscalDonacionHint;

  /// No description provided for @fiscalAportePensionVoluntaria.
  ///
  /// In es, this message translates to:
  /// **'Pensión voluntaria'**
  String get fiscalAportePensionVoluntaria;

  /// No description provided for @fiscalAportePensionVoluntariaHint.
  ///
  /// In es, this message translates to:
  /// **'Aportes a fondos voluntarios'**
  String get fiscalAportePensionVoluntariaHint;

  /// No description provided for @fiscalAporteAfc.
  ///
  /// In es, this message translates to:
  /// **'Cuenta AFC'**
  String get fiscalAporteAfc;

  /// No description provided for @fiscalAporteAfcHint.
  ///
  /// In es, this message translates to:
  /// **'Ahorro para vivienda'**
  String get fiscalAporteAfcHint;

  /// No description provided for @fiscalAporteObligatorio.
  ///
  /// In es, this message translates to:
  /// **'Salud y pensión obligatorias'**
  String get fiscalAporteObligatorio;

  /// No description provided for @fiscalAporteObligatorioHint.
  ///
  /// In es, this message translates to:
  /// **'Seguridad social que pagas tú'**
  String get fiscalAporteObligatorioHint;

  /// No description provided for @fiscalIngresoLaboral.
  ///
  /// In es, this message translates to:
  /// **'Salario'**
  String get fiscalIngresoLaboral;

  /// No description provided for @fiscalIngresoLaboralHint.
  ///
  /// In es, this message translates to:
  /// **'Lo que te paga tu empleador'**
  String get fiscalIngresoLaboralHint;

  /// No description provided for @fiscalIngresoHonorarios.
  ///
  /// In es, this message translates to:
  /// **'Honorarios o servicios'**
  String get fiscalIngresoHonorarios;

  /// No description provided for @fiscalIngresoHonorariosHint.
  ///
  /// In es, this message translates to:
  /// **'Trabajo independiente'**
  String get fiscalIngresoHonorariosHint;

  /// No description provided for @fiscalIngresoCapital.
  ///
  /// In es, this message translates to:
  /// **'Arriendos, intereses o rendimientos'**
  String get fiscalIngresoCapital;

  /// No description provided for @fiscalIngresoCapitalHint.
  ///
  /// In es, this message translates to:
  /// **'Rentas de capital'**
  String get fiscalIngresoCapitalHint;

  /// No description provided for @fiscalIngresoPension.
  ///
  /// In es, this message translates to:
  /// **'Pensión'**
  String get fiscalIngresoPension;

  /// No description provided for @fiscalIngresoPensionHint.
  ///
  /// In es, this message translates to:
  /// **'Mesadas pensionales'**
  String get fiscalIngresoPensionHint;

  /// No description provided for @fiscalIngresoNoLaboral.
  ///
  /// In es, this message translates to:
  /// **'Otros ingresos'**
  String get fiscalIngresoNoLaboral;

  /// No description provided for @fiscalIngresoNoLaboralHint.
  ///
  /// In es, this message translates to:
  /// **'Premios, ventas, otros'**
  String get fiscalIngresoNoLaboralHint;

  /// No description provided for @settingsCategoriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis categorías'**
  String get settingsCategoriesTitle;

  /// No description provided for @settingsCategoriesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea y edita tus propias categorías'**
  String get settingsCategoriesSubtitle;

  /// No description provided for @myCategoriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis categorías'**
  String get myCategoriesTitle;

  /// No description provided for @myCategoriesOwnSection.
  ///
  /// In es, this message translates to:
  /// **'Tuyas · solo las ves tú'**
  String get myCategoriesOwnSection;

  /// No description provided for @myCategoriesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes categorías propias. Crea una para ordenar tus gastos a tu manera.'**
  String get myCategoriesEmpty;

  /// No description provided for @myCategoriesNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva categoría'**
  String get myCategoriesNew;

  /// No description provided for @myCategoriesSystemSection.
  ///
  /// In es, this message translates to:
  /// **'De finanzia'**
  String get myCategoriesSystemSection;

  /// No description provided for @myCategoriesSystemNote.
  ///
  /// In es, this message translates to:
  /// **'Las categorías de finanzia se pueden usar, pero no editar ni borrar.'**
  String get myCategoriesSystemNote;

  /// No description provided for @myCategoriesMeta.
  ///
  /// In es, this message translates to:
  /// **'{tag} · {count, plural, =0{sin movimientos} =1{1 movimiento} other{{count} movimientos}}'**
  String myCategoriesMeta(String tag, int count);

  /// No description provided for @myCategoriesEditSemantics.
  ///
  /// In es, this message translates to:
  /// **'Editar {name}'**
  String myCategoriesEditSemantics(String name);

  /// No description provided for @myCategoriesDeleteSemantics.
  ///
  /// In es, this message translates to:
  /// **'Borrar {name}'**
  String myCategoriesDeleteSemantics(String name);

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar «{name}»?'**
  String categoryDeleteTitle(String name);

  /// No description provided for @categoryDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{No tiene movimientos.} =1{Su movimiento pasa a Sin categoría.} other{Sus {count} movimientos pasan a Sin categoría.}} Las reglas que la asignaban solas también se borran. No se puede deshacer.'**
  String categoryDeleteBody(int count);

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Borrar categoría'**
  String get categoryDeleteConfirm;

  /// No description provided for @categoryDeleteCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get categoryDeleteCancel;

  /// No description provided for @categoryDeleted.
  ///
  /// In es, this message translates to:
  /// **'Categoría borrada'**
  String get categoryDeleted;

  /// No description provided for @categoryCreated.
  ///
  /// In es, this message translates to:
  /// **'Categoría creada'**
  String get categoryCreated;

  /// No description provided for @categorySaved.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados'**
  String get categorySaved;

  /// No description provided for @registerOfflineBanner.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Lo que registres se envía al volver.'**
  String get registerOfflineBanner;

  /// No description provided for @registerUndo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get registerUndo;

  /// No description provided for @registerUndone.
  ///
  /// In es, this message translates to:
  /// **'Movimiento deshecho'**
  String get registerUndone;

  /// No description provided for @detailDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar movimiento'**
  String get detailDelete;

  /// No description provided for @detailDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este movimiento?'**
  String get detailDeleteTitle;

  /// No description provided for @detailDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se quita de tus movimientos y de tu reporte. No se puede deshacer.'**
  String get detailDeleteBody;

  /// No description provided for @detailDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get detailDeleteConfirm;

  /// No description provided for @detailDeleteCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get detailDeleteCancel;

  /// No description provided for @detailDeleted.
  ///
  /// In es, this message translates to:
  /// **'Movimiento eliminado'**
  String get detailDeleted;
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
