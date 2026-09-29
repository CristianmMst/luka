import 'dart:async';

import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/features/accounts/application/account_actions.dart';
import 'package:finanzia/features/accounts/presentation/account_picker_sheet.dart';
import 'package:finanzia/features/nfc/application/nfc_actions.dart';
import 'package:finanzia/features/nfc/domain/nfc_ports.dart';
import 'package:finanzia/features/nfc/presentation/nfc_format.dart';
import 'package:finanzia/features/nfc/presentation/nfc_write_screen.dart';
import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/presentation/widgets/category_sheet.dart';
import 'package:finanzia/features/transactions/presentation/widgets/sheet_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hoja "Nuevo tag" / "Editar tag" (F4.5b): nombre, categoría, cuenta y
/// nota de la plantilla, con "Guardar y escribir en un tag".
class NfcTagFormSheet extends ConsumerStatefulWidget {
  const NfcTagFormSheet({this.existing, super.key});

  final NfcTagTemplate? existing;

  static Future<void> show(BuildContext context, {NfcTagTemplate? existing}) =>
      showFinanziaSheet<void>(
        context,
        builder: (_) => NfcTagFormSheet(existing: existing),
      );

  @override
  ConsumerState<NfcTagFormSheet> createState() => _NfcTagFormSheetState();
}

class _NfcTagFormSheetState extends ConsumerState<NfcTagFormSheet> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _note = TextEditingController(text: widget.existing?.note);
  late String? _categoryId = widget.existing?.categoryId;
  late String? _accountId = widget.existing?.accountId;
  String? _categoryName;
  String? _accountName;
  bool _nameError = false;
  bool _busy = false;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final choice = await CategorySheet.show(context, selectedId: _categoryId);
    final id = choice?.id;
    if (id == null || !mounted) return;
    setState(() {
      _categoryId = id;
      _categoryName = choice?.name;
    });
  }

  Future<void> _pickAccount() async {
    final pick = await AccountPickerSheet.show(context, selectedId: _accountId);
    if (pick == null || !mounted) return;
    setState(() {
      _accountId = pick.id;
      _accountName = pick.name;
    });
  }

  /// Guarda; con [write] abre la pantalla de escribir. Cierra la hoja al
  /// terminar.
  Future<void> _save({required bool write}) async {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final saved = await ref
        .read(nfcActionsProvider)
        .save(
          NfcTagTemplate(
            id: widget.existing?.id ?? '',
            name: _name.text,
            categoryId: _categoryId,
            accountId: _accountId,
            note: _note.text,
          ),
        );
    if (!mounted) return;
    if (write) await NfcWriteScreen.show(context, saved);
    messenger.showSnackBar(SnackBar(content: Text(l10n.nfcTagSaved)));
    navigator.pop();
  }

  Future<void> _write() async {
    final existing = widget.existing;
    if (existing == null) return;
    await NfcWriteScreen.show(context, existing);
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(nfcActionsProvider).delete(existing.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.nfcTagDeleted)));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.finanziaColors;
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final canWrite = ref.watch(nfcWriteSupportedProvider);
    final categories = ref.watch(transactionCategoriesProvider).value ?? [];
    final accounts = ref.watch(linkedAccountsProvider).value ?? const [];
    final draft = NfcTagTemplate(
      id: '',
      name: '',
      categoryId: _categoryId,
      accountId: _accountId,
    );
    final categoryName =
        _categoryName ??
        templateCategoryName(draft, categories) ??
        l10n.nfcTagMetaNone;
    final accountName =
        _accountName ??
        templateAccountName(l10n, draft, accounts) ??
        l10n.accountPickerNone;
    InputDecoration field(String hint, {String? error}) => InputDecoration(
      hintText: hint,
      errorText: error,
      filled: true,
      fillColor: brand.tile,
      border: const OutlineInputBorder(borderRadius: Radii.rowAll),
    );

    Widget picker(String title, String value, VoidCallback onTap) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.xxs,
      children: [
        Text(title, style: label),
        Semantics(
          button: true,
          label: l10n.reviewChangeSemantics(title, value),
          excludeSemantics: true,
          child: Material(
            color: brand.tile,
            shape: RoundedRectangleBorder(
              borderRadius: Radii.rowAll,
              side: BorderSide(color: scheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _busy ? null : onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

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
          Semantics(
            header: true,
            child: Text(
              _editing ? l10n.nfcTagFormEditTitle : l10n.nfcTagFormNewTitle,
              style: textTheme.headlineSmall?.copyWith(fontSize: 22),
            ),
          ),
          Text(l10n.nfcTagFormName, style: label),
          TextField(
            controller: _name,
            autofocus: !_editing,
            enabled: !_busy,
            maxLength: NfcTagTemplate.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_nameError) setState(() => _nameError = false);
            },
            decoration: field(
              l10n.nfcTagFormNameHint,
              error: _nameError ? l10n.nfcTagFormNameRequired : null,
            ).copyWith(counterText: ''),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Space.sm,
            children: [
              Expanded(
                child: picker(
                  l10n.quickAddCategory,
                  categoryName,
                  () => unawaited(_pickCategory()),
                ),
              ),
              Expanded(
                child: picker(
                  l10n.accountFieldLabel,
                  accountName,
                  () => unawaited(_pickAccount()),
                ),
              ),
            ],
          ),
          Text(l10n.nfcTagFormNote, style: label),
          TextField(
            controller: _note,
            enabled: !_busy,
            textCapitalization: TextCapitalization.sentences,
            decoration: field(l10n.nfcTagFormNoteHint),
          ),
          if (_editing) ...[
            FilledButton(
              onPressed: _busy ? null : () => unawaited(_save(write: false)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(l10n.nfcTagFormSave),
            ),
            if (canWrite)
              OutlinedButton.icon(
                onPressed: _busy ? null : () => unawaited(_write()),
                icon: const Icon(Icons.nfc_rounded),
                label: Text(l10n.nfcTagFormWrite),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            TextButton(
              onPressed: _busy ? null : () => unawaited(_delete()),
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.nfcTagFormDelete),
            ),
          ] else ...[
            if (canWrite)
              FilledButton.icon(
                onPressed: _busy ? null : () => unawaited(_save(write: true)),
                icon: const Icon(Icons.nfc_rounded),
                label: Text(l10n.nfcTagFormSaveAndWrite),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            TextButton(
              onPressed: _busy ? null : () => unawaited(_save(write: false)),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.nfcTagFormSaveOnly),
            ),
          ],
        ],
      ),
    );
  }
}
