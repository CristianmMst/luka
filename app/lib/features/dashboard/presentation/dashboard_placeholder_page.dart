import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
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
              const Spacer(),
              OutlinedButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: Text(l10n.homeSignOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
