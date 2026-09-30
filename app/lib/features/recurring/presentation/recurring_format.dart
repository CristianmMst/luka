import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/categories/presentation/category_visuals.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/recurring_ports.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/presentation/widgets/category_icon.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// "22 oct": día y mes abreviado sin punto (como Movimientos).
String shortDay(DateTime day) =>
    '${day.day} ${DateFormat('MMMM', dateLocale).format(day).substring(0, 3)}';

/// La línea de estado de una ocurrencia (spec 011 §2).
String occurrenceStateLine(
  AppLocalizations l10n,
  RecurringOccurrence occurrence,
  DateTime today,
) {
  final due = shortDay(occurrence.dueDate);
  return switch (occurrenceStateOf(occurrence, today)) {
    OccurrenceState.upcoming => l10n.recurringStateUpcoming(due),
    OccurrenceState.late => l10n.recurringStateLate(due),
    OccurrenceState.undetected => l10n.recurringStateUndetected(due),
    OccurrenceState.skipped => l10n.recurringStateSkipped,
    OccurrenceState.paid => _paidLine(l10n, occurrence),
  };
}

String _paidLine(AppLocalizations l10n, RecurringOccurrence occurrence) {
  final when = occurrence.transactionOccurredAt ?? occurrence.paidAt;
  final date = when == null ? '' : shortDay(toColombiaLocal(when));
  final merchant = occurrence.transactionMerchant;
  return merchant == null || merchant.isEmpty
      ? l10n.recurringStatePaid(date)
      : l10n.recurringStatePaidWith(date, merchant);
}

/// Monto esperado sin decimales: `$16.900`.
String expectedAmountText(Cop amount) => formatCop(amount);

/// Ícono de la categoría del gasto fijo (o el genérico).
IconData recurringCategoryIcon(CategoryOption? category) {
  if (category == null) return Icons.event_repeat_rounded;
  if (category.isSystem) return categoryIcon(category.slug);
  return ownCategoryIcon(category.icon);
}

/// Mensaje de un fallo de gastos fijos.
String recurringFailureMessage(
  AppLocalizations l10n,
  RecurringFailure failure,
) => switch (failure) {
  RecurringOffline() => l10n.recurringErrorOffline,
  RecurringGone() => l10n.recurringErrorGone,
  RecurringConflict() => l10n.recurringErrorConflict,
  RecurringUnexpected() => l10n.recurringErrorUnexpected,
};
