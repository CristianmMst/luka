import 'package:flutter/material.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_row.dart';

/// Aviso "Sin duplicados" sobre la lista (diseño S): explica el sello
/// amarillo de los registros hechos de varios avisos. Se descarta una vez.
class DedupeHintBanner extends StatelessWidget {
  const DedupeHintBanner({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.only(left: Space.sm),
      decoration: BoxDecoration(
        color: brand.goldContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        spacing: 10,
        children: [
          const DedupeSeal(size: 26),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l10n.transactionsDedupeTitle} ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: l10n.transactionsDedupeBody),
                  ],
                ),
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: brand.onWarningContainer,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: l10n.transactionsDedupeDismiss,
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: brand.onWarningContainer,
            ),
          ),
        ],
      ),
    );
  }
}
