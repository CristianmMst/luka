import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/categories/presentation/category_form_sheet.dart';
import 'package:luka/features/categories/presentation/category_visuals.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/category_fit.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/presentation/widgets/category_icon.dart';
import 'package:luka/features/transactions/presentation/widgets/sheet_frame.dart';

/// Lo que se eligió en la hoja; `id` en `null` es "Todas" (solo en el
/// filtro).
typedef CategoryChoice = ({String? id, String? name});

/// Hoja "Categoría" (diseño "Hoja"): las categorías en una lista, la
/// elegida con su ícono en tomate y un check, y al final "Nueva categoría"
/// (F4.8a), que abre la hoja de crear y deja elegida la nueva. En el filtro
/// ([allowAll]) no se ofrece crear y "Todas" va primero.
///
/// Con [direction] (Registrar, diseño Y2) solo muestra las categorías de
/// ese tipo y suma un buscador sin tildes.
class CategorySheet extends ConsumerStatefulWidget {
  const CategorySheet({
    required this.selectedId,
    this.subtitle,
    this.allowAll = false,
    this.direction,
    super.key,
  });

  final String? selectedId;
  final String? subtitle;

  /// Agrega "Todas" al principio (el filtro por categoría).
  final bool allowAll;

  /// Tipo del movimiento: filtra las categorías y muestra el buscador.
  final TxDirection? direction;

  /// Abre la hoja; `null` si se cerró sin elegir.
  static Future<CategoryChoice?> show(
    BuildContext context, {
    required String? selectedId,
    String? subtitle,
    bool allowAll = false,
    TxDirection? direction,
  }) => showLukaSheet<CategoryChoice>(
    context,
    builder: (_) => CategorySheet(
      selectedId: selectedId,
      subtitle: subtitle,
      allowAll: allowAll,
      direction: direction,
    ),
  );

  @override
  ConsumerState<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<CategorySheet> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final direction = widget.direction;
    final all =
        ref.watch(transactionCategoriesProvider).value ??
        const <CategoryOption>[];
    final categories = direction == null
        ? all
        : categoriesFor(all, direction, query: _query);

    // La lista suele ser más alta que la pantalla: con el scroll dentro de
    // un DraggableScrollableSheet, deslizar hacia abajo desde arriba encoge
    // la hoja y la cierra, en vez de quedarse en el overscroll.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Alto estimado con todas las del tipo (sin la búsqueda, para que
        // la hoja no salte al escribir): si cabe, la hoja mide eso.
        final rows =
            (direction == null ? all : categoriesFor(all, direction)).length +
            1;
        final estimate =
            _chromeHeight +
            (widget.subtitle == null ? 0 : _subtitleHeight) +
            (direction == null ? 0 : _searchHeight) +
            rows * _rowHeight;
        final fraction = estimate / constraints.maxHeight;
        final fits = fraction <= _maxSize;
        final initial = fits ? fraction.clamp(_minInitial, _maxSize) : _maxSize;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initial,
          maxChildSize: fits ? initial : _maxSize,
          builder: (context, scrollController) =>
              _scroll(context, l10n, categories, scrollController),
        );
      },
    );
  }

  // Altos aproximados del diseño "Hoja", en dp.
  static const _chromeHeight = 150.0; // asa, título, separaciones y bordes
  static const _subtitleHeight = 22.0;
  static const _searchHeight = 62.0;
  static const _rowHeight = 57.0; // fila de 56 + separador
  static const _minInitial = 0.3;
  static const _maxSize = 0.9;

  Widget _scroll(
    BuildContext context,
    AppLocalizations l10n,
    List<CategoryOption> categories,
    ScrollController scrollController,
  ) => SingleChildScrollView(
    controller: scrollController,
    padding: EdgeInsets.fromLTRB(
      20,
      10,
      20,
      28 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: _content(context, l10n, categories),
  );

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    List<CategoryOption> categories,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selectedId = widget.selectedId;
    final subtitle = widget.subtitle;
    final allowAll = widget.allowAll;
    final direction = widget.direction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        const SheetHandle(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Row(
              spacing: Space.sm,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.categorySheetTitle,
                      style: textTheme.headlineSmall?.copyWith(fontSize: 22),
                    ),
                  ),
                ),
                if (direction != null) _KindChip(direction: direction),
              ],
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
        if (direction != null)
          TextField(
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.categorySheetSearchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              constraints: const BoxConstraints(minHeight: minTouchTarget),
              enabledBorder: OutlineInputBorder(
                borderRadius: Radii.pillAll,
                borderSide: BorderSide(color: context.lukaColors.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: Radii.pillAll,
                borderSide: BorderSide(color: scheme.primary, width: 2),
              ),
            ),
          ),
        if (direction != null && categories.isEmpty)
          Text(
            l10n.categorySheetNoMatches(_query.trim()),
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        // Lista (diseño "Hoja"): una fila por categoría, la elegida con
        // su ícono en tomate y un check.
        Material(
          color: context.lukaColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: context.lukaColors.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, row) in [
                if (allowAll)
                  _CategoryRow(
                    icon: Icons.apps_rounded,
                    label: l10n.categorySheetAll,
                    selected: selectedId == null,
                    onTap: () =>
                        Navigator.of(context).pop((id: null, name: null)),
                  ),
                for (final category in categories)
                  _CategoryRow(
                    icon: category.isSystem
                        ? categoryIcon(category.slug)
                        : ownCategoryIcon(category.icon),
                    label: category.name,
                    selected: category.id == selectedId,
                    onTap: () => Navigator.of(
                      context,
                    ).pop((id: category.id, name: category.name)),
                  ),
                if (!allowAll)
                  _CategoryRow(
                    icon: Icons.add_rounded,
                    label: l10n.categorySheetNew,
                    selected: false,
                    isAction: true,
                    onTap: () => unawaited(_create(context)),
                  ),
              ].indexed) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 64,
                    color: context.lukaColors.hairline,
                  ),
                row,
              ],
            ],
          ),
        ),
      ],
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isAction = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// "Nueva categoría": texto e ícono en `primary`, sin check.
  final bool isAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              spacing: Space.sm,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : brand.neutralChip,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected ? scheme.onPrimary : scheme.primary,
                  ),
                ),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isAction ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, size: 22, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Gasto" o "Ingreso" junto al título: la hoja solo muestra las de ese
/// tipo.
class _KindChip extends StatelessWidget {
  const _KindChip({required this.direction});

  final TxDirection direction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final expense = direction == TxDirection.debit;
    final color = expense
        ? Theme.of(context).colorScheme.primary
        : context.lukaColors.income;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: Radii.pillAll,
      ),
      child: Text(
        expense ? l10n.detailKindExpense : l10n.detailKindIncome,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
