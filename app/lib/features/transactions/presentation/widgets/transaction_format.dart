import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/domain/transaction_filter.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';

/// Presentación compartida de la lista, las hojas y los estados: nombres,
/// montos, horas y el resumen del filtro.

/// Colombia no tiene horario de verano: hora local = UTC−5 siempre.
const _colombiaOffset = Duration(hours: 5);

/// Campos de calendario de la hora de Colombia para [instant] (como UTC).
DateTime colombiaLocal(DateTime instant) =>
    instant.toUtc().subtract(_colombiaOffset);

/// Instante UTC de la medianoche de Colombia del día [day] (año, mes, día).
DateTime colombiaMidnight(int year, int month, int day) =>
    DateTime.utc(year, month, day).add(_colombiaOffset);

/// `12:41`, hora de Colombia.
String timeOfDay(DateTime instant) {
  final local = colombiaLocal(instant);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}

/// Mes abreviado de tres letras (`sep`), sin el punto ni la "t" que usa
/// CLDR para septiembre.
String _shortMonth(DateTime local) =>
    DateFormat('MMMM', dateLocale).format(local).substring(0, 3);

/// "Martes 23 sep 2026", fecha de Colombia.
String longDate(DateTime instant) {
  final local = colombiaLocal(instant);
  final weekday = capitalize(DateFormat('EEEE', dateLocale).format(local));
  return '$weekday ${local.day} ${_shortMonth(local)} ${local.year}';
}

/// "23 sep", fecha de Colombia.
String shortDate(DateTime instant) {
  final local = colombiaLocal(instant);
  return '${local.day} ${_shortMonth(local)}';
}

/// "Martes 23 sep 2026 · 12:41", hora de Colombia.
String longDateTime(DateTime instant) =>
    '${longDate(instant)} · ${timeOfDay(instant)}';

/// "23 sep · 12:41", hora de Colombia.
String shortDateTime(DateTime instant) {
  final local = colombiaLocal(instant);
  return '${local.day} ${_shortMonth(local)} · ${timeOfDay(instant)}';
}

/// Formato de fechas en español (los datos de `intl` los carga
/// `flutter_localizations`).
const dateLocale = 'es';

String capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// Comercio, o la nota, o "Sin comercio".
String displayName(AppLocalizations l10n, TransactionView tx) {
  final merchant = tx.merchant?.trim() ?? '';
  if (merchant.isNotEmpty) return merchant;
  final notes = tx.notes?.trim() ?? '';
  return notes.isNotEmpty ? notes : l10n.txNoMerchant;
}

bool hasMerchant(TransactionView tx) => tx.merchant?.trim().isNotEmpty ?? false;

AmountSign amountSign(TxKind kind) => switch (kind) {
  TxKind.expense => AmountSign.negative,
  TxKind.income => AmountSign.positive,
  TxKind.transfer => AmountSign.none,
};

Color amountColor(LukaColors colors, TxKind kind) => switch (kind) {
  TxKind.expense => colors.expense,
  TxKind.income => colors.income,
  TxKind.transfer => colors.transfer,
};

/// `−$126.400`, `+$3.500.000` o `$50.000` (lista, sin decimales).
String listAmount(Cop amount, TxKind kind) =>
    formatCop(amount, sign: amountSign(kind));

/// `−$126.400,00` (detalle, con decimales).
String detailAmount(Cop amount, TxKind kind) =>
    formatCop(amount, withDecimals: true, sign: amountSign(kind));

/// Número sin símbolo para el lector de pantalla: `126.400` (o
/// `126.400,00` con [withDecimals]).
String spokenNumber(Cop amount, {bool withDecimals = false}) =>
    formatCop(amount, withDecimals: withDecimals).substring(1);

/// "gasto de 126.400 pesos".
String amountSemantics(
  AppLocalizations l10n,
  Cop amount,
  TxKind kind, {
  bool withDecimals = false,
}) {
  final number = spokenNumber(amount, withDecimals: withDecimals);
  return switch (kind) {
    TxKind.expense => l10n.amountExpenseSemantics(number),
    TxKind.income => l10n.amountIncomeSemantics(number),
    TxKind.transfer => l10n.amountTransferSemantics(number),
  };
}

