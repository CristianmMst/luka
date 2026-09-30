import 'package:flutter/material.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/tokens/spacing.dart';

/// Aviso de un cambio que el servidor rechazó (diseño "Estados"): el
/// usuario lo reintenta o lo deja como lo tiene el servidor.
class RejectedBanner extends StatelessWidget {
  const RejectedBanner({
    required this.name,
    required this.onRetry,
    required this.onDiscard,
    super.key,
  });

  /// Comercio (o nota) del movimiento afectado.
  final String name;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = scheme.onErrorContainer;

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: Radii.noticeAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 22,
                    color: foreground,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        l10n.rejectedTitle,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                      Text(
                        l10n.rejectedBody(name),
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: Space.xs,
              children: [
                TextButton(
                  onPressed: onDiscard,
                  style: TextButton.styleFrom(foregroundColor: foreground),
                  child: Text(l10n.rejectedDiscard),
                ),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(l10n.rejectedRetry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
