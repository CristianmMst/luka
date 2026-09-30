import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/dashboard/presentation/widgets/dashboard_format.dart';
import 'package:luka/features/push/presentation/push_permission.dart';
import 'package:luka/features/recurring/application/recurring_actions.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/presentation/occurrence_actions.dart';
import 'package:luka/features/recurring/presentation/occurrence_row.dart';
import 'package:luka/features/recurring/presentation/recurring_form_sheet.dart';
import 'package:luka/features/recurring/presentation/recurring_format.dart';

/// `/gastos-fijos` (spec 008 §3.8): las ocurrencias del mes, tachadas las
/// pagadas, con acciones por fila y "Nuevo gasto fijo".
class RecurringPage extends ConsumerStatefulWidget {
  const RecurringPage({this.highlightId, super.key});

  /// Ocurrencia a resaltar (llega por el aviso push).
  final String? highlightId;

  @override
  ConsumerState<RecurringPage> createState() => _RecurringPageState();
}

class _RecurringPageState extends ConsumerState<RecurringPage> {
  late ColombiaMonth _current = ColombiaMonth.containing(
    ref.read(recurringClockProvider)(),
  );
  late final ColombiaMonth _thisMonth = _current;
  var _jumped = false;

  bool get _canGoBack => _current.isAfter(_thisMonth.previous);
  bool get _canGoForward => _current.isBefore(_thisMonth.next);

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final created = await RecurringFormSheet.show(context);
    if (created != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.recurringCreated)));
    }
  }

  /// Si el aviso apunta a otro mes de los que trae el sync, se abre ese.
  void _jumpToHighlight(List<RecurringOccurrence> items) {
    if (_jumped || widget.highlightId == null) return;
    _jumped = true;
    if (items.any((o) => o.id == widget.highlightId)) return;
    for (final month in [_thisMonth.previous, _thisMonth.next]) {
      final other = ref.read(recurringOccurrencesProvider(month)).value;
      if (other != null && other.any((o) => o.id == widget.highlightId)) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _current = month),
        );
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final occurrences = ref.watch(recurringOccurrencesProvider(_current));
    final expenses = ref.watch(recurringExpensesProvider).value ?? const [];
    final items = occurrences.value ?? const <RecurringOccurrence>[];
    if (occurrences.hasValue) _jumpToHighlight(items);
    final counted = items.where((o) => o.status != OccurrenceStatus.skipped);
    final total = counted.fold(0, (sum, o) => sum + o.expectedAmount.cents);
    final paid = counted
        .where((o) => o.status == OccurrenceStatus.paid)
        .fold(0, (sum, o) => sum + o.expectedAmount.cents);

    Widget body() {
      if (!occurrences.hasValue && occurrences.hasError) {
        return Column(
          spacing: Space.sm,
          children: [
            Text(l10n.recurringLoadError),
            OutlinedButton(
              onPressed: () =>
                  ref.invalidate(recurringOccurrencesProvider(_current)),
              child: Text(l10n.recurringRetry),
            ),
          ],
        );
      }
      if (!occurrences.hasValue) {
        return const Center(child: CircularProgressIndicator());
      }
      if (expenses.isEmpty) {
        return _EmptyState(onCreate: () => unawaited(_create()));
      }
      if (items.isEmpty) {
        return Text(
          l10n.recurringMonthEmpty(monthName(_current)),
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        );
      }
      return DecoratedBox(
        decoration: BoxDecoration(
          color: context.lukaColors.card,
          borderRadius: Radii.noticeAll,
        ),
        child: ClipRRect(
          borderRadius: Radii.noticeAll,
          child: Column(
            children: [
              for (final (i, occurrence) in items.indexed) ...[
                if (i > 0) Divider(height: 1, color: scheme.surfaceContainer),
                OccurrenceRow(
                  occurrence: occurrence,
                  highlighted: occurrence.id == widget.highlightId,
                  onTap: () => unawaited(
                    showOccurrenceActions(context, ref, occurrence),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.xs,
            Space.screen,
            Space.xl,
          ),
          children: [
            const PushOffBanner(),
            Row(
              children: [
                IconButton(
                  tooltip: l10n.recurringPrevMonth,
                  onPressed: _canGoBack
                      ? () => setState(() => _current = _current.previous)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    monthHeading(_current),
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.recurringNextMonth,
                  onPressed: _canGoForward
                      ? () => setState(() => _current = _current.next)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            if (items.isNotEmpty) ...[
              Text(
                l10n.recurringMonthSummary(
                  formatCop(Cop(paid)),
                  formatCop(Cop(total)),
                ),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.sm),
            ],
            body(),
            if (expenses.isNotEmpty) ...[
              const SizedBox(height: Space.sm),
              OutlinedButton.icon(
                onPressed: () => unawaited(_create()),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.recurringNew),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: BorderSide(color: scheme.primary),
                ),
              ),
              const SizedBox(height: Space.lg),
              for (final expense in expenses.where((e) => !e.active))
                ListTile(
                  title: Text(expense.name),
                  subtitle: Text(expectedAmountText(expense.expectedAmount)),
                  trailing: Chip(label: Text(l10n.recurringPausedBadge)),
                  onTap: () => unawaited(
                    RecurringFormSheet.show(context, existing: expense),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.lukaColors.card,
        borderRadius: Radii.cardAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.sm,
          children: [
            Icon(Icons.event_repeat_rounded, size: 40, color: scheme.primary),
            Text(
              l10n.recurringEmptyTitle,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              l10n.recurringEmptyBody,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.recurringNew),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
