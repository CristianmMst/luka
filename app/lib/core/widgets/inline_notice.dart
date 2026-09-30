import 'package:flutter/material.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';

enum NoticeTone { error, warning, info }

/// Aviso en línea sobre el botón principal de una pantalla (error, espera o
/// información): login, Gmail.
class InlineNotice extends StatelessWidget {
  const InlineNotice({
    required this.message,
    required this.tone,
    this.icon,
    super.key,
  });

  final String message;
  final NoticeTone tone;

  /// Por defecto, el ícono del tono.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final (background, foreground, toneIcon) = switch (tone) {
      NoticeTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline_rounded,
      ),
      NoticeTone.warning => (
        brand.warningContainer,
        brand.onWarningContainer,
        Icons.timer_outlined,
      ),
      NoticeTone.info => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.lock_outline_rounded,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: Radii.noticeAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md - 2,
            vertical: Space.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Space.sm - 2,
            children: [
              Icon(icon ?? toneIcon, size: 20, color: foreground),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