// ---------------------------------------------------------------- canales

/// Orden de los íconos de canal en la fila (como en el diseño).
const List<TxChannel> channelOrder = [
  TxChannel.notification,
  TxChannel.smsNotification,
  TxChannel.email,
  TxChannel.manual,
];

IconData channelIcon(TxChannel channel) => switch (channel) {
  TxChannel.notification => Icons.notifications_none_rounded,
  TxChannel.smsNotification => Icons.sms_outlined,
  TxChannel.email => Icons.mail_outline_rounded,
  TxChannel.manual => Icons.edit_outlined,
};

String channelName(AppLocalizations l10n, TxChannel channel) =>
    switch (channel) {
      TxChannel.notification => l10n.channelNotification,
      TxChannel.smsNotification => l10n.channelSms,
      TxChannel.email => l10n.channelEmail,
      TxChannel.manual => l10n.channelManual,
    };

/// Opciones de "Fuente" del filtro: "Notificación" cubre también los SMS
/// que llegan como notificación.
List<({String label, Set<TxChannel> channels})> sourceOptions(
  AppLocalizations l10n,
) => [
  (
    label: l10n.channelNotification,
    channels: const {TxChannel.notification, TxChannel.smsNotification},
  ),
  (label: l10n.channelEmail, channels: const {TxChannel.email}),
  (label: l10n.channelManual, channels: const {TxChannel.manual}),
];

// ----------------------------------------------------------------- bancos

/// Bancos del filtro: valor del cable (`Bank` del backend) y nombre.
List<({String wire, String label})> bankOptions(AppLocalizations l10n) => [
  (wire: 'bancolombia', label: l10n.bankBancolombia),
  (wire: 'nequi', label: l10n.bankNequi),
  (wire: 'davivienda', label: l10n.bankDavivienda),
  (wire: 'daviplata', label: l10n.bankDaviplata),
  (wire: 'bbva', label: l10n.bankBbva),
  (wire: 'banco_bogota', label: l10n.bankBancoBogota),
  (wire: 'other', label: l10n.bankOther),
];

/// Nombre de un banco por su valor del cable; uno desconocido se muestra
/// legible (`banco_x` → `Banco x`).
String bankLabel(AppLocalizations l10n, String wire) {
  for (final bank in bankOptions(l10n)) {
    if (bank.wire == wire) return bank.label;
  }
  return capitalize(wire.replaceAll('_', ' '));
}

/// Tipo de cuenta en minúscula (`AccountKind` del backend, spec 004 §2.4);
/// uno desconocido se muestra legible (`cdt_digital` → `cdt digital`).
String accountKindLabel(AppLocalizations l10n, String wire) => switch (wire) {
  'savings' => l10n.accountKindSavings,
  'checking' => l10n.accountKindChecking,
  'credit_card' => l10n.accountKindCreditCard,
  'wallet' => l10n.accountKindWallet,
  _ => wire.replaceAll('_', ' '),
};

/// Cuenta vinculada de [tx]: `"Bancolombia ahorros ···4821"`; sin últimos 4,
/// sin el sufijo. `null` si la transacción no tiene cuenta vinculada.
String? accountLabel(AppLocalizations l10n, TransactionView tx) {
  final bank = tx.accountBank;
  final kind = tx.accountKind;
  if (bank == null || kind == null) return null;
  final bankName = bankLabel(l10n, bank);
  final kindName = accountKindLabel(l10n, kind);
  final last4 = tx.accountLast4;
  return last4 == null || last4.isEmpty
      ? l10n.accountLabel(bankName, kindName)
      : l10n.accountLabelWithLast4(bankName, kindName, last4);
}

