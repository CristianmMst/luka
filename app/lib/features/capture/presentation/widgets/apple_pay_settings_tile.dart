import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/widgets/settings_group.dart';

/// Fila "Pagos con Apple Pay" de Ajustes (F4.3b, solo iOS): abre la guía
/// del Atajo, la misma del onboarding.
class ApplePaySettingsTile extends StatelessWidget {
  const ApplePaySettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.settingsApplePay),
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
                child: SettingsIcon(Icons.contactless_outlined),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      l10n.settingsApplePayTitle,
                      style: textTheme.titleSmall,
                    ),
                    Text(
                      l10n.settingsApplePaySubtitle,
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
