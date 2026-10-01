import 'package:flutter/material.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/dashboard/domain/monthly_summary.dart';
import 'package:luka/features/dashboard/presentation/widgets/dashboard_format.dart';
import 'package:luka/features/transactions/presentation/widgets/category_icon.dart';

/// "En qué se fue" (diseño Q): una franja con la parte de cada categoría
/// del gasto y, debajo, el top 5 más "Otras categorías" en tarjetas de dos
/// columnas. Tocar una tarjeta llama a [onOpen] con su `categoryId` (las
/// que no tienen id no se pueden abrir, y ninguna si [onOpen] es null).
class TopCategoriesCard extends StatelessWidget {
  const TopCategoriesCard({
    required this.summary,
    required this.onOpen,
    super.key,
  });

  final MonthlySummary summary;
  final ValueChanged<String>? onOpen;

  /// Rampa tomate por puesto: de más a menos gasto. Cada tono difiere en
  /// claridad, no solo en matiz; la tinta sobre el primero es blanca.
  static const List<(Color, Color)> ramp = [
    (Color(0xFFC8331F), Colors.white),
    (Color(0xFFE9705A), Color(0xFF2A1210)),
    (Color(0xFFF5A592), Color(0xFF2A1210)),
    (Color(0xFFFBD5CB), Color(0xFF2A1210)),
    (Color(0xFFFDE9E3), Color(0xFF2A1210)),
  ];
  static const (Color, Color) otherTone = (
    Color(0xFFEDE6E4),
    Color(0xFF2A1210),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = summary.totals.expenses;
    final top = summary.topCategories;
    final other = summary.otherAmount;

    final tiles = <_Tile>[
      for (final (i, spend) in top.indexed)
        _Tile(
          name: spendName(l10n, spend),
          icon: categoryIcon(spend.slug),
          amount: spend.amount,
          percent: sharePercent(spend.amount, total),
          tone: ramp[i.clamp(0, ramp.length - 1)],
          other: false,
          onTap: switch ((spend.categoryId, onOpen)) {
            (final id?, final open?) => () => open(id),
            _ => null,
          },
        ),
      if (other.cents > 0)
        _Tile(
          name: l10n.dashboardOtherCategories,
          icon: Icons.more_horiz_rounded,
          amount: other,
          percent: sharePercent(other, total),
          tone: otherTone,
          other: true,
          onTap: null,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.dashboardTopTitle,
                  style: textTheme.headlineSmall?.copyWith(letterSpacing: -0.5),
                ),
              ),
            ),
            Text(
              l10n.dashboardTopSubtitle,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (tiles.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: Text(
              l10n.dashboardNoExpenses(monthName(summary.month)),
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          const SizedBox(height: 14),
          ExcludeSemantics(
            child: SizedBox(
              height: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 3,
                children: [
                  for (final tile in tiles)
                    Expanded(
                      // Partes por mil del gasto; al menos 1 para que se vea.
                      flex: total.cents <= 0
                          ? 1
                          : (tile.amount.cents * 1000 ~/ total.cents).clamp(
                              1,
                              1000,
                            ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tile.tone.$1,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < tiles.length; i += 2)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    Expanded(child: tiles[i]),
                    Expanded(
                      child: i + 1 < tiles.length
                          ? tiles[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.name,
    required this.icon,
    required this.amount,
    required this.percent,
    required this.tone,
    required this.other,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final Cop amount;
  final int percent;
  final (Color, Color) tone;
  final bool other;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formatted = formatCop(amount);
    final border = BorderRadius.circular(16);

    return Semantics(
      button: onTap != null,
      excludeSemantics: true,
      label: other
          ? l10n.dashboardOtherSemantics(percent, formatted)
          : l10n.dashboardCategorySemantics(name, percent, formatted),
      onTap: onTap,
      child: Material(
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: border,
          side: BorderSide(color: context.lukaColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Row(
                spacing: 10,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tone.$1,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 18, color: tone.$2),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 1,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            Text(
                              formatted,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            Text(
                              l10n.dashboardCategoryPercent(percent),
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
