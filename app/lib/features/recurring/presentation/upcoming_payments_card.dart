import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/recurring/application/recurring_actions.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/presentation/occurrence_actions.dart';
import 'package:luka/features/recurring/presentation/occurrence_row.dart';
import 'package:luka/features/recurring/presentation/recurring_form_sheet.dart';

/// Tarjeta "Próximos pagos" del Inicio (spec 008 §3.2): hasta 5
/// ocurrencias del mes, tachadas las pagadas. Sin gastos fijos, invita a
/// registrar uno. No suma en el balance (AC-12.8).
class UpcomingPaymentsCard extends ConsumerWidget {
  const UpcomingPaymentsCard({required this.month, super.key});

  final ColombiaMonth month;

  static const _maxRows = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final expenses = ref.watch(recurringExpensesProvider).value;
    final items =
        ref.watch(recurringOccurrencesProvider(month)).value ??
        const <RecurringOccurrence>[];
    if (expenses == null) return const SizedBox.shrink();

    if (expenses.isEmpty) {
      return Material(
        color: context.lukaColors.card,
        borderRadius: Radii.cardAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => unawaited(RecurringFormSheet.show(context)),
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Row(
              spacing: Space.sm,
              children: [
                Icon(Icons.event_repeat_rounded, color: scheme.primary),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        l10n.recurringUpcomingInviteTitle,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.recurringUpcomingInviteBody,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.recurringUpcomingInviteAction,
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (items.isEmpty) return const SizedBox.shrink();

    final counted = items
        .where((o) => o.status != OccurrenceStatus.skipped)
        .toList();
    final paid = counted.where((o) => o.status == OccurrenceStatus.paid).length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.lukaColors.card,
        borderRadius: Radii.cardAll,
      ),
      child: ClipRRect(
        borderRadius: Radii.cardAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.md,
                Space.xs,
                Space.xxs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        '${l10n.recurringUpcomingTitle} · '
                        '${l10n.recurringUpcomingCount(paid, counted.length)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => unawaited(context.push(Routes.recurring)),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(minTouchTarget, minTouchTarget),
                    ),
                    child: Text(l10n.recurringUpcomingSeeAll),
                  ),
                ],
              ),
            ),
            for (final occurrence in items.take(_maxRows))
              OccurrenceRow(
                occurrence: occurrence,
                onTap: () => unawaited(
                  showOccurrenceActions(context, ref, occurrence),
                ),
              ),
            const SizedBox(height: Space.xs),
          ],
        ),
      ),
    );
  }
}
