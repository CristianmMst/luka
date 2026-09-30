import 'package:flutter/material.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/review/domain/review_item.dart';
import 'package:luka/features/review/presentation/widgets/review_format.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// Tarjeta de un mensaje en revisión: canal, banco, fecha de recepción,
/// motivo y un extracto con los montos resaltados. Toda la tarjeta abre el
/// detalle.
class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.item, required this.onOpen, super.key});

  final ReviewItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final source = reviewSource(l10n, item);
    final date = shortDateTime(item.receivedAt);
    final reason = reasonLabel(l10n, item.reason);
    final text = item.text;

    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      label: [
        l10n.reviewCardSemantics(source, date, reason),
        if (text != null) reviewPreview(text),
      ].join('. '),
      onTap: onOpen,
      child: Material(
        color: context.lukaColors.card,
        borderRadius: Radii.cardAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Space.sm,
              children: [
                ReviewHeader(item: item),
                if (text != null)
                  Text.rich(
                    TextSpan(
                      children: highlightedSpans(
                        l10n,
                        reviewPreview(text),
                        highlightStyle(scheme),
                      ),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(height: 1.45),
                  )
                else
                  Text(
                    l10n.reviewNoText,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
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

/// Encabezado común de la tarjeta y el detalle: ícono del canal, banco (o
/// remitente), fecha y hora de recepción y el chip del motivo.
class ReviewHeader extends StatelessWidget {
  const ReviewHeader({required this.item, super.key});

  final ReviewItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Space.sm,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primaryContainer,
          ),
          child: Icon(
            reviewChannelIcon(item.channel),
            size: 20,
            color: scheme.onPrimaryContainer,
            semanticLabel: reviewChannelName(l10n, item.channel),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: Space.xs,
                children: [
                  Expanded(
                    child: Text(
                      reviewSource(l10n, item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    shortDateTime(item.receivedAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: Radii.chipAll,
                  border: Border.all(color: scheme.outlineVariant),
                  color: brand.tile,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: Space.xxs,
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 14,
                      color: scheme.onSurface,
                    ),
                    Flexible(
                      child: Text(
                        reasonLabel(l10n, item.reason),
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
