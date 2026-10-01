import 'package:flutter/material.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/review/domain/review_item.dart';
import 'package:luka/features/review/presentation/widgets/review_format.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// Tarjeta de un mensaje en revisión (diseño AA "Bandeja"): canal, banco,
/// fecha de recepción, motivo y un extracto con los montos resaltados. Lleva
/// sus acciones: "Usar $X" abre el detalle con ese monto puesto (o
/// "Registrar a mano" si no hay ninguno) y "Descartar".
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    required this.item,
    required this.onOpen,
    required this.onDiscard,
    super.key,
  });

  final ReviewItem item;

  /// Abre el detalle; con un monto, ya puesto en el formulario.
  final ValueChanged<Cop?> onOpen;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final source = reviewSource(l10n, item);
    final date = shortDateTime(item.receivedAt);
    final reason = reasonLabel(l10n, item.reason);
    final text = item.text;
    final amount = suggestedAmount(item);

    return Material(
      color: brand.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: brand.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            container: true,
            excludeSemantics: true,
            label: [
              l10n.reviewCardSemantics(source, date, reason),
              if (text != null) reviewPreview(text),
            ].join('. '),
            onTap: () => onOpen(null),
            child: InkWell(
              onTap: () => onOpen(null),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
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
                        style: textTheme.bodyMedium?.copyWith(height: 1.55),
                      )
                    else
                      Text(
                        l10n.reviewNoText,
                        style: textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, Space.sm, 6, 14),
            // Si no caben juntas (letra grande), "Descartar" baja.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: Space.xxs,
              children: [
                if (amount != null)
                  FilledButton.icon(
                    onPressed: () => onOpen(amount),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(l10n.reviewUseAmount(formatCop(amount))),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, minTouchTarget),
                      shape: const StadiumBorder(),
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: () => onOpen(null),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, minTouchTarget),
                      shape: const StadiumBorder(),
                      side: BorderSide(color: brand.hairline),
                    ),
                    child: Text(l10n.reviewRegisterByHand),
                  ),
                TextButton(
                  onPressed: onDiscard,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, minTouchTarget),
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                  child: Text(l10n.reviewDiscard),
                ),
              ],
            ),
          ),
        ],
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
            borderRadius: BorderRadius.circular(13),
            color: brand.neutralChip,
          ),
          child: Icon(
            reviewChannelIcon(item.channel),
            size: 20,
            color: scheme.primary,
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
                  borderRadius: Radii.pillAll,
                  color: brand.neutralChip,
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
