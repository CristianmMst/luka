import 'dart:async';

import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/features/categories/presentation/category_form_sheet.dart';
import 'package:finanzia/features/categories/presentation/category_visuals.dart';
import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/domain/category_option.dart';
import 'package:finanzia/features/transactions/presentation/widgets/category_icon.dart';
import 'package:finanzia/features/transactions/presentation/widgets/sheet_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lo que se eligió en la hoja; `id` en `null` es "Todas" (solo en el
/// filtro).
typedef CategoryChoice = ({String? id, String? name});

/// Hoja "Categoría" (diseño "Categoria"): rejilla de 3 columnas con las
/// categorías y "+ Nueva categoría" (F4.8a), que abre la hoja de crear y
/// deja elegida la nueva. En el filtro ([allowAll]) no se ofrece crear.
class CategorySheet extends ConsumerWidget {
  const CategorySheet({
    required this.selectedId,
    this.subtitle,
    this.allowAll = false,
    super.key,
  });

  final String? selectedId;
  final String? subtitle;

  /// Agrega "Todas" al principio (el filtro por categoría).
  final bool allowAll;

  /// Abre la hoja; `null` si se cerró sin elegir.
  static Future<CategoryChoice?> show(
    BuildContext context, {
    required String? selectedId,
    String? subtitle,
    bool allowAll = false,
  }) => showFinanziaSheet<CategoryChoice>(
    context,
    builder: (_) => CategorySheet(
      selectedId: selectedId,
      subtitle: subtitle,
      allowAll: allowAll,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categories =
        ref.watch(transactionCategoriesProvider).value ??
        const <CategoryOption>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          const SheetHandle(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.categorySheetTitle,
                  style: textTheme.headlineSmall?.copyWith(fontSize: 22),
                ),
              ),
              if (subtitle case final subtitle?)
                Text(
                  subtitle,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          GridView(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: Space.xs,
              crossAxisSpacing: Space.xs,
              mainAxisExtent: 76,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              if (allowAll)
                _CategoryTile(
                  icon: Icons.apps_rounded,
                  label: l10n.categorySheetAll,
                  selected: selectedId == null,
                  onTap: () =>
                      Navigator.of(context).pop((id: null, name: null)),
                ),
              for (final category in categories)
                _CategoryTile(
                  icon: category.isSystem
                      ? categoryIcon(category.slug)
                      : ownCategoryIcon(category.icon),
                  label: category.name,
                  selected: category.id == selectedId,
                  onTap: () => Navigator.of(
                    context,
                  ).pop((id: category.id, name: category.name)),
                ),
            ],
          ),
          if (!allowAll)
            OutlinedButton(
              onPressed: () => unawaited(_create(context)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(minTouchTarget),
                side: BorderSide(color: scheme.outline),
              ),
              child: Text(l10n.categorySheetNew),
            ),
        ],
      ),
    );
  }
}

Future<void> _create(BuildContext context) async {
  final navigator = Navigator.of(context);
  final created = await CategoryFormSheet.show(context);
  if (created != null && navigator.mounted) {
    navigator.pop<CategoryChoice>((id: created.id, name: created.name));
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = context.finanziaColors;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primaryContainer : brand.tile,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.noticeAll,
          side: selected
              ? BorderSide(color: scheme.primary, width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                Icon(icon, size: 22, color: foreground),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 16 / 13,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
