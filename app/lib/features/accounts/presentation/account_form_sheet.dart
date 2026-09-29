import 'dart:async';

import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/core/widgets/inline_notice.dart';
import 'package:finanzia/features/accounts/application/account_actions.dart';
import 'package:finanzia/features/accounts/domain/account_draft.dart';
import 'package:finanzia/features/accounts/domain/accounts_ports.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/presentation/widgets/sheet_frame.dart';
import 'package:finanzia/features/transactions/presentation/widgets/transaction_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hoja "Nueva cuenta" / "Editar cuenta" (diseño B "Lista + hoja", F4.4):
/// banco, tipo, últimos 4 y alias. La usan Mis cuentas y el paso Cuentas
/// del onboarding. Pide conexión. Devuelve la cuenta guardada, o `null` si
/// se cerró.
class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({this.existing, super.key});

  /// La cuenta a editar; `null` crea una nueva.
  final LinkedAccount? existing;

  static Future<SyncedAccount?> show(
    BuildContext context, {
    LinkedAccount? existing,
  }) => showFinanziaSheet<SyncedAccount>(
    context,
    builder: (_) => AccountFormSheet(existing: existing),
  );

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  late AccountDraft _draft = switch (widget.existing) {
    final a? => AccountDraft(
      bank: a.bank,
      kind: accountKinds.contains(a.kind) ? a.kind : accountKinds.first,
      last4: a.last4 ?? '',
      alias: a.alias ?? '',
    ),
    null => const AccountDraft(),
  };
  late final _last4 = TextEditingController(text: _draft.last4);
  late final _alias = TextEditingController(text: _draft.alias);
  Set<AccountDraftError> _errors = const {};
  AccountFailure? _failure;
  var _busy = false;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _last4.dispose();
    _alias.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final draft = _draft.copyWith(last4: _last4.text, alias: _alias.text);
    final errors = draft.validate();
    setState(() {
      _errors = errors;
      _failure = null;
    });
    if (errors.isNotEmpty) return;
    setState(() => _busy = true);
    final actions = ref.read(accountActionsProvider);
    final navigator = Navigator.of(context);
    try {
      final saved = switch (widget.existing) {
        final a? => await actions.update(a.id, draft),
        null => await actions.create(draft),
      };
      navigator.pop(saved);
    } on AccountFailure catch (failure) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = failure;
        });
      }
    }
  }

  void _clearErrors() {
    if (_errors.isNotEmpty || _failure is AccountDuplicate) {
      setState(() {
        _errors = const {};
        _failure = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.finanziaColors;
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final failureMessage = switch (_failure) {
      AccountOffline() => l10n.accountErrorOffline,
      AccountGone() => l10n.accountErrorGone,
      AccountUnexpected() => l10n.accountErrorUnexpected,
      AccountDuplicate() || null => null,
    };
    InputDecoration field({String? hint, String? error, String? helper}) =>
        InputDecoration(
          hintText: hint,
          errorText: error,
          helperText: helper,
          helperMaxLines: 3,
          counterText: '',
          filled: true,
          fillColor: brand.tile,
          border: const OutlineInputBorder(borderRadius: Radii.rowAll),
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
              _editing ? l10n.accountFormEditTitle : l10n.accountFormNewTitle,
              style: textTheme.headlineSmall?.copyWith(fontSize: 22),
            ),
          ),
          Text(l10n.accountFormBank, style: label),
          DropdownButtonFormField<String>(
            initialValue: _draft.bank.isEmpty ? null : _draft.bank,
            isExpanded: true,
            hint: Text(l10n.accountFormBankHint),
            items: [
              for (final bank in bankOptions(l10n))
                DropdownMenuItem(value: bank.wire, child: Text(bank.label)),
            ],
            onChanged: _editing || _busy
                ? null
                : (bank) {
                    if (bank == null) return;
                    setState(() {
                      _draft = _draft.copyWith(bank: bank);
                      _errors = const {};
                      _failure = null;
                    });
                  },
            decoration: field(
              error: _errors.contains(AccountDraftError.invalidBank)
                  ? l10n.accountBankRequired
                  : null,
              helper: _editing ? l10n.accountFormBankLocked : null,
            ),
          ),
          Text(l10n.accountFormKind, style: label),
          Wrap(
            spacing: Space.xs,
            children: [
              for (final kind in accountKinds)
                ChoiceChip(
                  label: Text(capitalize(accountKindLabel(l10n, kind))),
                  selected: kind == _draft.kind,
                  onSelected: _busy
                      ? null
                      : (_) => setState(
                          () => _draft = _draft.copyWith(kind: kind),
                        ),
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Space.sm,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Space.xs,
                  children: [
                    Text(l10n.accountFormLast4, style: label),
                    TextField(
                      controller: _last4,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => _clearErrors(),
                      decoration: field(
                        error: _errors.contains(AccountDraftError.invalidLast4)
                            ? l10n.accountLast4Invalid
                            : _failure is AccountDuplicate
                            ? l10n.accountErrorDuplicate
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Space.xs,
                  children: [
                    Text(l10n.accountFormAlias, style: label),
                    TextField(
                      controller: _alias,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: AccountDraft.maxAliasLength,
                      onChanged: (_) => _clearErrors(),
                      decoration: field(
                        hint: l10n.accountFormAliasHint,
                        error: _errors.contains(AccountDraftError.aliasTooLong)
                            ? l10n.accountAliasTooLong
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  child: Text(l10n.accountFormCancel),
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
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : Text(
                          _editing
                              ? l10n.accountFormSave
                              : l10n.accountFormCreate,
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
