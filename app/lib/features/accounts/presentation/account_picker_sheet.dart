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
import 'package:luka/features/transactions/presentation/widgets/sheet_frame.dart';

/// Lo que eligió el usuario en [AccountPickerSheet]: una cuenta o "Sin
/// cuenta" (`id == null`).
typedef AccountPick = ({String? id, String? name});

/// Hoja "¿De qué cuenta?" (diseño A "Fila + hoja", F4.8b, spec 008 §3.4):
/// las cuentas vinculadas, "Sin cuenta" y "+ Agregar cuenta", que crea una
/// y la deja elegida. Devuelve `null` si se cerró sin elegir.
class AccountPickerSheet extends ConsumerWidget {
  const AccountPickerSheet({this.selectedId, super.key});

  final String? selectedId;

  static Future<AccountPick?> show(
    BuildContext context, {
    String? selectedId,
  }) => showLukaSheet<AccountPick>(
    context,
    builder: (_) => AccountPickerSheet(selectedId: selectedId),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accounts = ref.watch(linkedAccountsProvider).value ?? const [];

    Future<void> create() async {
      final navigator = Navigator.of(context);
      final created = await AccountFormSheet.show(context);
      if (created == null) return;
      final account = LinkedAccount(
        id: created.id,
        bank: created.bank,
        kind: created.kind,
        last4: created.last4,
        alias: created.alias,
        transactionCount: 0,
      );
      navigator.pop<AccountPick>((
        id: account.id,
        name: linkedAccountTitle(l10n, account),
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.lg, 10, Space.lg, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.xs,
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Semantics(
              header: true,
              child: Text(
                l10n.accountPickerTitle,
                style: textTheme.headlineSmall?.copyWith(fontSize: 22),
              ),
            ),
          ),
          for (final account in accounts)
            _Option(
              title: linkedAccountTitle(l10n, account),
              subtitle: linkedAccountMeta(l10n, account),
              selected: account.id == selectedId,
              onTap: () => Navigator.of(context).pop<AccountPick>((
                id: account.id,
                name: linkedAccountTitle(l10n, account),
              )),
            ),
          _Option(
            title: l10n.accountPickerNone,
            selected: selectedId == null,
            muted: true,
            onTap: () => Navigator.of(
              context,
            ).pop<AccountPick>((id: null, name: null)),
          ),
          const SizedBox(height: Space.xs),
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
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.muted = false,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final subtitle = this.subtitle;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primaryContainer : context.lukaColors.tile,
        borderRadius: Radii.rowAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: Space.xs,
              ),
              child: Row(
                spacing: Space.sm,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: muted
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: muted && !selected
                                ? scheme.onSurfaceVariant
                                : foreground,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: selected
                                  ? foreground
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_rounded, color: scheme.onPrimaryContainer),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
