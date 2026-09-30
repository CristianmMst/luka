import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/widgets/brand_mark.dart';
import 'package:luka/core/widgets/inline_notice.dart';
import 'package:luka/features/capture/application/capture_flusher.dart';
import 'package:luka/features/onboarding/domain/onboarding_step.dart';
import 'package:luka/features/onboarding/presentation/onboarding_navigation.dart';
import 'package:luka/features/onboarding/presentation/widgets/onboarding_parts.dart';

/// "Registra tus pagos con Apple Pay" (F4.3b, diseño A "Guía paso a paso",
/// spec 006 §3.3, spec 008 §3.1): iPhone no deja leer notificaciones, así
/// que la guía explica cómo crear la automatización "Transacción" de Atajos
/// que llama a la App Intent. Es un paso del onboarding en iOS y, con
/// [inOnboarding] en `false`, la misma guía desde Ajustes.
class ApplePayOnboardingPage extends ConsumerStatefulWidget {
  const ApplePayOnboardingPage({this.inOnboarding = true, super.key});

  final bool inOnboarding;

  @override
  ConsumerState<ApplePayOnboardingPage> createState() =>
      _ApplePayOnboardingPageState();
}

class _ApplePayOnboardingPageState
    extends ConsumerState<ApplePayOnboardingPage> {
  bool _openFailed = false;

  Future<void> _openShortcuts() async {
    try {
      await ref.read(notificationSourceProvider).openPermissionSettings();
      if (mounted && _openFailed) setState(() => _openFailed = false);
    } on PlatformException {
      if (mounted) setState(() => _openFailed = true);
    }
  }

  void _next() {
    if (widget.inOnboarding) {
      unawaited(advanceOnboarding(context, ref, OnboardingStep.applePay));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final steps = [l10n.applePayStep1, l10n.applePayStep2, l10n.applePayStep3];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // El hero es oscuro en ambos temas: íconos de estado claros.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(inOnboarding: widget.inOnboarding, onBack: _next),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.screen,
                          Space.lg,
                          Space.screen,
                          Space.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: Space.md - 2,
                          children: [
                            for (final (i, text) in steps.indexed)
                              _StepRow(number: i + 1, text: text),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: brand.card,
                                borderRadius: Radii.noticeAll,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Space.md - 2,
                                  vertical: Space.sm,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: Space.xs,
                                  children: [
                                    Text(
                                      l10n.applePayCardTip,
                                      style: textTheme.bodySmall,
                                    ),
                                    Text(
                                      l10n.applePayQueueNote,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (_openFailed)
                              InlineNotice(
                                message: l10n.applePayOpenShortcutsError,
                                tone: NoticeTone.error,
                              ),
                            FilledButton.icon(
                              onPressed: () => unawaited(_openShortcuts()),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 20,
                              ),
                              label: Text(l10n.applePayOpenShortcuts),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                              ),
                            ),
                            if (widget.inOnboarding)
                              TextButton(
                                onPressed: _next,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size.fromHeight(
                                    minTouchTarget,
                                  ),
                                ),
                                child: Text(l10n.onboardingContinue),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero esmeralda: marca y progreso en el onboarding, o volver en Ajustes.
class _Hero extends StatelessWidget {
  const _Hero({required this.inOnboarding, required this.onBack});

  final bool inOnboarding;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final soft = brand.onHero.withValues(alpha: 0.85);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.hero,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(Radii.hero),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.md,
            Space.screen,
            Space.xl - 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Space.sm,
            children: [
              Row(
                children: [
                  if (inOnboarding) ...[
                    BrandMark(gemColor: brand.gem, textColor: brand.onHero),
                    const Spacer(),
                    const OnboardingDots(
                      step: OnboardingStep.applePay,
                      onHero: true,
                    ),
                  ] else
                    IconButton(
                      onPressed: onBack,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      color: brand.onHero,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                ],
              ),
              const SizedBox(height: Space.xs),
              Semantics(
                header: true,
                child: Text(
                  l10n.applePayTitle,
                  style: textTheme.displaySmall?.copyWith(color: brand.onHero),
                ),
              ),
              Text(
                l10n.applePayBody,
                style: textTheme.bodyMedium?.copyWith(color: soft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un paso numerado de la guía.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: l10n.applePayStepSemantics(number, text),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.sm,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: textTheme.titleSmall?.copyWith(color: scheme.onPrimary),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(text, style: textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
