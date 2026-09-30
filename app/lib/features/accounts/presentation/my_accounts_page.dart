import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';
import 'package:luka/features/accounts/presentation/account_form_sheet.dart';
import 'package:luka/features/accounts/presentation/linked_account_row.dart';

/// Ajustes → "Mis cuentas" (spec 008 §3.7, F4.4): las cuentas vinculadas,
/// con agregar, editar y borrar.
class MyAccountsPage extends ConsumerWidget {
  const MyAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accounts = ref.watch(linkedAccountsProvider).value ?? const [];

    Future<void> create() async {
      final created = await AccountFormSheet.show(context);
      if (created != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.accountCreated)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myAccountsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.xs,
            Space.screen,
            Space.xl,
          ),
          children: [
            Text(
              l10n.myAccountsIntro,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            if (accounts.isEmpty)
              Text(l10n.myAccountsEmpty, style: textTheme.bodyMedium)
            else
              LinkedAccountsCard(
                accounts: accounts,
                rowBuilder: (account) => _AccountRow(account: account),
              ),
            const SizedBox(height: Space.sm),
            OutlinedButton.icon(
              onPressed: () => unawaited(create()),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.accountsAdd),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(color: scheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con las cuentas separadas por líneas.
class LinkedAccountsCard extends StatelessWidget {
  const LinkedAccountsCard({
    required this.accounts,
    required this.rowBuilder,
    super.key,
  });

  final List<LinkedAccount> accounts;
  final Widget Function(LinkedAccount account) rowBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.lukaColors.card,
        borderRadius: Radii.noticeAll,
      ),
      child: Column(
        children: [
          for (final (i, account) in accounts.indexed) ...[
            if (i > 0) Divider(height: 1, color: scheme.surfaceContainer),
            rowBuilder(account),
          ],
        ],
      ),
    );
  }
}

class _AccountRow extends ConsumerWidget {
  const _AccountRow({required this.account});

  final LinkedAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    Future<void> edit() async {
      final saved = await AccountFormSheet.show(context, existing: account);
      if (saved != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.accountSaved)));
      }
    }

    Future<void> delete() async {
      final messenger = ScaffoldMessenger.of(context);
      if (!await AccountDeleteDialog.show(context, account)) return;
      try {
        await ref.read(accountActionsProvider).delete(account.id);
        messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
      } on AccountFailure catch (failure) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(switch (failure) {
              AccountOffline() => l10n.accountErrorOffline,
              AccountGone() => l10n.accountErrorGone,
              _ => l10n.accountErrorUnexpected,
            }),
          ),
        );
      }
    }

    return LinkedAccountRow(
      account: account,
      onEdit: () => unawaited(edit()),
      onDelete: () => unawaited(delete()),
    );
  }
}

/// "¿Borrar «X»?": dice cuántos movimientos quedan sin cuenta. `true`
/// confirma.
class AccountDeleteDialog extends StatelessWidget {
  const AccountDeleteDialog({required this.account, super.key});

  final LinkedAccount account;

  static Future<bool> show(BuildContext context, LinkedAccount account) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AccountDeleteDialog(account: account),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: context.lukaColors.card,
      shape: const RoundedRectangleBorder(borderRadius: Radii.cardAll),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 326),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.errorContainer,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 22,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  l10n.accountDeleteTitle(linkedAccountTitle(l10n, account)),
                  style: textTheme.headlineSmall?.copyWith(fontSize: 22),
                ),
              ),
              Text(
                l10n.accountDeleteBody(account.transactionCount),
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                child: Text(l10n.accountDeleteConfirm),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(minTouchTarget),
                ),
                child: Text(l10n.accountDeleteCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
