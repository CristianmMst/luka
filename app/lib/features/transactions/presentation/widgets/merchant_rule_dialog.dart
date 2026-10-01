import 'package:flutter/material.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';

/// "¿Aplicar siempre a {comercio}?" (diseño "Categoria", AC-7.2): `true`
/// aprende la regla del comercio, `false` cambia solo este movimiento y
/// `null` (cerrar) no cambia nada.
class MerchantRuleDialog extends StatelessWidget {
  const MerchantRuleDialog({
    required this.merchant,
    required this.categoryName,
    super.key,
  });

  final String merchant;
  final String categoryName;

  static Future<bool?> show(
    BuildContext context, {
    required String merchant,
    required String categoryName,
  }) => showDialog<bool>(
    context: context,
    builder: (_) =>
        MerchantRuleDialog(merchant: merchant, categoryName: categoryName),
  );

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
                      color: context.lukaColors.neutralChip,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      size: 22,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  l10n.merchantRuleTitle(merchant),
                  style: textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    height: 1.15,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: l10n.merchantRuleBodyBefore),
                    TextSpan(
                      text: categoryName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    TextSpan(text: l10n.merchantRuleBodyAfter),
                  ],
                ),
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Space.xs,
                  children: [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        l10n.merchantRuleAlways(merchant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onSurface,
                      ),
                      child: Text(l10n.merchantRuleOnce),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
