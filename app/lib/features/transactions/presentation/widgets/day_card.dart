import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/transactions/domain/day_group.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_row.dart';

/// Tarjeta de un día (diseño S): el número del día grande en tomate,
/// "Hoy", "Ayer" o el día de la semana, el total de gastos y sus
/// movimientos, con borde fino sobre el fondo blanco.
class DayCard extends StatelessWidget {
  const DayCard({
    required this.group,
    required this.onOpen,
    required this.onChangeCategory,
    super.key,
  });

  final DayGroup group;
  final ValueChanged<TransactionView> onOpen;
  final ValueChanged<TransactionView> onChangeCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    // `day` ya trae los campos de calendario de Colombia (00:00 UTC).
    final day = group.day;
    final weekday = DateFormat('EEEE', dateLocale).format(day);
    final month = DateFormat('MMMM', dateLocale).format(day);
    final (title, subtitle) = switch (group.label) {
      DayLabel.today => (l10n.dayToday, weekday),
      DayLabel.yesterday => (l10n.dayYesterday, weekday),
      DayLabel.other => (capitalize(weekday), month),
    };
    final hasExpenses = group.expenses.cents != 0;
    final headerSemantics = [
      l10n.dayHeaderSemantics(
        title,
        DateFormat("EEEE d 'de' MMMM", dateLocale).format(day),
      ),
      if (hasExpenses) l10n.dayExpensesSemantics(spokenNumber(group.expenses)),
    ].join('. ');

    return Material(
      color: brand.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: brand.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              label: headerSemantics,
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  0,
                  Space.md,
                  Space.xs,
                ),
                child: Row(
                  spacing: Space.sm,
                  children: [
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${day.day}',
                        style: textTheme.headlineLarge?.copyWith(
                          fontSize: 34,
                          height: 1,
                          letterSpacing: -1.4,
                          color: scheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleSmall?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasExpenses)
                      Text(
                        formatCop(group.expenses, sign: AmountSign.negative),
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: brand.expense,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            for (final tx in group.items)
              TransactionRow(
                key: ValueKey(tx.id),
                tx: tx,
                onOpen: () => onOpen(tx),
                onChangeCategory: () => onChangeCategory(tx),
              ),
          ],
        ),
      ),
    );
  }
}
