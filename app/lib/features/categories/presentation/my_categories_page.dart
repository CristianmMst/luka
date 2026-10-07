import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/categories/application/category_actions.dart';
import 'package:luka/features/categories/domain/categories_ports.dart';
import 'package:luka/features/categories/presentation/category_form_sheet.dart';
import 'package:luka/features/categories/presentation/category_visuals.dart';

/// Ajustes → "Mis categorías" (spec 008 §3.7, F4.8a): las categorías
/// propias del usuario, que solo ve él, con crear, editar y borrar.
class MyCategoriesPage extends ConsumerWidget {
  const MyCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final own = ref.watch(ownCategoriesProvider).value ?? const [];
    final section = textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: scheme.onSurfaceVariant,
    );

    Future<void> create() async {
      final created = await CategoryFormSheet.show(context);
      if (created != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.categoryCreated)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myCategoriesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.xs,
            Space.screen,
            Space.xl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.myCategoriesOwnSection.toUpperCase(),
                style: section,
              ),
            ),
            const SizedBox(height: Space.sm),
            if (own.isEmpty)
              Text(
                l10n.myCategoriesEmpty,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.lukaColors.card,
                  borderRadius: Radii.noticeAll,
                  border: Border.all(color: context.lukaColors.hairline),
                ),
                child: Column(
                  children: [
                    for (final (i, category) in own.indexed) ...[
                      if (i > 0)
                        Divider(height: 1, color: scheme.surfaceContainer),
                      _CategoryRow(category: category),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: Space.sm),
            OutlinedButton.icon(
              onPressed: () => unawaited(create()),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.myCategoriesNew),
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

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category});

  final OwnCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> edit() async {
      final saved = await CategoryFormSheet.show(context, existing: category);
      if (saved != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.categorySaved)));
      }
    }

    Future<void> delete() async {
      final messenger = ScaffoldMessenger.of(context);
      if (!await CategoryDeleteDialog.show(context, category)) return;
      try {
        await ref.read(categoryActionsProvider).delete(category.id);
        messenger.showSnackBar(SnackBar(content: Text(l10n.categoryDeleted)));
      } on CategoryFailure catch (failure) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(switch (failure) {
              CategoryOffline() => l10n.categoryErrorOffline,
              CategoryGone() => l10n.categoryErrorGone,
              _ => l10n.categoryErrorUnexpected,
            }),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 14, right: Space.xxs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          spacing: Space.sm,
          children: [
            OwnCategoryAvatar(icon: category.icon, color: category.color),
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      category.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.myCategoriesMeta(
                        fiscalTagName(l10n, category.fiscalTag),
                        category.transactionCount,
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => unawaited(edit()),
              tooltip: l10n.myCategoriesEditSemantics(category.name),
              icon: Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
            ),
            IconButton(
              onPressed: () => unawaited(delete()),
              tooltip: l10n.myCategoriesDeleteSemantics(category.name),
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            ),
          ],
        ),
      ),
    );
  }
}

/// "¿Borrar «X»?": dice cuántos movimientos pasan a "Sin categoría".
/// `true` confirma.
class CategoryDeleteDialog extends StatelessWidget {
  const CategoryDeleteDialog({required this.category, super.key});

  final OwnCategory category;

  static Future<bool> show(BuildContext context, OwnCategory category) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => CategoryDeleteDialog(category: category),
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
                  l10n.categoryDeleteTitle(category.name),
                  style: textTheme.headlineSmall?.copyWith(fontSize: 22),
                ),
              ),
              Text(
                l10n.categoryDeleteBody(category.transactionCount),
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
                child: Text(l10n.categoryDeleteConfirm),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(minTouchTarget),
                ),
                child: Text(l10n.categoryDeleteCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
