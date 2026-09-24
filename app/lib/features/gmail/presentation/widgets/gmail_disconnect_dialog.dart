import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

/// "¿Desconectar Gmail?": `true` confirma; cancelar o cerrar devuelve
/// `false`/`null`.
class GmailDisconnectDialog extends StatelessWidget {
  const GmailDisconnectDialog({super.key});

  static Future<bool> show(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => const GmailDisconnectDialog(),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: context.finanziaColors.card,
      shape: const RoundedRectangleBorder(borderRadius: Radii.cardAll),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 326),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.errorContainer,
                    ),
                    child: Icon(
                      Icons.link_off_rounded,
                      size: 22,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  l10n.settingsGmailDisconnectTitle,
                  style: textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    height: 1.15,
                  ),
                ),
              ),
              Text(
                l10n.settingsGmailDisconnectBody,
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Space.xs,
                  children: [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      ),
                      child: Text(l10n.settingsGmailDisconnectConfirm),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onSurface,
                      ),
                      child: Text(l10n.settingsGmailDisconnectCancel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
