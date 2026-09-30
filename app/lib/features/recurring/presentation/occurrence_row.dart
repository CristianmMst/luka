import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/recurring/application/recurring_actions.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/presentation/recurring_format.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/category_option.dart';

/// Fila de una ocurrencia (spec 008 §3.8): las pagadas van tachadas, con
/// check y "Pagado el 22 oct"; las pendientes vencidas, en ámbar.
class OccurrenceRow extends ConsumerWidget {
  const OccurrenceRow({
    required this.occurrence,
    this.onTap,
    this.highlighted = false,
    super.key,
  });

  final RecurringOccurrence occurrence;
  final VoidCallback? onTap;

  /// Resaltada al abrir desde el aviso push.
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final today = colombiaToday(ref.watch(recurringClockProvider)());
    final state = occurrenceStateOf(occurrence, today);
    final categories =
        ref.watch(transactionCategoriesProvider).value ??
        const <CategoryOption>[];
    final category = categories
        .where((c) => c.id == occurrence.categoryId)
        .firstOrNull;
    final paid = state == OccurrenceState.paid;
    final dimmed = paid || state == OccurrenceState.skipped;
    final warning =
        state == OccurrenceState.late || state == OccurrenceState.undetected;
    final stateLine = occurrenceStateLine(l10n, occurrence, today);
    final amount = expectedAmountText(occurrence.expectedAmount);
    // Tachado en `onSurfaceVariant`: conserva el contraste AA (spec 008 §3.8).
    const struck = TextDecoration.lineThrough;

    return Material(
      color: highlighted ? scheme.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: onTap != null,
          label: l10n.recurringRowSemantics(occurrence.name, amount, stateLine),
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: Space.xs,
              ),
              child: Row(
                spacing: Space.sm,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: paid ? scheme.primary : brand.tile,
                    ),
                    child: Icon(
                      paid
                          ? Icons.check_rounded
                          : recurringCategoryIcon(category),
                      size: 20,
                      color: paid ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          occurrence.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: paid ? struck : null,
                            color: dimmed ? scheme.onSurfaceVariant : null,
                          ),
                        ),
                        Text(
                          stateLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: warning
                                ? brand.onWarningContainer
                                : scheme.onSurfaceVariant,
                            fontWeight: warning ? FontWeight.w600 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amount,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: paid ? struck : null,
                      color: dimmed ? scheme.onSurfaceVariant : null,
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
