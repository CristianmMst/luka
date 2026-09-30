import 'package:flutter/material.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/theme/tokens/type_tokens.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';
import 'package:luka/features/transactions/presentation/widgets/category_icon.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// Fila de un movimiento dentro de su `DayCard` (diseño "ListaB"): ícono
/// de categoría, comercio, chip de categoría editable, monto con signo,
/// canales, hora y sello de sync.
///
/// Toda la fila abre el detalle; el chip es un botón aparte con su propia
/// área táctil de 48 dp.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    required this.tx,
    required this.onOpen,
    required this.onChangeCategory,
    super.key,
  });

  final TransactionView tx;
  final VoidCallback onOpen;
  final VoidCallback onChangeCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final muted = scheme.onSurfaceVariant;
    final isTransfer = tx.kind == TxKind.transfer;
    final channels = [
      for (final channel in channelOrder)
        if (tx.channels.contains(channel)) channel,
    ];

    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: onOpen,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: Row(
              spacing: Space.sm,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTransfer
                          ? brand.transfer.withValues(alpha: 0.16)
                          : scheme.primaryContainer,
                    ),
                    child: Icon(
                      isTransfer ? transferIcon : categoryIcon(tx.categorySlug),
                      size: 20,
                      color: isTransfer
                          ? brand.transfer
                          : scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        displayName(l10n, tx),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 20 / 15,
                        ),
                      ),
                      SizedBox(
                        height: minTouchTarget,
                        child: Row(
                          spacing: Space.xs,
                          children: [
                            Flexible(
                              child: CategoryChip(
                                label: tx.categoryName ?? l10n.txNoCategory,
                                onTap: onChangeCategory,
                              ),
                            ),
                            if (tx.sync != SyncMark.none)
                              Flexible(child: SyncMarkLabel(tx.sync)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: Space.xxs,
                  children: [
                    Semantics(
                      label: amountSemantics(l10n, tx.amount, tx.kind),
                      child: ExcludeSemantics(
                        child: Text(
                          listAmount(tx.amount, tx.kind),
                          style: amountTextStyle.copyWith(
                            fontSize: 15,
                            color: amountColor(brand, tx.kind),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: Space.xxs,
                      children: [
                        if (channels.isNotEmpty)
                          Semantics(
                            label: l10n.channelsSemantics(
                              channels
                                  .map((c) => channelName(l10n, c))
                                  .join(', '),
                            ),
                            child: ExcludeSemantics(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: Space.xxs,
                                children: [
                                  for (final channel in channels)
                                    Icon(
                                      channelIcon(channel),
                                      size: 14,
                                      color: muted,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        Text(
                          timeOfDay(tx.occurredAt),
                          style: textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip de categoría de 28 dp de alto, centrado en un área táctil de 48 dp.
class CategoryChip extends StatelessWidget {
  const CategoryChip({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      label: l10n.txChangeCategorySemantics(label),
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.chipAll,
        child: SizedBox(
          height: minTouchTarget,
          child: Center(
            widthFactor: 1,
            child: Container(
              height: 28,
              padding: const EdgeInsets.only(left: 10, right: 6),
              decoration: BoxDecoration(
                borderRadius: Radii.chipAll,
                border: Border.all(color: scheme.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 14,
                    color: scheme.onSurface,
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

/// "Por enviar" (reloj, gris) o "No enviado" (alerta, color de gasto).
class SyncMarkLabel extends StatelessWidget {
  const SyncMarkLabel(this.mark, {super.key});

  final SyncMark mark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final rejected = mark == SyncMark.rejected;
    final color = rejected
        ? context.lukaColors.expense
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Space.xxs,
      children: [
        ExcludeSemantics(
          child: Icon(
            rejected ? Icons.warning_amber_rounded : Icons.schedule_rounded,
            size: 14,
            color: color,
          ),
        ),
        Flexible(
          child: Text(
            rejected ? l10n.txSyncRejected : l10n.txSyncPending,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: rejected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
