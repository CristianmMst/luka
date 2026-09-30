import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/theme/tokens/type_tokens.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/domain/rejected_change.dart';
import 'package:luka/features/sync/presentation/sync_format.dart';
import 'package:luka/features/transactions/presentation/widgets/sheet_frame.dart';

/// Hoja "Sincronización" de Ajustes (diseño B "Hoja compacta", F4.8b,
/// spec 008 §5): cuándo fue la última, "Sincronizar ahora" y los cambios que
/// el servidor rechazó, cada uno con reintentar y descartar.
class SyncSheet extends ConsumerWidget {
  const SyncSheet({this.now, super.key});

  /// Reloj para "hace …"; en tests se fija.
  final DateTime Function()? now;

  static Future<void> show(BuildContext context) => showLukaSheet<void>(
    context,
    builder: (_) => const SyncSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sync = ref.watch(syncCoordinatorProvider);
    final rejected = ref.watch(rejectedChangesProvider).value ?? const [];
    final last = sync.lastSyncedAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.lg, 10, Space.lg, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.sm,
        children: [
          const SheetHandle(),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.syncSheetTitle,
                    style: textTheme.headlineSmall?.copyWith(fontSize: 22),
                  ),
                ),
              ),
              Text(
                last == null
                    ? l10n.syncStatusNever
                    : syncAgo(l10n, last, (now ?? DateTime.now)()),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: sync.running
                ? null
                : () => unawaited(
                    ref.read(syncCoordinatorProvider.notifier).sync(),
                  ),
            icon: sync.running
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            label: Text(
              sync.running ? l10n.syncSheetRunning : l10n.syncSheetNow,
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          if (rejected.isEmpty)
            Text(
              sync.offline ? l10n.syncStatusOffline : l10n.syncSheetAllSent,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else ...[
            Semantics(
              header: true,
              child: Text(
                l10n.syncSheetRejectedHeader(rejected.length),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.lukaColors.expense,
                ),
              ),
            ),
            for (final change in rejected) _RejectedRow(change: change),
            Text(
              l10n.syncSheetHelp,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RejectedRow extends ConsumerWidget {
  const _RejectedRow({required this.change});

  // 48 dp de área táctil (el outlined de Material 3 mide 40).
  static final ButtonStyle _iconStyle = IconButton.styleFrom(
    minimumSize: const Size.square(minTouchTarget),
  );

  final RejectedChange change;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brand = context.lukaColors;
    final coordinator = ref.read(syncCoordinatorProvider.notifier);
    final title = rejectedOpLabel(l10n, change.op);
    final amount = change.amountCents;
    final merchant = change.merchant?.trim();
    final id = change.op.targetId;
    final credit = change.direction == 'credit';
    final amountText = amount == null
        ? null
        : formatCop(
            Cop(amount),
            sign: credit ? AmountSign.positive : AmountSign.negative,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.surfaceContainer)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Row(
          spacing: Space.xs,
          children: [
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: merchant == null || merchant.isEmpty
                                ? title
                                : '$title · $merchant',
                          ),
                          if (amountText != null)
                            TextSpan(
                              text: '  $amountText',
                              style: amountTextStyle.copyWith(
                                color: credit ? brand.income : brand.expense,
                              ),
                            ),
                        ],
                      ),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      rejectedReasonLabel(l10n, change.reason),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton.outlined(
              onPressed: () => unawaited(coordinator.retryRejected(id)),
              tooltip: l10n.rejectedRetrySemantics(title),
              style: _iconStyle,
              icon: Icon(Icons.refresh_rounded, color: scheme.primary),
            ),
            IconButton.outlined(
              onPressed: () => unawaited(coordinator.discardRejected(id)),
              tooltip: l10n.rejectedDiscardSemantics(title),
              style: _iconStyle,
              icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
