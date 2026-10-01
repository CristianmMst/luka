import 'package:flutter/material.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';

/// Divulgación prominente del acceso a notificaciones (spec 010 §2, política
/// de Google Play): qué se lee y qué se ignora, antes de abrir el ajuste del
/// sistema. `true` si el usuario sigue al ajuste.
class NotificationDisclosureSheet extends StatelessWidget {
  const NotificationDisclosureSheet({super.key});

  static Future<bool> show(BuildContext context) async =>
      await showModalBottomSheet<bool>(
        context: context,
        // Sobre la barra de navegación: se abre desde Ajustes y desde
        // Inicio, dentro del shell.
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: context.lukaColors.card,
        builder: (_) => const NotificationDisclosureSheet(),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget point(IconData icon, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Space.sm,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 20, color: scheme.primary)),
        Expanded(child: Text(text, style: textTheme.bodyMedium)),
      ],
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          0,
          Space.lg,
          Space.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.md,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.notificationDisclosureTitle,
                style: textTheme.headlineSmall,
              ),
            ),
            Text(l10n.notificationDisclosureBody, style: textTheme.bodyLarge),
            point(
              Icons.account_balance_outlined,
              l10n.notificationDisclosureReads,
            ),
            point(Icons.block_outlined, l10n.notificationDisclosureIgnores),
            point(Icons.toggle_off_outlined, l10n.notificationDisclosureRevoke),
            const SizedBox(height: Space.xs),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.notificationDisclosureContinue),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.notificationDisclosureCancel),
            ),
          ],
        ),
      ),
    );
  }
}
