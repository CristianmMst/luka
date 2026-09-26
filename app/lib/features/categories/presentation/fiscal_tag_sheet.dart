import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/features/categories/domain/category_catalog.dart';
import 'package:finanzia/features/categories/presentation/category_visuals.dart';
import 'package:finanzia/features/transactions/presentation/widgets/sheet_frame.dart';
import 'package:flutter/material.dart';

/// "¿Para qué la usas?": las 12 etiquetas fiscales que puede elegir el
/// usuario, en lenguaje claro y agrupadas (diseño F4.8a). Devuelve la
/// elegida, o `null` si se cerró.
class FiscalTagSheet extends StatelessWidget {
  const FiscalTagSheet({required this.selected, super.key});

  final String selected;

  static Future<String?> show(
    BuildContext context, {
    required String selected,
  }) => showFinanziaSheet<String>(
    context,
    builder: (_) => FiscalTagSheet(selected: selected),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.xs,
        children: [
          const SheetHandle(),
          Semantics(
            header: true,
            child: Text(
              l10n.fiscalSheetTitle,
              style: textTheme.headlineSmall?.copyWith(fontSize: 22),
            ),
          ),
          Text(
            l10n.fiscalSheetBody,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          for (final group in userFiscalTagGroups) ...[
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(
                fiscalGroupName(l10n, group.group).toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final tag in group.tags)
              _FiscalOption(
                title: fiscalTagName(l10n, tag),
                hint: fiscalTagHint(l10n, tag),
                selected: tag == selected,
                onTap: () => Navigator.of(context).pop(tag),
              ),
          ],
        ],
      ),
    );
  }
}

class _FiscalOption extends StatelessWidget {
  const _FiscalOption({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: Radii.rowAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.sm,
                vertical: Space.xs,
              ),
              child: Row(
                spacing: Space.sm,
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          hint,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
