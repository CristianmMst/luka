import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Destino tras el login hasta que llegue el dashboard (F4).
class DashboardPlaceholderPage extends ConsumerWidget {
  const DashboardPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final user = switch (ref.watch(authControllerProvider)) {
      AsyncData(value: Authenticated(:final user)) => user,
      _ => null,
    };
    final sync = ref.watch(syncCoordinatorProvider);
    final syncLine = switch (sync) {
      SyncStatus(running: true) => l10n.syncStatusRunning,
      SyncStatus(offline: true) => l10n.syncStatusOffline,
      SyncStatus(:final rejected) when rejected > 0 => l10n.syncStatusRejected(
        rejected,
      ),
      SyncStatus(lastSyncedAt: null) => l10n.syncStatusNever,
      SyncStatus(:final pending) => l10n.syncStatusSynced(pending),
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Space.sm,
            children: [
              const SizedBox(height: Space.xl),
              Text(
                l10n.homeGreeting(user?.greetingName ?? ''),
                style: textTheme.headlineLarge,
              ),
              if (user != null)
                Text(
                  user.email,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: Space.md),
              Text(l10n.homePlaceholderBody, style: textTheme.bodyLarge),
              Text(
                syncLine,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
