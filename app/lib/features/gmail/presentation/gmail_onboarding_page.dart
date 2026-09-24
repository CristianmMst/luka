import 'dart:async';

import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/routing/routes.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/core/widgets/brand_mark.dart';
import 'package:finanzia/features/gmail/application/gmail_controller.dart';
import 'package:finanzia/features/gmail/domain/gmail_connection.dart';
import 'package:finanzia/features/gmail/domain/gmail_failure.dart';
import 'package:finanzia/features/gmail/presentation/widgets/gmail_failure_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Paso "Conecta tu Gmail" tras el login (spec 008 §3.1, AC-1.2/AC-1.3), con
/// el lenguaje del login "Veta esmeralda": hero esmeralda y titular
/// Bricolage. Conectar y "Ahora no" llevan a Inicio; si la conexión quedó
/// guardada pero sin captura (`error`/`revoked`), avisa que se reintenta
/// desde Ajustes.
class GmailOnboardingPage extends ConsumerWidget {
  const GmailOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final brand = context.finanziaColors;
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
            _ => const GmailUnexpected(),
          }
        : current?.failure;
    final showNotice = failure != null && failure is! GmailConsentCancelled;

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
        context.go(Routes.home);
      }
    }

    Future<void> notNow() async {
      await controller.skip();
      if (context.mounted) context.go(Routes.home);
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
                            _ScopeRow(
                              icon: Icons.check_rounded,
                              iconColor: scheme.onPrimaryContainer,
                              bubbleColor: scheme.primaryContainer,
                              label: l10n.gmailReadsLabel,
                              text: l10n.gmailReads,
                            ),
                            const SizedBox(height: Space.sm),
                            _ScopeRow(
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
                              onPressed: busy
                                  ? null
                                  : () => unawaited(notNow()),
                              child: Text(l10n.gmailNotNow),
                            ),
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
    final brand = context.finanziaColors;
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
              BrandMark(
                gemColor: context.finanziaColors.gem,
                textColor: onColor,
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
                        _Bubble(
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

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.icon,
    required this.color,
    required this.iconColor,
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
class _ScopeRow extends StatelessWidget {
  const _ScopeRow({
    required this.icon,
    required this.iconColor,
    required this.bubbleColor,
    required this.label,
    required this.text,
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
            child: _Bubble(
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
