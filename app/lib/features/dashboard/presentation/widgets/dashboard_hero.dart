import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/core/theme/tokens/type_tokens.dart';
import 'package:finanzia/core/time/colombia_month.dart';
import 'package:finanzia/features/dashboard/domain/monthly_summary.dart';
import 'package:finanzia/features/dashboard/presentation/widgets/dashboard_format.dart';
import 'package:finanzia/features/transactions/presentation/widgets/transaction_format.dart';
import 'package:flutter/material.dart';

/// Banda esmeralda del Inicio (diseño A "Balance protagonista"): saludo,
/// línea de sync, selector de mes y, si hay [summary], el balance con las
/// tarjetas de gastos e ingresos.
class DashboardHero extends StatelessWidget {
  const DashboardHero({
    required this.greeting,
    required this.syncLine,
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    this.summary,
    super.key,
  });

  final String greeting;
  final String syncLine;
  final ColombiaMonth month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final MonthlySummary? summary;

  static const _radius = 28.0;

  @override
  Widget build(BuildContext context) {
    final brand = context.finanziaColors;
    final textTheme = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;
    final soft = brand.onHero.withValues(alpha: 0.85);

    return Container(
      padding: EdgeInsets.fromLTRB(Space.md, top + Space.sm, Space.md, 20),
      decoration: BoxDecoration(
        color: brand.hero,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_radius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(
            spacing: Space.sm,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    greeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      color: brand.onHero,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  syncLine,
                  textAlign: TextAlign.end,
                  style: textTheme.bodySmall?.copyWith(color: soft),
                ),
              ),
            ],
          ),
          _MonthSelector(
            month: month,
            canGoNext: canGoNext,
            onPrevious: onPrevious,
            onNext: onNext,
          ),
          if (summary case final summary?) ...[
            _Balance(summary: summary),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Expanded(
                  child: _TotalTile(
                    label: AppLocalizations.of(context).dashboardExpenses,
                    amount: summary.totals.expenses,
                    sign: AmountSign.negative,
                    color: brand.expense,
                    delta: summary.expensesDelta,
                    previous: summary.month.previous,
                  ),
                ),
                Expanded(
                  child: _TotalTile(
                    label: AppLocalizations.of(context).dashboardIncome,
                    amount: summary.totals.income,
                    sign: AmountSign.positive,
                    color: brand.income,
                    delta: summary.incomeDelta,
                    previous: summary.month.previous,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final ColombiaMonth month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.finanziaColors;
    final scheme = Theme.of(context).colorScheme;
    final style = IconButton.styleFrom(
      fixedSize: const Size.square(minTouchTarget),
      minimumSize: const Size.square(minTouchTarget),
      backgroundColor: brand.heroChip,
      foregroundColor: scheme.onPrimaryContainer,
      disabledBackgroundColor: Colors.transparent,
      disabledForegroundColor: brand.onHero.withValues(alpha: 0.35),
    );

    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: l10n.dashboardPreviousMonth,
          style: style,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              monthHeading(month),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 20,
                color: brand.onHero,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: canGoNext ? onNext : null,
          tooltip: l10n.dashboardNextMonth,
          style: style,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({required this.summary});

  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.finanziaColors;
    final textTheme = Theme.of(context).textTheme;
    final balance = summary.balance;
    final (sign, spoken) = switch (balance.cents) {
      > 0 => (AmountSign.positive, 'positive'),
      < 0 => (AmountSign.negative, 'negative'),
      _ => (AmountSign.none, 'none'),
    };

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l10n.dashboardBalanceSemantics(spoken, spokenNumber(balance)),
      child: Column(
        spacing: 2,
        children: [
          Text(
            l10n.dashboardBalance,
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: brand.onHero.withValues(alpha: 0.85),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatCop(balance, sign: sign),
              maxLines: 1,
              style: textTheme.displayMedium?.copyWith(color: brand.onHero),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({
    required this.label,
    required this.amount,
    required this.sign,
    required this.color,
    required this.delta,
    required this.previous,
  });

  final String label;
  final Cop amount;
  final AmountSign sign;
  final Color color;
  final AmountDelta delta;
  final ColombiaMonth previous;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.finanziaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l10n.dashboardTileSemantics(
        label,
        spokenNumber(amount),
        deltaSemantics(l10n, delta, previous),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: brand.heroCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Space.xxs,
          children: [
            Text(label, style: muted?.copyWith(fontWeight: FontWeight.w600)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                formatCop(amount, sign: sign),
                maxLines: 1,
                style: TextStyle(
                  fontFamily: FontFamilies.mono,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  height: 22 / 17,
                  color: color,
                ),
              ),
            ),
            Text(deltaText(l10n, delta, previous), style: muted),
          ],
        ),
      ),
    );
  }
}
