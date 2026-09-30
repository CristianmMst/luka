import 'package:flutter/material.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/theme/tokens/type_tokens.dart';
import 'package:luka/features/dashboard/domain/monthly_summary.dart';
import 'package:luka/features/dashboard/presentation/widgets/dashboard_format.dart';
import 'package:luka/features/transactions/presentation/widgets/category_icon.dart';

/// "En qué se fue": top 5 del gasto con barras relativas a la mayor, el %
/// del gasto total y "Otras categorías". Tocar una fila llama a [onOpen]
/// con su `categoryId` (las que no tienen id no se pueden abrir, y ninguna
/// si [onOpen] es null).
class TopCategoriesCard extends StatelessWidget {
  const TopCategoriesCard({
    required this.summary,
    required this.onOpen,
    super.key,
  });

  final MonthlySummary summary;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = summary.totals.expenses;
    final top = summary.topCategories;
    final largest = top.isEmpty ? 0 : top.first.amount.cents;
    final other = summary.otherAmount;

    return Material(
      color: brand.card,
      borderRadius: Radii.cardAll,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.dashboardTopTitle,
                        style: textTheme.headlineSmall?.copyWith(fontSize: 20),
                      ),
                    ),
                  ),
                  Text(
                    l10n.dashboardTopSubtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (top.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.sm),
                child: Text(
                  l10n.dashboardNoExpenses(monthName(summary.month)),
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final spend in top)
              _CategoryRow(
                spend: spend,
                percent: sharePercent(spend.amount, total),
                fraction: largest <= 0 ? 0 : spend.amount.cents / largest,
                onTap: switch ((spend.categoryId, onOpen)) {
                  (final id?, final open?) => () => open(id),
                  _ => null,
                },
              ),
            if (other.cents > 0) _OtherRow(amount: other, total: total),
          ],
        ),
      ),
    );
  }
}

/// Separador fino entre filas.
BorderSide _hairline(BuildContext context) =>
    BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHigh);

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.spend,
    required this.percent,
    required this.fraction,
    required this.onTap,
  });

  final CategorySpend spend;
  final int percent;

  /// Ancho de la barra frente a la categoría mayor (0–1, solo de vista).
  final double fraction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = spendName(l10n, spend);
    final amount = formatCop(spend.amount);

    return Semantics(
      button: onTap != null,
      excludeSemantics: true,
      label: l10n.dashboardCategorySemantics(name, percent, amount),
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border(top: _hairline(context))),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              spacing: Space.sm,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryIcon(spend.slug),
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        Row(
                          spacing: Space.xs,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall,
                              ),
                            ),
                            Text(
                              amount,
                              style: TextStyle(
                                fontFamily: FontFamilies.mono,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                height: 20 / 14,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        _Bar(fraction: fraction),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    l10n.dashboardCategoryPercent(percent),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    softWrap: false,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction});

  final double fraction;

  static const _height = 8.0;
  static const _radius = BorderRadius.all(Radius.circular(_height / 2));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: _radius,
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: _radius,
          ),
        ),
      ),
    );
  }
}

class _OtherRow extends StatelessWidget {
  const _OtherRow({required this.amount, required this.total});

  final Cop amount;
  final Cop total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
    final percent = sharePercent(amount, total);
    final formatted = formatCop(amount);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l10n.dashboardOtherSemantics(percent, formatted),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: _hairline(context))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 10, 0, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.dashboardOtherCategories, style: style),
              ),
              Text(
                l10n.dashboardOtherAmount(formatted, percent),
                style: style?.copyWith(fontFamily: FontFamilies.mono),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
