import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:flutter/material.dart';

enum AuthNoticeTone { error, warning, info }

/// Aviso en línea sobre el botón de login (error, espera o información).
class AuthNotice extends StatelessWidget {
  const AuthNotice({
    required this.message,
    required this.tone,
    this.icon,
    super.key,
  });

  final String message;
  final AuthNoticeTone tone;

  /// Por defecto, el ícono del tono.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = context.finanziaColors;
    final (background, foreground, toneIcon) = switch (tone) {
      AuthNoticeTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline_rounded,
      ),
      AuthNoticeTone.warning => (
        brand.warningContainer,
        brand.onWarningContainer,
        Icons.timer_outlined,
      ),
      AuthNoticeTone.info => (
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
