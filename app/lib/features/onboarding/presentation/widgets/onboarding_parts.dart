import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/onboarding/application/onboarding_gate.dart';
import 'package:luka/features/onboarding/domain/onboarding_step.dart';

/// Progreso del onboarding (diseño B "Puntos"): un punto por paso de esta
/// plataforma y el actual más largo. Se lee como "Paso n de m".
class OnboardingDots extends ConsumerWidget {
  const OnboardingDots({required this.step, this.onHero = false, super.key});

  final OnboardingStep step;

  /// Sobre el hero oscuro (colores claros).
  final bool onHero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final onHeroColor = context.lukaColors.onHero;
    final steps = ref.watch(onboardingFlowProvider).steps;
    final current = steps.indexOf(step);
    final (active, done, todo) = onHero
        ? (
            onHeroColor,
            onHeroColor.withValues(alpha: 0.6),
            onHeroColor.withValues(alpha: 0.3),
          )
        : (scheme.primary, scheme.outline, scheme.outlineVariant);

    return Semantics(
      label: l10n.onboardingProgress(current + 1, steps.length),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Space.xs,
        children: [
          for (var i = 0; i < steps.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == current
                    ? active
                    : i < current
                    ? done
                    : todo,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

/// Círculo de 36 dp con un ícono.
class OnboardingBubble extends StatelessWidget {
  const OnboardingBubble({
    required this.icon,
    required this.color,
    required this.iconColor,
    super.key,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }
}

/// "Lee" / "Nunca lee": una fila con su ícono y la explicación.
class OnboardingScopeRow extends StatelessWidget {
  const OnboardingScopeRow({
    required this.icon,
    required this.iconColor,
    required this.bubbleColor,
    required this.label,
    required this.text,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color bubbleColor;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.sm,
        children: [
          ExcludeSemantics(
            child: OnboardingBubble(
              icon: icon,
              color: bubbleColor,
              iconColor: iconColor,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(label, style: textTheme.titleSmall),
                Text(
                  text,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
