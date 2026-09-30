import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/theme/tokens/type_tokens.dart';
import 'package:luka/core/widgets/brand_mark.dart';
import 'package:luka/core/widgets/inline_notice.dart';
import 'package:luka/features/capture/application/notification_access_controller.dart';
import 'package:luka/features/onboarding/domain/onboarding_step.dart';
import 'package:luka/features/onboarding/presentation/onboarding_navigation.dart';
import 'package:luka/features/onboarding/presentation/widgets/onboarding_parts.dart';

/// Paso "Registra tus pagos al instante" (spec 008 §3.1, F4.4, diseño A
/// "Hero como Gmail"): explica qué lee y qué ignora, y abre el ajuste del
/// sistema. Al volver el acceso se vuelve a consultar (AC-3.4); concedido,
/// ofrece "Continuar". La pantalla es la divulgación destacada que Play pide
/// antes del ajuste (spec 010 §2).
class NotificationsOnboardingPage extends ConsumerWidget {
  const NotificationsOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final access = ref.watch(notificationAccessProvider);
    final granted = switch (access.value) {
      NotificationAccess.granted || NotificationAccess.unsupported => true,
      NotificationAccess.denied || null => false,
    };

    void next() => unawaited(
      advanceOnboarding(context, ref, OnboardingStep.notifications),
    );

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
                  const _Hero(),
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
                                l10n.notificationDisclosureTitle,
                                style: textTheme.displaySmall,
                              ),
                            ),
                            const SizedBox(height: Space.sm),
                            Text(
                              l10n.notificationsOnboardingBody,
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
                              text: l10n.notificationsOnboardingReads,
                            ),
                            const SizedBox(height: Space.sm),
                            OnboardingScopeRow(
                              icon: Icons.block_rounded,
                              iconColor: scheme.onSurfaceVariant,
                              bubbleColor: scheme.surfaceContainerHigh,
                              label: l10n.onboardingIgnoresLabel,
                              text: l10n.notificationsOnboardingIgnores,
                            ),
                            const Spacer(),
                            const SizedBox(height: Space.lg),
                            if (granted) ...[
                              InlineNotice(
                                message: l10n.notificationsOnboardingGranted,
                                tone: NoticeTone.info,
                                icon: Icons.check_circle_outline_rounded,
                              ),
                              const SizedBox(height: Space.sm),
                              FilledButton(
                                onPressed: next,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: Text(l10n.onboardingContinue),
                              ),
                            ] else ...[
                              FilledButton.icon(
                                onPressed: access.isLoading && !access.hasValue
                                    ? null
                                    : () => unawaited(
                                        ref
                                            .read(
                                              notificationAccessProvider
                                                  .notifier,
                                            )
                                            .openSettings(),
                                      ),
                                icon: const Icon(
                                  Icons.notifications_active_outlined,
                                  size: 20,
                                ),
                                label: Text(l10n.notificationsOnboardingEnable),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                              ),
                              const SizedBox(height: Space.xxs),
                              TextButton(
                                onPressed: next,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size.fromHeight(
                                    minTouchTarget,
                                  ),
                                ),
                                child: Text(l10n.onboardingNotNow),
                              ),
                            ],
                            const SizedBox(height: Space.xs),
                            Text(
                              l10n.notificationDisclosureRevoke,
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

/// Hero café con la marca, el progreso y un ejemplo: la notificación
/// de una compra que queda registrada sola.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            spacing: Space.xl - 4,
            children: [
              Row(
                children: [
                  BrandMark(onDark: true, textColor: brand.onHero),
                  const Spacer(),
                  const OnboardingDots(
                    step: OnboardingStep.notifications,
                    onHero: true,
                  ),
                ],
              ),
              Semantics(
                label: l10n.notificationsHeroSemantics,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: Space.sm,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: Space.sm,
                          children: [
                            OnboardingBubble(
                              icon: Icons.notifications_none_rounded,
                              color: brand.heroChip,
                              iconColor: scheme.onPrimaryContainer,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 2,
                                children: [
                                  Text(
                                    l10n.notificationsHeroSender,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    l10n.notificationsHeroText,
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 1, color: scheme.surfaceContainerHigh),
                        Row(
                          spacing: Space.xs,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: brand.income,
                            ),
                            Expanded(
                              child: Text(
                                l10n.notificationsHeroResult,
                                style: textTheme.titleSmall,
                              ),
                            ),
                            Text(
                              formatCop(
                                const Cop(4590000),
                                sign: AmountSign.negative,
                              ),
                              style: amountTextStyle.copyWith(
                                fontSize: 14,
                                color: brand.expense,
                              ),
                            ),
                          ],
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
