import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/widgets/settings_group.dart';
import 'package:luka/features/recurring/application/recurring_actions.dart';

/// Fila "Gastos fijos" de Ajustes (spec 008 §3.7): abre `/gastos-fijos`.
class RecurringSettingsTile extends ConsumerWidget {
  const RecurringSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final expenses = ref.watch(recurringExpensesProvider).value ?? const [];
    final active = expenses.where((e) => e.active).length;

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.recurring),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md - 2,
            Space.sm,
            Space.sm,
            Space.sm,
          ),
          child: Row(
            spacing: Space.sm,
            children: [
              const ExcludeSemantics(
                child: SettingsIcon(Icons.event_repeat_rounded),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      l10n.settingsRecurringTitle,
                      style: textTheme.titleSmall,
                    ),
                    Text(
                      l10n.settingsRecurringSubtitle(active),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
