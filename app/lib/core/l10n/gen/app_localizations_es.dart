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
  String get homePlaceholderBody =>
      'Ya iniciaste sesión. El resumen de tus gastos llega en la siguiente fase.';

  @override
  String get homeSignOut => 'Cerrar sesión';

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
}
