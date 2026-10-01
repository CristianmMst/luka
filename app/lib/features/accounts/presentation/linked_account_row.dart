import 'package:flutter/material.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// Nombre de la cuenta en listas y diálogos: su alias o, sin alias, el banco.
String linkedAccountTitle(AppLocalizations l10n, LinkedAccount account) =>
    account.alias ?? bankLabel(l10n, account.bank);

/// "Bancolombia · Ahorros ···4821"; sin últimos 4, sin el sufijo.
String linkedAccountMeta(AppLocalizations l10n, LinkedAccount account) {
  final bank = bankLabel(l10n, account.bank);
  final kind = capitalize(accountKindLabel(l10n, account.kind));
  final last4 = account.last4;
  return last4 == null
      ? l10n.accountRowMeta(bank, kind)
      : l10n.accountRowMetaWithLast4(bank, kind, last4);
}

/// Fila de una cuenta vinculada (Mis cuentas y el paso Cuentas del
/// onboarding): ícono, nombre, banco y tipo, y sus acciones de 48 dp.
class LinkedAccountRow extends StatelessWidget {
  const LinkedAccountRow({
    required this.account,
    required this.onEdit,
    this.onDelete,
    super.key,
  });

  final LinkedAccount account;
  final VoidCallback onEdit;

  /// `null` oculta "Borrar" (el onboarding solo edita).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = linkedAccountTitle(l10n, account);

    return Padding(
      padding: const EdgeInsets.only(left: 14, right: Space.xxs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          spacing: Space.sm,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.lukaColors.neutralChip,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_outlined,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
            ),
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      linkedAccountMeta(l10n, account),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: onEdit,
              tooltip: l10n.accountEditSemantics(title),
              icon: Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
            ),
            if (onDelete case final delete?)
              IconButton(
                onPressed: delete,
                tooltip: l10n.accountDeleteSemantics(title),
                icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
