import 'package:flutter/material.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/dashboard/domain/monthly_summary.dart';
import 'package:luka/features/dashboard/presentation/widgets/dashboard_format.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// Gastos e ingresos del mes en una sola tarjeta blanca montada sobre el
/// borde de la banda (diseño Q). Cada lado lleva su delta frente al mes
/// anterior en una píldora: verde si mejoró, tomate si empeoró.
class DashboardTotalsCard extends StatelessWidget {
  const DashboardTotalsCard({required this.summary, super.key});

  final MonthlySummary summary;

  /// Alto aproximado que la tarjeta se monta sobre la banda.
  static const overlap = 62.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: brand.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x405C1A10),
            blurRadius: 32,
            spreadRadius: -14,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Side(
                label: l10n.dashboardExpenses,
                amount: summary.totals.expenses,
                sign: AmountSign.negative,
                color: brand.expense,
                delta: summary.expensesDelta,
                previous: summary.month.previous,
                higherIsBetter: false,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: brand.hairline,
            ),
            Expanded(
              child: _Side(
                label: l10n.dashboardIncome,
                amount: summary.totals.income,
                sign: AmountSign.positive,
                color: brand.income,
                delta: summary.incomeDelta,
                previous: summary.month.previous,
                higherIsBetter: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.label,
    required this.amount,
    required this.sign,
    required this.color,
    required this.delta,
    required this.previous,
    required this.higherIsBetter,
  });

  final String label;
  final Cop amount;
  final AmountSign sign;
  final Color color;
  final AmountDelta delta;
  final ColombiaMonth previous;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final difference = delta.difference.cents;
    final (pillBg, pillFg) = switch (delta.percent == null || difference == 0
        ? 0
        : (difference > 0) == higherIsBetter
        ? 1
        : -1) {
      1 => (brand.income.withValues(alpha: 0.12), brand.income),
      -1 => (scheme.primary.withValues(alpha: 0.1), scheme.primary),
      _ => (brand.neutralChip, scheme.onSurfaceVariant),
    };

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l10n.dashboardTileSemantics(
        label,
        spokenNumber(amount),
        deltaSemantics(l10n, delta, previous),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Space.xxs,
          children: [
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                formatCop(amount, sign: sign),
                maxLines: 1,
                style: textTheme.titleLarge?.copyWith(
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: Space.xxs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: Radii.pillAll,
              ),
              child: Text(
                deltaText(l10n, delta, previous),
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: pillFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