/// "Leído con": `rule:<banco>:<plantilla>` → "Plantilla Bancolombia",
/// `llm` → "Lectura automática", `manual` → "Registro manual". `null` si no
/// se reconoce.
String? parsedByLabel(AppLocalizations l10n, String? parsedBy) {
  if (parsedBy == null) return null;
  if (parsedBy == 'llm') return l10n.parsedByLlm;
  if (parsedBy == 'manual') return l10n.parsedByManual;
  final parts = parsedBy.split(':');
  if (parts.length >= 2 && parts.first == 'rule' && parts[1].isNotEmpty) {
    return l10n.parsedByRule(bankLabel(l10n, parts[1]));
  }
  return null;
}

// ---------------------------------------------------------------- periodo

String kindName(AppLocalizations l10n, TxKind kind) => switch (kind) {
  TxKind.expense => l10n.filterKindExpense,
  TxKind.income => l10n.filterKindIncome,
  TxKind.transfer => l10n.filterKindTransfer,
};

String presetName(AppLocalizations l10n, PeriodPreset preset) =>
    switch (preset) {
      PeriodPreset.thisMonth => l10n.filterPeriodThisMonth,
      PeriodPreset.lastMonth => l10n.filterPeriodLastMonth,
      PeriodPreset.thisYear => l10n.filterPeriodThisYear,
      PeriodPreset.custom => l10n.filterPeriodCustom,
    };

/// "23 sep – 30 sep": el rango `[from, to)` de un periodo propio.
String customRangeLabel(
  AppLocalizations l10n,
  TransactionFilter filter,
  DateTime now,
) {
  final range = filter.range(now);
  final format = DateFormat('d MMM', dateLocale);
  final from = colombiaLocal(range.from);
  final lastDay = colombiaLocal(range.to).subtract(const Duration(days: 1));
  return l10n.transactionsPeriodRange(
    format.format(from),
    format.format(lastDay),
  );
}

/// Encabezado del periodo: "Septiembre 2026", "2026" o el rango propio.
String periodHeading(
  AppLocalizations l10n,
  TransactionFilter filter,
  DateTime now,
) {
  if (filter.period == PeriodPreset.custom) {
    return customRangeLabel(l10n, filter, now);
  }
  final from = colombiaLocal(filter.range(now).from);
  if (filter.period == PeriodPreset.thisYear) return '${from.year}';
  return capitalize(DateFormat('MMMM y', dateLocale).format(from));
}

/// Nombre de la categoría del filtro: null sin filtro o mientras cargan las
/// categorías. Un id fuera de la lista es `sin_categoria` (no se asigna a
/// mano, pero el Inicio filtra por ella) y se lee "Sin categoría".
String? filterCategoryName(
  AppLocalizations l10n,
  String? categoryId,
  List<CategoryOption>? categories,
) {
  if (categoryId == null || categories == null) return null;
  return categories.where((c) => c.id == categoryId).firstOrNull?.name ??
      l10n.txNoCategory;
}

/// Resumen del filtro activo: "Este mes · Solo gastos".
String filterSummary(
  AppLocalizations l10n,
  TransactionFilter filter,
  DateTime now, {
  String? categoryName,
}) {
  final parts = <String>[
    if (filter.period == PeriodPreset.custom)
      customRangeLabel(l10n, filter, now)
    else
      presetName(l10n, filter.period),
    if (filter.kinds.length == 1)
      switch (filter.kinds.single) {
        TxKind.expense => l10n.filterOnlyExpenses,
        TxKind.income => l10n.filterOnlyIncome,
        TxKind.transfer => l10n.filterOnlyTransfers,
      }
    else if (filter.kinds.isNotEmpty)
      [
        for (final kind in TxKind.values)
          if (filter.kinds.contains(kind)) kindName(l10n, kind),
      ].join(', '),
    if (filter.banks.isNotEmpty)
      [
        for (final bank in bankOptions(l10n))
          if (filter.banks.contains(bank.wire)) bank.label,
      ].join(', '),
    if (filter.channels.isNotEmpty)
      [
        for (final source in sourceOptions(l10n))
          if (source.channels.any(filter.channels.contains)) source.label,
      ].join(', '),
    ?categoryName,
  ];
  return parts.join(' · ');
}
