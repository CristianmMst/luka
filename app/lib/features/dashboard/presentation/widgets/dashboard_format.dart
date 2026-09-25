import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/time/colombia_month.dart';
import 'package:finanzia/features/dashboard/domain/monthly_summary.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/transactions/presentation/widgets/transaction_format.dart';
import 'package:intl/intl.dart';

/// Textos del Inicio: meses, deltas, porcentajes y la línea de sync.

DateTime _firstDay(ColombiaMonth month) =>
    DateTime.utc(month.year, month.month);

/// "agosto", para las frases ("vs agosto", "Sin movimientos en agosto").
String monthName(ColombiaMonth month) =>
    DateFormat('MMMM', dateLocale).format(_firstDay(month));

/// "Septiembre 2026", el selector de mes.
String monthHeading(ColombiaMonth month) =>
    capitalize(DateFormat('MMMM y', dateLocale).format(_firstDay(month)));

/// Parte de [total] que es [part], en % entero redondeado (solo en la vista;
/// los montos siguen en centavos).
int sharePercent(Cop part, Cop total) {
  if (total.cents <= 0) return 0;
  return (part.cents * 200 + total.cents) ~/ (total.cents * 2);
}

/// Hubo movimientos (gastos o ingresos) en el mes del resumen.
bool hasMovements(MonthlySummary summary) =>
    summary.totals.expenses.cents != 0 ||
    summary.totals.income.cents != 0 ||
    summary.topCategories.isNotEmpty;

/// "↓ 9 % vs agosto", "= igual que agosto" o "Sin datos de agosto".
String deltaText(
  AppLocalizations l10n,
  AmountDelta delta,
  ColombiaMonth previous,
) {
  final month = monthName(previous);
  final percent = delta.percent;
  if (percent == null) return l10n.dashboardDeltaNoData(month);
  final difference = delta.difference.cents;
  if (difference > 0) return l10n.dashboardDeltaUp(percent.abs(), month);
  if (difference < 0) return l10n.dashboardDeltaDown(percent.abs(), month);
  return l10n.dashboardDeltaSame(month);
}

/// Lo mismo que [deltaText], sin flechas, para el lector de pantalla.
String deltaSemantics(
  AppLocalizations l10n,
  AmountDelta delta,
  ColombiaMonth previous,
) {
  final month = monthName(previous);
  final percent = delta.percent;
  if (percent == null) return l10n.dashboardDeltaNoData(month);
  final difference = delta.difference.cents;
  if (difference > 0) {
    return l10n.dashboardDeltaUpSemantics(percent.abs(), month);
  }
  if (difference < 0) {
    return l10n.dashboardDeltaDownSemantics(percent.abs(), month);
  }
  return l10n.dashboardDeltaSameSemantics(month);
}

/// Nombre de la categoría, o "Sin categoría" si no está en la base local.
String spendName(AppLocalizations l10n, CategorySpend spend) {
  final name = spend.name?.trim() ?? '';
  return name.isEmpty ? l10n.txNoCategory : name;
}

/// Línea provisional del estado de sync (spec 008 §5, hasta F4.8).
String syncLine(AppLocalizations l10n, SyncStatus sync) => switch (sync) {
  SyncStatus(running: true) => l10n.syncStatusRunning,
  SyncStatus(offline: true) => l10n.syncStatusOffline,
  SyncStatus(:final rejected) when rejected > 0 => l10n.syncStatusRejected(
    rejected,
  ),
  SyncStatus(lastSyncedAt: null) => l10n.syncStatusNever,
  SyncStatus(:final pending) => l10n.syncStatusSynced(pending),
};
