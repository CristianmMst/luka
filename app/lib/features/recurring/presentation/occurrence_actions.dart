import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/recurring/application/recurring_actions.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/recurring_ports.dart';
import 'package:luka/features/recurring/presentation/recurring_form_sheet.dart';
import 'package:luka/features/recurring/presentation/recurring_format.dart';
import 'package:luka/features/transactions/presentation/widgets/sheet_frame.dart';

/// Lo que se puede hacer con una ocurrencia según su estado (spec 008 §3.8).
enum OccurrenceAction { markPaid, pick, skip, undo, viewTransaction, edit }

List<OccurrenceAction> actionsFor(
  OccurrenceState state, {
  required bool hasTx,
}) => switch (state) {
  OccurrenceState.upcoming ||
  OccurrenceState.late ||
  OccurrenceState.undetected => const [
    OccurrenceAction.markPaid,
    OccurrenceAction.pick,
    OccurrenceAction.skip,
    OccurrenceAction.edit,
  ],
  OccurrenceState.paid => [
    OccurrenceAction.undo,
    if (hasTx) OccurrenceAction.viewTransaction,
    OccurrenceAction.edit,
  ],
  OccurrenceState.skipped => const [
    OccurrenceAction.undo,
    OccurrenceAction.edit,
  ],
};

/// Abre la hoja de acciones de [occurrence] y ejecuta la elegida.
Future<void> showOccurrenceActions(
  BuildContext context,
  WidgetRef ref,
  RecurringOccurrence occurrence,
) async {
  final l10n = AppLocalizations.of(context);
  final today = colombiaToday(ref.read(recurringClockProvider)());
  final state = occurrenceStateOf(occurrence, today);
  final chosen = await showLukaSheet<OccurrenceAction>(
    context,
    builder: (_) => _ActionsSheet(
      occurrence: occurrence,
      actions: actionsFor(state, hasTx: occurrence.transactionId != null),
    ),
  );
  if (chosen == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(recurringActionsProvider);

  Future<void> run(Future<Object?> Function() call, String done) async {
    try {
      await call();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on RecurringFailure catch (failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(recurringFailureMessage(l10n, failure))),
      );
    }
  }

  switch (chosen) {
    case OccurrenceAction.markPaid:
      await run(
        () => actions.markPaid(occurrence.id),
        l10n.recurringMarkedPaid,
      );
    case OccurrenceAction.pick:
      final picked = await PickTransactionSheet.show(context, occurrence);
      if (picked == null) return;
      await run(
        () => actions.markPaid(occurrence.id, transactionId: picked.id),
        l10n.recurringMarkedPaid,
      );
    case OccurrenceAction.skip:
      await run(() => actions.skip(occurrence.id), l10n.recurringSkippedDone);
    case OccurrenceAction.undo:
      await run(() => actions.unmark(occurrence.id), l10n.recurringUndone);
    case OccurrenceAction.viewTransaction:
      final id = occurrence.transactionId;
      if (id != null && context.mounted) {
        unawaited(context.push('${Routes.transactions}/$id'));
      }
    case OccurrenceAction.edit:
      final expenses = ref.read(recurringExpensesProvider).value ?? const [];
      final expense = expenses
          .where((e) => e.id == occurrence.expenseId)
          .firstOrNull;
      if (expense != null && context.mounted) {
        await RecurringFormSheet.show(context, existing: expense);
      }
  }
}

class _ActionsSheet extends StatelessWidget {
  const _ActionsSheet({required this.occurrence, required this.actions});

  final RecurringOccurrence occurrence;
  final List<OccurrenceAction> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    (IconData, String) describe(OccurrenceAction action) => switch (action) {
      OccurrenceAction.markPaid => (
        Icons.check_circle_outline_rounded,
        l10n.recurringActionMarkPaid,
      ),
      OccurrenceAction.pick => (
        Icons.receipt_long_outlined,
        l10n.recurringActionPick,
      ),
      OccurrenceAction.skip => (
        Icons.skip_next_outlined,
        l10n.recurringActionSkip,
      ),
      OccurrenceAction.undo => (Icons.undo_rounded, l10n.recurringActionUndo),
      OccurrenceAction.viewTransaction => (
        Icons.open_in_new_rounded,
        l10n.recurringActionViewTransaction,
      ),
      OccurrenceAction.edit => (
        Icons.edit_outlined,
        l10n.recurringActionEdit,
      ),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, 10, Space.lg, Space.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.xxs,
          children: [
            const SheetHandle(),
            const SizedBox(height: Space.xs),
            Semantics(
              header: true,
              child: Text(
                occurrence.name,
                style: textTheme.headlineSmall?.copyWith(fontSize: 22),
              ),
            ),
            const SizedBox(height: Space.xs),
            for (final action in actions)
              ListTile(
                minTileHeight: 52,
                leading: Icon(describe(action).$1),
                title: Text(describe(action).$2),
                shape: const RoundedRectangleBorder(
                  borderRadius: Radii.rowAll,
                ),
                onTap: () => Navigator.of(context).pop(action),
              ),
          ],
        ),
      ),
    );
  }
}

/// "¿Con qué movimiento lo pagaste?": los gastos locales de la ventana,
/// los de monto más cercano primero.
class PickTransactionSheet extends ConsumerWidget {
  const PickTransactionSheet({required this.occurrence, super.key});

  final RecurringOccurrence occurrence;

  static Future<PaymentCandidate?> show(
    BuildContext context,
    RecurringOccurrence occurrence,
  ) => showLukaSheet<PaymentCandidate>(
    context,
    builder: (_) => PickTransactionSheet(occurrence: occurrence),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const window = Duration(days: detectionWindowDays);

    return FutureBuilder<List<PaymentCandidate>>(
      future: ref
          .read(recurringStoreProvider)
          .candidates(occurrence.dueDate, occurrence.expectedAmount),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <PaymentCandidate>[];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.lg, 10, Space.lg, Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Space.xs,
            children: [
              const SheetHandle(),
              Semantics(
                header: true,
                child: Text(
                  l10n.recurringPickTitle,
                  style: textTheme.headlineSmall?.copyWith(fontSize: 22),
                ),
              ),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (items.isEmpty)
                Text(
                  l10n.recurringPickEmpty(
                    shortDay(occurrence.dueDate.subtract(window)),
                    shortDay(occurrence.dueDate.add(window)),
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.lukaColors.tile,
                    borderRadius: Radii.noticeAll,
                  ),
                  child: Column(
                    children: [
                      for (final item in items)
                        ListTile(
                          minTileHeight: 56,
                          title: Text(item.merchant ?? '—'),
                          subtitle: Text(
                            shortDay(toColombiaLocal(item.occurredAt)),
                          ),
                          trailing: Text(
                            formatCop(item.amount),
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(item),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
