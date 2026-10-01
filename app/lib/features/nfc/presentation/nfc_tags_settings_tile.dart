import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/widgets/settings_group.dart';

/// Fila "Tags NFC" de Ajustes (F4.5b, solo Android): abre las plantillas.
class NfcTagsSettingsTile extends StatelessWidget {
  const NfcTagsSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.settingsNfcTags),
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
                child: SettingsIcon(Icons.nfc_rounded),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      l10n.settingsNfcTitle,
                      style: textTheme.titleSmall,
                    ),
                    Text(
                      l10n.settingsNfcSubtitle,
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
