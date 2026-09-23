import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

/// "Sin conexión · ves tus datos guardados" (diseño "Estados").
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: Radii.noticeAll,
        ),
        child: Row(
          spacing: 10,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.wifi_off_rounded,
                size: 20,
                color: scheme.onSurface,
              ),
            ),
            Expanded(
              child: Text(
                l10n.offlineBanner,
                style: textTheme.titleSmall?.copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
