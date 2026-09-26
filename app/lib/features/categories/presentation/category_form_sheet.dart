import 'dart:async';

import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/core/widgets/inline_notice.dart';
import 'package:finanzia/features/categories/application/category_actions.dart';
import 'package:finanzia/features/categories/domain/categories_ports.dart';
import 'package:finanzia/features/categories/domain/category_catalog.dart';
import 'package:finanzia/features/categories/domain/category_draft.dart';
import 'package:finanzia/features/categories/presentation/category_visuals.dart';
import 'package:finanzia/features/categories/presentation/fiscal_tag_sheet.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/presentation/widgets/sheet_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hoja "Nueva categoría" / "Editar categoría" (diseño A "Hoja completa",
/// F4.8a): nombre, ícono, color y "¿Para qué la usas?". Pide conexión.
/// Devuelve la categoría guardada, o `null` si se cerró.
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({this.existing, super.key});

  /// La categoría a editar; `null` crea una nueva.
  final OwnCategory? existing;

  static Future<SyncedCategory?> show(
    BuildContext context, {
    OwnCategory? existing,
  }) => showFinanziaSheet<SyncedCategory>(
    context,
    builder: (_) => CategoryFormSheet(existing: existing),
  );

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late CategoryDraft _draft = switch (widget.existing) {
    final c? => CategoryDraft.fromExisting(
      name: c.name,
      fiscalTag: c.fiscalTag,
      icon: c.icon,
      color: c.color,
    ),
    null => const CategoryDraft(name: ''),
  };
  late final _name = TextEditingController(text: _draft.name);
  Set<CategoryDraftError> _errors = const {};
  CategoryFailure? _failure;
  var _busy = false;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickFiscalTag() async {
    final tag = await FiscalTagSheet.show(context, selected: _draft.fiscalTag);
    if (tag == null || !mounted) return;
    setState(() => _draft = _draft.copyWith(fiscalTag: tag));
  }

  Future<void> _save() async {
    final draft = _draft.copyWith(name: _name.text);
    final errors = draft.validate();
    setState(() {
      _errors = errors;
      _failure = null;
    });
    if (errors.isNotEmpty) return;
    setState(() => _busy = true);
    final actions = ref.read(categoryActionsProvider);
    final navigator = Navigator.of(context);
    try {
      final saved = switch (widget.existing) {
        final c? => await actions.update(c.id, draft),
        null => await actions.create(draft),
      };
      navigator.pop(saved);
    } on CategoryFailure catch (failure) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = failure;
        });
      }
    }
  }

  String? get _nameError {
    final l10n = AppLocalizations.of(context);
    if (_errors.contains(CategoryDraftError.nameRequired)) {
      return l10n.categoryNameRequired;
    }
    if (_errors.contains(CategoryDraftError.nameTooLong)) {
      return l10n.categoryNameTooLong;
    }
    if (_failure is CategoryDuplicateName) return l10n.categoryErrorDuplicate;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.finanziaColors;
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final failureMessage = switch (_failure) {
      CategoryOffline() => l10n.categoryErrorOffline,
      CategoryGone() => l10n.categoryErrorGone,
      CategoryUnexpected() => l10n.categoryErrorUnexpected,
      CategoryDuplicateName() || null => null,
    };

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        10,
        Space.lg,
        Space.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.sm,
        children: [
          const SheetHandle(),
          Row(
            spacing: Space.sm,
            children: [
              OwnCategoryAvatar(
                icon: _draft.icon,
                color: _draft.color,
                size: 44,
              ),
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    _editing
                        ? l10n.categoryFormEditTitle
                        : l10n.categoryFormNewTitle,
                    style: textTheme.headlineSmall?.copyWith(fontSize: 22),
                  ),
                ),
              ),
            ],
          ),
          Text(l10n.categoryFormName, style: label),
          TextField(
            controller: _name,
            autofocus: !_editing,
            textCapitalization: TextCapitalization.sentences,
            maxLength: CategoryDraft.maxNameLength,
            onChanged: (_) {
              if (_nameError != null) {
                setState(() {
                  _errors = const {};
                  _failure = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: l10n.categoryFormNameHint,
              errorText: _nameError,
              counterText: '',
              filled: true,
              fillColor: brand.tile,
              border: const OutlineInputBorder(borderRadius: Radii.rowAll),
            ),
          ),
          Text(l10n.categoryFormIcon, style: label),
          // 6 por fila: cada ícono conserva un área táctil de 48 dp o más.
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Space.xxs,
            crossAxisSpacing: Space.xxs,
            children: [
              for (final key in categoryIconKeys)
                _IconChoice(
                  icon: ownCategoryIcon(key),
                  semantics: l10n.categoryIconSemantics(
                    categoryIconName(l10n, key),
                  ),
                  selected: key == _draft.icon,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(icon: key)),
                ),
            ],
          ),
          Text(l10n.categoryFormColor, style: label),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              for (final hex in categoryColors)
                _ColorChoice(
                  color: ownCategoryColor(hex),
                  semantics: l10n.categoryColorSemantics(
                    categoryColorName(l10n, hex),
                  ),
                  selected: hex == _draft.color,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(color: hex)),
                ),
            ],
          ),
          Text(l10n.categoryFormPurpose, style: label),
          Material(
            color: brand.tile,
            shape: RoundedRectangleBorder(
              borderRadius: Radii.rowAll,
              side: BorderSide(color: scheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _busy ? null : () => unawaited(_pickFiscalTag()),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: Space.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fiscalTagName(l10n, _draft.fiscalTag),
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              fiscalTagHint(l10n, _draft.fiscalTag),
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (failureMessage != null)
            InlineNotice(message: failureMessage, tone: NoticeTone.error),
          Row(
            spacing: Space.sm,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(l10n.categoryFormCancel),
                ),
              ),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _busy ? null : () => unawaited(_save()),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _editing
                              ? l10n.categoryFormSave
                              : l10n.categoryFormCreate,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.semantics,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String semantics;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: semantics,
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.primaryContainer : context.finanziaColors.tile,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.rowAll,
          side: selected
              ? BorderSide(color: scheme.primary, width: 2)
              : BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Icon(icon, size: 20, color: scheme.primary),
        ),
      ),
    );
  }
}

/// Muestra de color de 32 dp dentro de un área táctil de 48 dp o más.
class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.semantics,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String semantics;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: semantics,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: minTouchTarget / 2,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: minTouchTarget,
            minHeight: minTouchTarget,
          ),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: scheme.surface, width: 3)
                    : null,
                boxShadow: selected
                    ? [BoxShadow(color: scheme.onSurface, spreadRadius: 2)]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
