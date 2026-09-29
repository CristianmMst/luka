// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'finanzia';

  @override
  String get splashRestoring => 'Restaurando tu sesión';

  @override
  String get loginHeadline => 'Tus gastos se anotan solos.';

  @override
  String get loginBody =>
      'finanzia lee las notificaciones y correos de tu banco y deja cada compra registrada una sola vez.';

  @override
  String get loginContinueWithGoogle => 'Continuar con Google';

  @override
  String get loginConnecting => 'Conectando con Google…';

  @override
  String get loginRetryWithGoogle => 'Reintentar con Google';

  @override
  String get loginLegalPrefix => 'Al continuar aceptas los ';

  @override
  String get loginLegalTerms => 'Términos';

  @override
  String get loginLegalJoin => ' y la ';

  @override
  String get loginLegalPrivacy => 'Política de tratamiento de datos';

  @override
  String get loginLegalSuffix => '.';

  @override
  String get tickerNotificationSource => 'NOTIFICACIÓN · BANCOLOMBIA';

  @override
  String get tickerNotificationText => 'Compra en La Espiga';

  @override
  String get tickerEmailSource => 'CORREO · BANCOLOMBIA';

  @override
  String get tickerEmailText => 'Compraste en La Espiga';

  @override
  String get tickerResultTitle => '1 registro';

  @override
  String get tickerResultSubtitle => 'Mercado · sin duplicados';

  @override
  String tickerSemantics(String amount) {
    return 'Ejemplo: una notificación y un correo de la misma compra de $amount quedan como un solo registro.';
  }

  @override
  String get errorNetwork =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.';

  @override
  String errorRateLimited(String countdown) {
    return 'Hiciste muchos intentos seguidos. Podrás volver a intentarlo en $countdown.';
  }

  @override
  String get errorRateLimitedNoWait =>
      'Hiciste muchos intentos seguidos. Espera un momento y vuelve a intentarlo.';

  @override
  String get errorRejected =>
      'Google no confirmó tu cuenta. Inténtalo de nuevo o usa otra cuenta.';

  @override
  String get errorMisconfigured =>
      'El inicio de sesión con Google no está configurado en esta versión de la app.';

  @override
  String get errorUnexpected =>
      'No pudimos iniciar sesión. Inténtalo de nuevo en unos minutos.';

  @override
  String get sessionExpiredNotice =>
      'Tu sesión se cerró para proteger tu cuenta. Inicia sesión de nuevo para seguir.';

  @override
  String homeGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get homeSignOut => 'Cerrar sesión';

  @override
  String get dashboardPreviousMonth => 'Mes anterior';

  @override
  String get dashboardNextMonth => 'Mes siguiente';

  @override
  String get dashboardBalance => 'Balance del mes';

  @override
  String dashboardBalanceSemantics(String sign, String amount) {
    String _temp0 = intl.Intl.selectLogic(
      sign,
      {
        'positive': 'Balance del mes: más $amount pesos',
        'negative': 'Balance del mes: menos $amount pesos',
        'other': 'Balance del mes: $amount pesos',
      },
    );
    return '$_temp0';
  }

  @override
  String get dashboardExpenses => 'Gastos';

  @override
  String get dashboardIncome => 'Ingresos';

  @override
  String dashboardTileSemantics(String label, String amount, String delta) {
    return '$label: $amount pesos. $delta';
  }

  @override
  String dashboardDeltaUp(int percent, String month) {
    return '↑ $percent % vs $month';
  }

  @override
  String dashboardDeltaDown(int percent, String month) {
    return '↓ $percent % vs $month';
  }

  @override
  String dashboardDeltaSame(String month) {
    return '= igual que $month';
  }

  @override
  String dashboardDeltaNoData(String month) {
    return 'Sin datos de $month';
  }

  @override
  String dashboardDeltaUpSemantics(int percent, String month) {
    return '$percent % más que $month';
  }

  @override
  String dashboardDeltaDownSemantics(int percent, String month) {
    return '$percent % menos que $month';
  }

  @override
  String dashboardDeltaSameSemantics(String month) {
    return 'Igual que $month';
  }

  @override
  String get dashboardTopTitle => 'En qué se fue';

  @override
  String get dashboardTopSubtitle => 'Top 5 del gasto';

  @override
  String dashboardCategoryPercent(int percent) {
    return '$percent %';
  }

  @override
  String dashboardCategorySemantics(String name, int percent, String amount) {
    return '$name, $percent % del gasto, $amount';
  }

  @override
  String get dashboardOtherCategories => 'Otras categorías';

  @override
  String dashboardOtherAmount(String amount, int percent) {
    return '$amount · $percent %';
  }

  @override
  String dashboardOtherSemantics(int percent, String amount) {
    return 'Otras categorías, $percent % del gasto, $amount';
  }

  @override
  String dashboardNoExpenses(String month) {
    return 'Sin gastos en $month.';
  }

  @override
  String dashboardEmptyTitle(String month) {
    return 'Sin movimientos en $month';
  }

  @override
  String get dashboardEmptyBody =>
      'Cuando lleguen pagos o ingresos de ese mes, aquí verás en qué se fue tu plata.';

  @override
  String dashboardBackToMonth(String month) {
    return 'Volver a $month';
  }

  @override
  String get dashboardFirstSyncTitle => 'Trayendo tus movimientos';

  @override
  String get dashboardFirstSyncBody =>
      'La primera vez tarda un poco. Tu resumen aparece apenas termine.';

  @override
  String get dashboardOffline => 'Sin conexión — datos locales';

  @override
  String get dashboardLoadError =>
      'No pudimos leer el resumen guardado en el teléfono.';

  @override
  String syncStatusSynced(int pending) {
    String _temp0 = intl.Intl.pluralLogic(
      pending,
      locale: localeName,
      other: '$pending pendientes',
      one: '1 pendiente',
      zero: 'al día',
    );
    return 'Sincronizado · $_temp0';
  }

  @override
  String get syncStatusOffline =>
      'Sin conexión · los cambios se enviarán al volver';

  @override
  String get syncStatusRunning => 'Sincronizando…';

  @override
  String get syncStatusNever => 'Aún no sincronizado';

  @override
  String syncStatusRejected(int rejected) {
    String _temp0 = intl.Intl.pluralLogic(
      rejected,
      locale: localeName,
      other: '$rejected cambios no se pudieron enviar',
      one: '1 cambio no se pudo enviar',
    );
    return '$_temp0';
  }

  @override
  String get navHomeLabel => 'Inicio';

  @override
  String get navTransactionsLabel => 'Movimientos';

  @override
  String get navRegisterLabel => 'Registrar';

  @override
  String get navReviewLabel => 'Revisión';

  @override
  String get navSettingsLabel => 'Ajustes';

  @override
  String reviewBadgeSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count por revisar',
      one: '1 por revisar',
    );
    return '$_temp0';
  }

  @override
  String get shellComingSoonBody => 'Llega pronto';

  @override
  String get transactionsSearchHint => 'Buscar comercio, categoría o nota';

  @override
  String get transactionsFilters => 'Filtros';

  @override
  String transactionsFiltersSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Filtros, $count activos',
      one: 'Filtros, 1 activo',
      zero: 'Filtros',
    );
    return '$_temp0';
  }

  @override
  String transactionsPeriodRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get transactionsLoadError => 'No pudimos cargar tus movimientos.';

  @override
  String get transactionsRetry => 'Reintentar';

  @override
  String get filterPeriod => 'Periodo';

  @override
  String get filterPeriodThisMonth => 'Este mes';

  @override
  String get filterPeriodLastMonth => 'Mes pasado';

  @override
  String get filterPeriodThisYear => 'Este año';

  @override
  String get filterPeriodCustom => 'Elegir fechas';

  @override
  String get filterKind => 'Tipo';

  @override
  String get filterKindExpense => 'Gastos';

  @override
  String get filterKindIncome => 'Ingresos';

  @override
  String get filterKindTransfer => 'Transferencias';

  @override
  String get filterOnlyExpenses => 'Solo gastos';

  @override
  String get filterOnlyIncome => 'Solo ingresos';

  @override
  String get filterOnlyTransfers => 'Solo transferencias';

  @override
  String get filterBank => 'Banco';

  @override
  String get filterSource => 'Fuente';

  @override
  String get filterCategory => 'Categoría';

  @override
  String get filterCategoryAll => 'Todas';

  @override
  String get filterClear => 'Limpiar';

  @override
  String filterApply(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ver $count movimientos',
      one: 'Ver 1 movimiento',
    );
    return '$_temp0';
  }

  @override
  String get filterApplyUncounted => 'Ver movimientos';

  @override
  String get bankBancolombia => 'Bancolombia';

  @override
  String get bankNequi => 'Nequi';

  @override
  String get bankDavivienda => 'Davivienda';

  @override
  String get bankDaviplata => 'Daviplata';

  @override
  String get bankBbva => 'BBVA';

  @override
  String get bankBancoBogota => 'Banco de Bogotá';

  @override
  String get bankOther => 'Otro';

  @override
  String get accountKindSavings => 'ahorros';

  @override
  String get accountKindChecking => 'corriente';

  @override
  String get accountKindCreditCard => 'tarjeta de crédito';

  @override
  String get accountKindWallet => 'billetera';

  @override
  String accountLabel(String bank, String kind) {
    return '$bank $kind';
  }

  @override
  String accountLabelWithLast4(String bank, String kind, String last4) {
    return '$bank $kind ···$last4';
  }

  @override
  String get channelNotification => 'Notificación';

  @override
  String get channelSms => 'SMS';

  @override
  String get channelEmail => 'Correo';

  @override
  String get channelManual => 'Manual';

  @override
  String get channelNfc => 'NFC';

  @override
  String channelsSemantics(String channels) {
    return 'Fuentes: $channels';
  }

  @override
  String get dayToday => 'Hoy';

  @override
  String get dayYesterday => 'Ayer';

  @override
  String dayHeaderSemantics(String day, String date) {
    return '$day, $date';
  }

  @override
  String dayExpensesSemantics(String amount) {
    return 'gastos del día: $amount pesos';
  }

  @override
  String amountExpenseSemantics(String amount) {
    return 'gasto de $amount pesos';
  }

  @override
  String amountIncomeSemantics(String amount) {
    return 'ingreso de $amount pesos';
  }

  @override
  String amountTransferSemantics(String amount) {
    return 'transferencia de $amount pesos';
  }

  @override
  String get txNoMerchant => 'Sin comercio';

  @override
  String get txNoCategory => 'Sin categoría';

  @override
  String txChangeCategorySemantics(String category) {
    return 'Cambiar categoría: $category';
  }

  @override
  String get txSyncPending => 'Por enviar';

  @override
  String get txSyncRejected => 'No enviado';

  @override
  String get categorySheetTitle => 'Categoría';

  @override
  String categorySheetSubtitle(String merchant, String amount) {
    return '$merchant · $amount';
  }

  @override
  String get categorySheetAll => 'Todas';

  @override
  String get categorySheetNew => '+ Nueva categoría';

  @override
  String merchantRuleTitle(String merchant) {
    return '¿Aplicar siempre a $merchant?';
  }

  @override
  String get merchantRuleBodyBefore =>
      'Los próximos movimientos de este comercio quedarán en ';

  @override
  String get merchantRuleBodyAfter => '. Puedes cambiarlo cuando quieras.';

  @override
  String merchantRuleAlways(String merchant) {
    return 'Siempre para $merchant';
  }

  @override
  String get merchantRuleOnce => 'Solo este movimiento';

  @override
  String get offlineBanner => 'Sin conexión · ves tus datos guardados';

  @override
  String get rejectedTitle => 'No se guardó un cambio';

  @override
  String rejectedBody(String merchant) {
    return '$merchant no quedó así en tu cuenta. Puedes intentarlo otra vez o dejarlo como estaba.';
  }

  @override
  String get rejectedDiscard => 'Dejar como estaba';

  @override
  String get rejectedRetry => 'Reintentar';

  @override
  String get emptyTitle => 'Aún no hay movimientos';

  @override
  String get emptyBody =>
      'Cuando llegue una notificación o un correo de tu banco, lo verás aquí. También puedes anotar un gasto a mano.';

  @override
  String get emptyCta => 'Registrar un gasto';

  @override
  String get noResultsTitle => 'Ningún movimiento coincide';

  @override
  String noResultsTitleText(String text) {
    return 'Nada coincide con “$text”';
  }

  @override
  String noResultsBody(String summary) {
    return 'Con los filtros: $summary.';
  }

  @override
  String get noResultsClear => 'Quitar filtros';

  @override
  String get firstSyncLoading => 'Trayendo tus movimientos…';

  @override
  String get detailTitle => 'Movimiento';

  @override
  String get detailBack => 'Volver';

  @override
  String get detailNotFound => 'Este movimiento ya no existe.';

  @override
  String get detailLoadError => 'No pudimos cargar este movimiento.';

  @override
  String get detailTransferBadge => 'TRANSFERENCIA PROPIA';

  @override
  String get detailTransferNote => 'No cuenta como gasto ni como ingreso';

  @override
  String get detailCategory => 'Categoría';

  @override
  String get detailAccount => 'Cuenta';

  @override
  String get detailNoAccount => 'Sin cuenta';

  @override
  String get detailKind => 'Tipo';

  @override
  String get detailKindExpense => 'Gasto';

  @override
  String get detailKindIncome => 'Ingreso';

  @override
  String get detailKindTransfer => 'Transferencia propia';

  @override
  String get detailParsedBy => 'Leído con';

  @override
  String parsedByRule(String bank) {
    return 'Plantilla $bank';
  }

  @override
  String get parsedByLlm => 'Lectura automática';

  @override
  String get parsedByManual => 'Registro manual';

  @override
  String get detailSources => 'Fuentes';

  @override
  String detailSourcesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canales',
      one: '1 canal',
    );
    return '$_temp0';
  }

  @override
  String get sourceNotification => 'Notificación del banco';

  @override
  String get sourceSms => 'SMS del banco';

  @override
  String get sourceEmail => 'Correo del banco';

  @override
  String get sourceManual => 'Registro manual';

  @override
  String get sourceNfc => 'Etiqueta NFC';

  @override
  String sourceReceived(String gender, String when) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'female': 'Recibida $when',
        'male': 'Recibido $when',
        'other': 'Registrado $when',
      },
    );
    return '$_temp0';
  }

  @override
  String sourcesSeal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '1 registro con $count fuentes, sin duplicados',
      one: '1 registro con 1 fuente',
    );
    return '$_temp0';
  }

  @override
  String get sourcesOffline =>
      'Las fuentes se consultan con conexión. El resto del movimiento está guardado en tu teléfono.';

  @override
  String get sourcesEmpty =>
      'Las fuentes aparecen cuando el movimiento llega a tu cuenta en el servidor.';

  @override
  String get detailMarkTransfer => 'Marcar como transferencia propia';

  @override
  String get detailUnmarkTransfer => 'No es una transferencia';

  @override
  String get detailPairLabel => 'La otra parte';

  @override
  String detailPairValue(String account, String direction, String time) {
    String _temp0 = intl.Intl.selectLogic(
      direction,
      {
        'credit': 'recibida',
        'other': 'enviada',
      },
    );
    return '$account · $_temp0 $time';
  }

  @override
  String detailPairSemantics(String value) {
    return 'Abrir la otra parte: $value';
  }

  @override
  String get detailNotes => 'Notas';

  @override
  String get detailNotesHint => 'Agrega una nota para ti';

  @override
  String get emptyPeriodTitle => 'Sin movimientos este mes';

  @override
  String get emptyPeriodBody =>
      'Tus movimientos anteriores siguen guardados. Revisa el mes pasado o cambia los filtros.';

  @override
  String get emptyPeriodLastMonth => 'Ver mes pasado';

  @override
  String get emptyPeriodFilters => 'Cambiar filtros';

  @override
  String get gmailHeroLabel => 'SOLO ALERTAS DE TUS BANCOS';

  @override
  String get gmailHeroBanks => 'Bancolombia · Nequi · Davivienda · BBVA';

  @override
  String get gmailHeroSemantics =>
      'finanzia solo lee los correos de alerta de bancos como Bancolombia, Nequi, Davivienda y BBVA.';

  @override
  String get gmailOnboardingTitle => 'Conecta tu Gmail';

  @override
  String get gmailOnboardingBody =>
      'Tus compras quedan registradas solas, sin duplicados.';

  @override
  String get gmailReadsLabel => 'Lee';

  @override
  String get gmailReads =>
      'Correos de alertas de tus bancos (Bancolombia, Nequi…).';

  @override
  String get gmailNeverReadsLabel => 'Nunca lee';

  @override
  String get gmailNeverReads => 'Tu correo personal, contactos ni adjuntos.';

  @override
  String get gmailConnect => 'Conectar Gmail';

  @override
  String get gmailConnecting => 'Conectando Gmail…';

  @override
  String get gmailRetry => 'Reintentar';

  @override
  String get gmailNotNow => 'Ahora no';

  @override
  String get gmailRevokeNote =>
      'Puedes quitar el permiso cuando quieras desde Ajustes o desde tu cuenta de Google.';

  @override
  String get gmailErrorRejected =>
      'Google no aceptó la autorización. Inténtalo de nuevo.';

  @override
  String get gmailErrorScopeDenied =>
      'Para conectar Gmail, marca el permiso de lectura de correos en la pantalla de Google.';

  @override
  String get gmailErrorUpstream =>
      'No pudimos hablar con Google. Inténtalo de nuevo en unos minutos.';

  @override
  String get gmailErrorMisconfigured =>
      'La conexión con Gmail no está configurada en esta versión de la app.';

  @override
  String get gmailErrorUnexpected =>
      'No pudimos conectar Gmail. Inténtalo de nuevo.';

  @override
  String get gmailConnectedInactive =>
      'Conectado, pero no pudimos activar la captura; reintenta desde Ajustes.';

  @override
  String get settingsGmailTitle => 'Gmail';

  @override
  String settingsGmailConnected(String email) {
    return 'Conectado · $email';
  }

  @override
  String get settingsGmailConnectedNoEmail => 'Conectado';

  @override
  String get settingsGmailRevoked =>
      'Google quitó el permiso. Reconecta para seguir capturando.';

  @override
  String get settingsGmailError =>
      'La captura de correos se detuvo. Reconecta para reanudarla.';

  @override
  String get settingsGmailDisconnected =>
      'Sin conectar · tus compras por correo no se registran';

  @override
  String get settingsGmailLoading => 'Consultando Gmail…';

  @override
  String get settingsGmailUnavailable =>
      'No pudimos consultar el estado de Gmail.';

  @override
  String get settingsGmailConnect => 'Conectar';

  @override
  String get settingsGmailReconnect => 'Reconectar';

  @override
  String get settingsGmailDisconnect => 'Desconectar';

  @override
  String get settingsGmailRetry => 'Reintentar';

  @override
  String settingsGmailActionSemantics(String action) {
    return '$action Gmail';
  }

  @override
  String get settingsGmailDisconnectTitle => '¿Desconectar Gmail?';

  @override
  String get settingsGmailDisconnectBody =>
      'Dejamos de leer los correos de tus bancos. Los movimientos que ya tienes se quedan.';

  @override
  String get settingsGmailDisconnectConfirm => 'Desconectar';

  @override
  String get settingsGmailDisconnectCancel => 'Cancelar';

  @override
  String get settingsNotificationsTitle => 'Notificaciones del banco';

  @override
  String get settingsNotificationsActive =>
      'Activo · registramos tus pagos apenas llegan';

  @override
  String get settingsNotificationsInactive =>
      'Inactivo · los pagos que te notifica el banco no se registran';

  @override
  String get settingsNotificationsLoading => 'Consultando el permiso…';

  @override
  String get settingsNotificationsEnable => 'Activar';

  @override
  String get settingsNotificationsManage => 'Administrar';

  @override
  String settingsNotificationsActionSemantics(String action) {
    return '$action notificaciones del banco';
  }

  @override
  String get notificationDisclosureTitle => 'Registra tus pagos al instante';

  @override
  String get notificationDisclosureBody =>
      'Con el acceso a notificaciones, finanzia registra cada compra o transferencia apenas tu banco te avisa, sin que escribas nada.';

  @override
  String get notificationDisclosureReads =>
      'Leemos solo las notificaciones de las apps de tus bancos y los SMS que envían tus bancos.';

  @override
  String get notificationDisclosureIgnores =>
      'Ignoramos todo lo demás: chats, correos y SMS de otras personas no se guardan ni salen de tu teléfono.';

  @override
  String get notificationDisclosureRevoke =>
      'Puedes quitar el permiso cuando quieras en los ajustes del teléfono.';

  @override
  String get notificationDisclosureContinue => 'Ir a los ajustes';

  @override
  String get notificationDisclosureCancel => 'Ahora no';

  @override
  String reviewSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes por revisar',
      one: '1 mensaje por revisar',
      zero: 'Todo al día',
    );
    return '$_temp0';
  }

  @override
  String get reviewReasonNoTemplate => 'No reconocimos el formato';

  @override
  String get reviewReasonLlmDisabled => 'Falta lectura automática';

  @override
  String get reviewReasonLlmUnreliable => 'La lectura no fue confiable';

  @override
  String get reviewReasonOther => 'Necesita tu ayuda';

  @override
  String get reviewNoText => 'El texto de este mensaje ya no está disponible.';

  @override
  String get reviewEmptyTitle => 'Nada por revisar';

  @override
  String get reviewEmptyBody =>
      'Cuando no podamos leer solos un mensaje de tu banco, aparece aquí para que lo completes.';

  @override
  String get reviewLoadError => 'No pudimos cargar los mensajes por revisar.';

  @override
  String get reviewRetry => 'Reintentar';

  @override
  String reviewCardSemantics(String source, String date, String reason) {
    return 'Revisar mensaje de $source, $date. $reason';
  }

  @override
  String get reviewDetailTitle => 'Revisar mensaje';

  @override
  String get reviewNotFound => 'Este mensaje ya no está por revisar.';

  @override
  String get reviewMessageLabel => 'Mensaje del banco';

  @override
  String get reviewAmountsHint => 'Toca un monto para usarlo';

  @override
  String get reviewShowFullMessage => 'Ver mensaje completo';

  @override
  String get reviewShowLessMessage => 'Ver menos';

  @override
  String reviewAmountSemantics(String amount) {
    return '$amount pesos';
  }

  @override
  String reviewUseAmountSemantics(String amount) {
    return 'Usar $amount pesos como monto';
  }

  @override
  String get reviewFormTitle => 'Crear movimiento';

  @override
  String get reviewAmountLabel => 'Monto';

  @override
  String get reviewAmountRequired => 'Escribe el monto';

  @override
  String get reviewDirectionRequired => 'Elige si es un gasto o un ingreso';

  @override
  String get reviewDateLabel => 'Fecha';

  @override
  String get reviewTimeLabel => 'Hora';

  @override
  String get reviewDateRequired => 'Elige la fecha';

  @override
  String get reviewDateFromReceived =>
      'Es la fecha en que llegó el mensaje; cámbiala si no coincide.';

  @override
  String reviewChangeSemantics(String field, String value) {
    return '$field: $value. Cambiar';
  }

  @override
  String get reviewMerchantLabel => 'Comercio';

  @override
  String get reviewMerchantHint => 'Opcional';

  @override
  String get registerNotesLabel => 'Nota';

  @override
  String get reviewConvert => 'Crear movimiento';

  @override
  String get reviewDiscard => 'Descartar';

  @override
  String get reviewDiscardTitle => '¿Descartar este mensaje?';

  @override
  String get reviewDiscardBody =>
      'Sale de Revisión y no se crea ningún movimiento.';

  @override
  String get reviewDiscardConfirm => 'Descartar';

  @override
  String get reviewDiscardCancel => 'Cancelar';

  @override
  String get reviewConverted => 'Movimiento creado';

  @override
  String get reviewDiscarded => 'Descartado';

  @override
  String get reviewSaveError =>
      'No pudimos guardar el cambio. Intenta de nuevo.';

  @override
  String get registerSubtitle => 'Anota un gasto o un ingreso a mano.';

  @override
  String get registerSave => 'Guardar movimiento';

  @override
  String get registerSaved => 'Movimiento guardado';

  @override
  String get registerSavedOffline =>
      'Movimiento guardado. Se enviará cuando haya conexión.';

  @override
  String get registerAmountRequired => 'Escribe un monto mayor a \$0.';

  @override
  String get registerSaveError =>
      'No pudimos guardar el movimiento. Intenta de nuevo.';

  @override
  String get categoryFormNewTitle => 'Nueva categoría';

  @override
  String get categoryFormEditTitle => 'Editar categoría';

  @override
  String get categoryFormName => 'Nombre';

  @override
  String get categoryFormNameHint => 'Ej.: Mascotas';

  @override
  String get categoryFormIcon => 'Ícono';

  @override
  String get categoryFormColor => 'Color';

  @override
  String get categoryFormPurpose => '¿Para qué la usas?';

  @override
  String get categoryFormCreate => 'Crear categoría';

  @override
  String get categoryFormSave => 'Guardar cambios';

  @override
  String get categoryFormCancel => 'Cancelar';

  @override
  String get categoryNameRequired => 'Escribe un nombre.';

  @override
  String get categoryNameTooLong => 'Máximo 80 caracteres.';

  @override
  String get categoryErrorDuplicate =>
      'Ya existe una categoría con ese nombre (tuya o de finanzia).';

  @override
  String get categoryErrorOffline =>
      'Necesitas conexión para crear, editar o borrar categorías.';

  @override
  String get categoryErrorGone => 'Esa categoría ya no existe.';

  @override
  String get categoryErrorUnexpected =>
      'No pudimos guardar la categoría. Intenta de nuevo.';

  @override
  String categoryIconSemantics(String name) {
    return 'Ícono $name';
  }

  @override
  String categoryColorSemantics(String name) {
    return 'Color $name';
  }

  @override
  String get categoryIconLabel => 'Etiqueta';

  @override
  String get categoryIconPets => 'Mascota';

  @override
  String get categoryIconCart => 'Mercado';

  @override
  String get categoryIconHome => 'Hogar';

  @override
  String get categoryIconHealth => 'Salud';

  @override
  String get categoryIconCar => 'Carro';

  @override
  String get categoryIconCoffee => 'Café';

  @override
  String get categoryIconBook => 'Libro';

  @override
  String get categoryIconGift => 'Regalo';

  @override
  String get categoryIconFlight => 'Viaje';

  @override
  String get categoryIconPhone => 'Celular';

  @override
  String get categoryIconBolt => 'Servicios';

  @override
  String get categoryIconMusic => 'Música';

  @override
  String get categoryIconFitness => 'Deporte';

  @override
  String get categoryIconClothes => 'Ropa';

  @override
  String get categoryIconSchool => 'Estudio';

  @override
  String get categoryColorEmerald => 'Esmeralda';

  @override
  String get categoryColorGreen => 'Verde';

  @override
  String get categoryColorSlate => 'Pizarra';

  @override
  String get categoryColorTerracotta => 'Terracota';

  @override
  String get categoryColorOchre => 'Ocre';

  @override
  String get categoryColorPurple => 'Morado';

  @override
  String get categoryColorRose => 'Rosa';

  @override
  String get categoryColorGraphite => 'Grafito';

  @override
  String get fiscalSheetTitle => '¿Para qué la usas?';

  @override
  String get fiscalSheetBody =>
      'Define cómo cuenta en tu reporte de renta. Si no sabes, deja «Gasto personal».';

  @override
  String get fiscalGroupExpenses => 'Gastos';

  @override
  String get fiscalGroupContributions => 'Aportes';

  @override
  String get fiscalGroupIncome => 'Ingresos';

  @override
  String get fiscalNoDeducible => 'Gasto personal';

  @override
  String get fiscalNoDeducibleHint => 'No cuenta en la declaración';

  @override
  String get fiscalDeducibleSalud => 'Salud prepagada o seguros de salud';

  @override
  String get fiscalDeducibleSaludHint => 'Puede restar en la renta';

  @override
  String get fiscalDeducibleVivienda => 'Intereses de crédito de vivienda';

  @override
  String get fiscalDeducibleViviendaHint => 'Puede restar en la renta';

  @override
  String get fiscalDonacion => 'Donaciones';

  @override
  String get fiscalDonacionHint => 'A entidades sin ánimo de lucro';

  @override
  String get fiscalAportePensionVoluntaria => 'Pensión voluntaria';

  @override
  String get fiscalAportePensionVoluntariaHint =>
      'Aportes a fondos voluntarios';

  @override
  String get fiscalAporteAfc => 'Cuenta AFC';

  @override
  String get fiscalAporteAfcHint => 'Ahorro para vivienda';

  @override
  String get fiscalAporteObligatorio => 'Salud y pensión obligatorias';

  @override
  String get fiscalAporteObligatorioHint => 'Seguridad social que pagas tú';

  @override
  String get fiscalIngresoLaboral => 'Salario';

  @override
  String get fiscalIngresoLaboralHint => 'Lo que te paga tu empleador';

  @override
  String get fiscalIngresoHonorarios => 'Honorarios o servicios';

  @override
  String get fiscalIngresoHonorariosHint => 'Trabajo independiente';

  @override
  String get fiscalIngresoCapital => 'Arriendos, intereses o rendimientos';

  @override
  String get fiscalIngresoCapitalHint => 'Rentas de capital';

  @override
  String get fiscalIngresoPension => 'Pensión';

  @override
  String get fiscalIngresoPensionHint => 'Mesadas pensionales';

  @override
  String get fiscalIngresoNoLaboral => 'Otros ingresos';

  @override
  String get fiscalIngresoNoLaboralHint => 'Premios, ventas, otros';

  @override
  String get settingsCategoriesTitle => 'Mis categorías';

  @override
  String get settingsCategoriesSubtitle =>
      'Crea y edita tus propias categorías';

  @override
  String get myCategoriesTitle => 'Mis categorías';

  @override
  String get myCategoriesOwnSection => 'Tuyas · solo las ves tú';

  @override
  String get myCategoriesEmpty =>
      'Aún no tienes categorías propias. Crea una para ordenar tus gastos a tu manera.';

  @override
  String get myCategoriesNew => 'Nueva categoría';

  @override
  String get myCategoriesSystemSection => 'De finanzia';

  @override
  String get myCategoriesSystemNote =>
      'Las categorías de finanzia se pueden usar, pero no editar ni borrar.';

  @override
  String myCategoriesMeta(String tag, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimientos',
      one: '1 movimiento',
      zero: 'sin movimientos',
    );
    return '$tag · $_temp0';
  }

  @override
  String myCategoriesEditSemantics(String name) {
    return 'Editar $name';
  }

  @override
  String myCategoriesDeleteSemantics(String name) {
    return 'Borrar $name';
  }

  @override
  String categoryDeleteTitle(String name) {
    return '¿Borrar «$name»?';
  }

  @override
  String categoryDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sus $count movimientos pasan a Sin categoría.',
      one: 'Su movimiento pasa a Sin categoría.',
      zero: 'No tiene movimientos.',
    );
    return '$_temp0 Las reglas que la asignaban solas también se borran. No se puede deshacer.';
  }

  @override
  String get categoryDeleteConfirm => 'Borrar categoría';

  @override
  String get categoryDeleteCancel => 'Cancelar';

  @override
  String get categoryDeleted => 'Categoría borrada';

  @override
  String get categoryCreated => 'Categoría creada';

  @override
  String get categorySaved => 'Cambios guardados';

  @override
  String get registerOfflineBanner =>
      'Sin conexión. Lo que registres se envía al volver.';

  @override
  String get registerUndo => 'Deshacer';

  @override
  String get registerUndone => 'Movimiento deshecho';

  @override
  String get detailDelete => 'Eliminar movimiento';

  @override
  String get detailDeleteTitle => '¿Eliminar este movimiento?';

  @override
  String get detailDeleteBody =>
      'Se quita de tus movimientos y de tu reporte. No se puede deshacer.';

  @override
  String get detailDeleteConfirm => 'Eliminar';

  @override
  String get detailDeleteCancel => 'Cancelar';

  @override
  String get detailDeleted => 'Movimiento eliminado';

  @override
  String get settingsAccountsTitle => 'Mis cuentas';

  @override
  String get settingsAccountsSubtitle =>
      'Para reconocer tus transferencias propias';

  @override
  String get myAccountsTitle => 'Mis cuentas';

  @override
  String get myAccountsIntro =>
      'Con tus cuentas separamos lo que pasas entre ellas de tus gastos e ingresos reales.';

  @override
  String get myAccountsEmpty =>
      'Aún no tienes cuentas. Agrega las de tus bancos.';

  @override
  String get accountsAdd => 'Agregar cuenta';

  @override
  String accountRowMeta(String bank, String kind) {
    return '$bank · $kind';
  }

  @override
  String accountRowMetaWithLast4(String bank, String kind, String last4) {
    return '$bank · $kind ···$last4';
  }

  @override
  String accountEditSemantics(String name) {
    return 'Editar $name';
  }

  @override
  String accountDeleteSemantics(String name) {
    return 'Borrar $name';
  }

  @override
  String get accountFormNewTitle => 'Nueva cuenta';

  @override
  String get accountFormEditTitle => 'Editar cuenta';

  @override
  String get accountFormBank => 'Banco';

  @override
  String get accountFormBankHint => 'Elige tu banco';

  @override
  String get accountFormBankLocked =>
      'El banco no se puede cambiar; si te equivocaste, borra la cuenta y créala de nuevo.';

  @override
  String get accountFormKind => 'Tipo';

  @override
  String get accountFormLast4 => 'Últimos 4 (opcional)';

  @override
  String get accountFormAlias => 'Alias (opcional)';

  @override
  String get accountFormAliasHint => 'Ej. Nómina';

  @override
  String get accountFormCreate => 'Guardar cuenta';

  @override
  String get accountFormSave => 'Guardar';

  @override
  String get accountFormCancel => 'Cancelar';

  @override
  String get accountBankRequired => 'Elige el banco.';

  @override
  String get accountLast4Invalid => 'Escribe de 1 a 4 números.';

  @override
  String get accountAliasTooLong => 'Máximo 60 caracteres.';

  @override
  String get accountErrorDuplicate =>
      'Ya tienes una cuenta de ese banco con esos últimos 4.';

  @override
  String get accountErrorOffline =>
      'Necesitas conexión para agregar, editar o borrar cuentas.';

  @override
  String get accountErrorGone => 'Esa cuenta ya no existe.';

  @override
  String get accountErrorUnexpected =>
      'No pudimos guardar la cuenta. Intenta de nuevo.';

  @override
  String get accountCreated => 'Cuenta agregada';

  @override
  String get accountSaved => 'Cuenta guardada';

  @override
  String get accountDeleted => 'Cuenta borrada';

  @override
  String accountDeleteTitle(String name) {
    return '¿Borrar «$name»?';
  }

  @override
  String accountDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sus $count movimientos quedan sin cuenta.',
      one: 'Su movimiento queda sin cuenta.',
      zero: 'No tiene movimientos.',
    );
    return '$_temp0 No se puede deshacer.';
  }

  @override
  String get accountDeleteConfirm => 'Borrar cuenta';

  @override
  String get accountDeleteCancel => 'Cancelar';
}
