import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/widgets/brand_mark.dart';
import 'package:luka/features/gmail/application/gmail_controller.dart';
import 'package:luka/features/gmail/domain/gmail_connection.dart';
import 'package:luka/features/gmail/domain/gmail_failure.dart';
import 'package:luka/features/gmail/presentation/widgets/gmail_failure_notice.dart';
import 'package:luka/features/onboarding/domain/onboarding_step.dart';
import 'package:luka/features/onboarding/presentation/onboarding_navigation.dart';
import 'package:luka/features/onboarding/presentation/widgets/onboarding_parts.dart';

/// Paso "Conecta tu Gmail" tras el login (spec 008 §3.1, AC-1.2/AC-1.3), con
/// el lenguaje del login "Veta esmeralda": hero café y titular
/// Bricolage. Conectar y "Ahora no" siguen al próximo paso del onboarding;
/// si la conexión quedó guardada pero sin captura (`error`/`revoked`), avisa
/// que se reintenta desde Ajustes. Con Gmail ya activo (deep link o estado
/// que llegó tarde) solo ofrece "Continuar".
class GmailOnboardingPage extends ConsumerWidget {
  const GmailOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(gmailControllerProvider.notifier);

    final gmail = ref.watch(gmailControllerProvider);
    // Sin estado (deep link con la red caída): el botón reintenta leerlo.
    final loadFailed = gmail.hasError && !gmail.isLoading;
    final loading = gmail.isLoading && !gmail.hasValue;
    final current = gmail.hasError ? null : gmail.value;
    final busy = current?.busy ?? false;
    final failure = loadFailed
        ? switch (gmail.error) {
            final GmailFailure f => f,
            final Object error => GmailUnexpected(
              error,
              GmailErrorCode.unknown,
            ),
            null => const GmailUnexpected(),
          }
        : current?.failure;
    final showNotice = failure != null && failure is! GmailConsentCancelled;
    final active = current?.info.status == GmailStatus.active;

    void next() =>
        unawaited(advanceOnboarding(context, ref, OnboardingStep.gmail));

    Future<void> connect() async {
      if (loadFailed) return controller.refresh();
      if (await controller.connect() && context.mounted) {
        // 200 con `error`/`revoked` (el watch falló): la conexión quedó
        // guardada pero no captura. Se avisa en vez de ir en silencio.
        final status = ref.read(gmailControllerProvider).value?.info.status;
        if (status != GmailStatus.active) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.gmailConnectedInactive)));
        }
        next();
      }
    }

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
                  _Hero(color: brand.hero, onColor: brand.onHero),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.screen,
                          Space.xl - 4,
                          Space.screen,
                          Space.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.gmailOnboardingTitle,
                                style: textTheme.displaySmall,
                              ),
                            ),
                            const SizedBox(height: Space.sm),
                            Text(
                              l10n.gmailOnboardingBody,
                              style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: Space.lg),
                            OnboardingScopeRow(
                              icon: Icons.check_rounded,
                              iconColor: scheme.onPrimaryContainer,
                              bubbleColor: scheme.primaryContainer,
                              label: l10n.gmailReadsLabel,
                              text: l10n.gmailReads,
                            ),
                            const SizedBox(height: Space.sm),
                            OnboardingScopeRow(
                              icon: Icons.block_rounded,
                              iconColor: scheme.onSurfaceVariant,
                              bubbleColor: scheme.surfaceContainerHigh,
                              label: l10n.gmailNeverReadsLabel,
                              text: l10n.gmailNeverReads,
                            ),
                            const Spacer(),
                            const SizedBox(height: Space.lg),
                            if (showNotice) ...[
                              GmailFailureNotice(failure: failure),
                              const SizedBox(height: Space.sm),
                            ],
                            if (active)
                              FilledButton(
                                onPressed: next,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: Text(l10n.onboardingContinue),
                              )
                            else ...[
                              _ConnectButton(
                                label: busy
                                    ? l10n.gmailConnecting
                                    : showNotice
                                    ? l10n.gmailRetry
                                    : l10n.gmailConnect,
                                busy: busy,
                                onPressed: busy || loading
                                    ? null
                                    : () => unawaited(connect()),
                              ),
                              const SizedBox(height: Space.xxs),
                              TextButton(
                                onPressed: busy ? null : next,
                                child: Text(l10n.gmailNotNow),
                              ),
                            ],
                            const SizedBox(height: Space.xs),
                            Text(
                              l10n.gmailRevokeNote,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
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

class _Hero extends StatelessWidget {
  const _Hero({required this.color, required this.onColor});

  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Space.xl - 4,
            children: [
              Row(
                children: [
                  BrandMark(
                    onDark: true,
                    textColor: onColor,
                  ),
                  const Spacer(),
                  const OnboardingDots(
                    step: OnboardingStep.gmail,
                    onHero: true,
                  ),
                ],
              ),
              Semantics(
                label: l10n.gmailHeroSemantics,
                excludeSemantics: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: brand.heroCard,
                    borderRadius: Radii.noticeAll,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.md - 2,
                      vertical: Space.sm,
                    ),
                    child: Row(
                      spacing: Space.sm,
                      children: [
                        OnboardingBubble(
                          icon: Icons.mail_outline_rounded,
                          color: brand.heroChip,
                          iconColor: scheme.onPrimaryContainer,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 2,
                            children: [
                              Text(
                                l10n.gmailHeroLabel,
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                l10n.gmailHeroBanks,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: Space.sm,
          children: [
            if (busy)
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              const Icon(Icons.mail_outline_rounded, size: 20),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
