import 'dart:async';

import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/core/theme/tokens/type_tokens.dart';
import 'package:finanzia/features/accounts/application/account_actions.dart';
import 'package:finanzia/features/accounts/presentation/account_form_sheet.dart';
import 'package:finanzia/features/accounts/presentation/linked_account_row.dart';
import 'package:finanzia/features/accounts/presentation/my_accounts_page.dart';
import 'package:finanzia/features/onboarding/domain/onboarding_step.dart';
import 'package:finanzia/features/onboarding/presentation/onboarding_navigation.dart';
import 'package:finanzia/features/onboarding/presentation/widgets/onboarding_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Paso "¿Qué cuentas tienes?" (spec 008 §3.1, F4.4, diseño B "Lista +
/// hoja"): explica para qué sirven (detectar transferencias propias), lista
/// las agregadas y abre la misma hoja de Mis cuentas. Es el último paso:
/// "Listo" o "Ahora no" terminan el onboarding.
class AccountsOnboardingPage extends ConsumerWidget {
  const AccountsOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accounts = ref.watch(linkedAccountsProvider).value ?? const [];

    void finish() => unawaited(finishOnboarding(context, ref));

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.screen,
                  Space.xs,
                  Space.screen,
                  Space.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(
                      height: minTouchTarget,
                      child: Center(
                        child: OnboardingDots(step: OnboardingStep.accounts),
                      ),
                    ),
                    const SizedBox(height: Space.xs),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.accountsOnboardingTitle,
                        style: textTheme.displaySmall,
                      ),
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      l10n.accountsOnboardingBody,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    const _TransferExample(),
                    const SizedBox(height: Space.md),
                    if (accounts.isNotEmpty) ...[
                      LinkedAccountsCard(
                        accounts: accounts,
                        rowBuilder: (account) => LinkedAccountRow(
                          account: account,
                          onEdit: () => unawaited(
                            AccountFormSheet.show(context, existing: account),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                    ],
                    _AddAccountButton(
                      onPressed: () =>
                          unawaited(AccountFormSheet.show(context)),
                    ),
                    const Spacer(),
                    const SizedBox(height: Space.lg),
                    if (accounts.isNotEmpty)
                      FilledButton(
                        onPressed: finish,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: Text(l10n.onboardingDone),
                      )
                    else
                      TextButton(
                        onPressed: finish,
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(minTouchTarget),
                        ),
                        child: Text(l10n.onboardingNotNow),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Bancolombia ···1234 → Nequi ···9876 · $500.000, transferencia propia".
class _TransferExample extends StatelessWidget {
  const _TransferExample();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.finanziaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget account(String label) => Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: brand.card,
          borderRadius: Radii.rowAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.xs,
            vertical: Space.xs,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );

    return Semantics(
      label: l10n.accountsOnboardingExampleSemantics,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: Radii.cardAll,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            spacing: Space.xs,
            children: [
              Row(
                spacing: Space.xs,
                children: [
                  account(l10n.accountsOnboardingExampleFrom),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 22,
                    color: scheme.primary,
                  ),
                  account(l10n.accountsOnboardingExampleTo),
                ],
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatCop(const Cop(50000000)),
                      style: amountTextStyle.copyWith(color: brand.transfer),
                    ),
                    TextSpan(text: ' · ${l10n.accountsOnboardingExample}'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "+ Agregar cuenta" bajo la lista. El diseño lo dibuja punteado; aquí es
/// un borde sólido, porque Flutter no trae bordes punteados.
class _AddAccountButton extends StatelessWidget {
  const _AddAccountButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded),
      label: Text(l10n.accountsAdd),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        side: BorderSide(color: scheme.outline, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: Radii.noticeAll),
      ),
    );
  }
}
