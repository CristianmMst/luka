import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/theme/tokens/type_tokens.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/core/widgets/inline_notice.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/accounts/presentation/account_picker_sheet.dart';
import 'package:luka/features/accounts/presentation/linked_account_row.dart';
import 'package:luka/features/push/presentation/push_permission.dart';
import 'package:luka/features/recurring/application/recurring_actions.dart';
import 'package:luka/features/recurring/domain/recurring_draft.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/recurring_ports.dart';
import 'package:luka/features/recurring/presentation/recurring_format.dart';
import 'package:luka/features/review/presentation/widgets/review_format.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';
import 'package:luka/features/transactions/presentation/widgets/category_sheet.dart';
import 'package:luka/features/transactions/presentation/widgets/sheet_frame.dart';

/// Hoja "Nuevo gasto fijo" / "Editar gasto fijo" (spec 008 §3.8). Va directo
/// a la API: sin conexión lo avisa. Devuelve el gasto guardado, o `null`.
class RecurringFormSheet extends ConsumerStatefulWidget {
  const RecurringFormSheet({this.existing, this.initial, super.key});

  /// El gasto a editar; `null` crea uno nuevo.
  final RecurringExpense? existing;

  /// Borrador prellenado ("Crear gasto fijo con esto" desde un movimiento).
  final RecurringDraft? initial;

  /// Tras crear un gasto fijo, ofrece los avisos si aún no se preguntó
  /// (spec 008 §3.8).
  static Future<RecurringExpense?> show(
    BuildContext context, {
    RecurringExpense? existing,
    RecurringDraft? initial,
  }) async {
    final saved = await showLukaSheet<RecurringExpense>(
      context,
      builder: (_) => RecurringFormSheet(existing: existing, initial: initial),
    );
    if (saved != null && existing == null && context.mounted) {
      await maybeAskPushPermission(context);
    }
    return saved;
  }

  @override
  ConsumerState<RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<RecurringFormSheet> {
  late RecurringDraft _draft = switch (widget.existing) {
    final e? => RecurringDraft.fromExpense(e),
    null =>
      widget.initial ?? const RecurringDraft(name: '', merchantKeyword: ''),
  };
  late final _name = TextEditingController(text: _draft.name);
  late final _keyword = TextEditingController(text: _draft.merchantKeyword);
  late final _amount = TextEditingController(
    text: switch (_draft.expectedAmount) {
      final amount? => copInputText(amount),
      null => '',
    },
  );
  Set<RecurringDraftError> _errors = const {};
  RecurringFailure? _failure;
  var _busy = false;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _keyword.dispose();
    _amount.dispose();
    super.dispose();
  }

  RecurringDraft get _current => _draft.copyWith(
    name: _name.text,
    merchantKeyword: _keyword.text,
    expectedAmount: parseCopInput(_amount.text),
  );

  Future<void> _save() async {
    final draft = _current;
    final errors = draft.validate();
    setState(() {
      _errors = errors;
      _failure = null;
    });
    if (errors.isNotEmpty) return;
    setState(() => _busy = true);
    final actions = ref.read(recurringActionsProvider);
    final navigator = Navigator.of(context);
    try {
      final saved = switch (widget.existing) {
        final e? => await actions.update(e.id, draft),
        null => await actions.create(draft),
      };
      navigator.pop(saved);
    } on RecurringFailure catch (failure) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = failure;
        });
      }
    }
  }

  Future<void> _toggleActive() async {
    final existing = widget.existing;
    if (existing == null) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    try {
      final saved = await ref
          .read(recurringActionsProvider)
          .setActive(existing.id, active: !existing.active);
      navigator.pop(saved);
    } on RecurringFailure catch (failure) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = failure;
        });
      }
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recurringDeleteTitle(existing.name)),
        content: Text(l10n.recurringDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.recurringDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.recurringDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(recurringActionsProvider).delete(existing.id);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.recurringDeleted)));
    } on RecurringFailure catch (failure) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = failure;
        });
      }
    }
  }

  Future<void> _pickDay() async {
    final l10n = AppLocalizations.of(context);
    final day = await showLukaSheet<int>(
      context,
      builder: (context) => _DaySheet(
        selected: _draft.dayOfMonth,
        title: l10n.recurringFormDaySheetTitle,
      ),
    );
    if (day != null && mounted) {
      setState(() => _draft = _draft.copyWith(dayOfMonth: day));
    }
  }

  Future<void> _pickCategory() async {
    final choice = await CategorySheet.show(
      context,
      selectedId: _draft.categoryId,
    );
    if (choice != null && mounted) {
      setState(() => _draft = _draft.copyWith(categoryId: choice.id));
    }
  }

  Future<void> _pickAccount() async {
    final pick = await AccountPickerSheet.show(
      context,
      selectedId: _draft.accountId,
    );
    if (pick != null && mounted) {
      setState(() => _draft = _draft.copyWith(accountId: pick.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final categories =
        ref.watch(transactionCategoriesProvider).value ?? const [];
    final accounts = ref.watch(linkedAccountsProvider).value ?? const [];
    final categoryName =
        categories.where((c) => c.id == _draft.categoryId).firstOrNull?.name ??
        l10n.recurringFormNoCategory;
    final account = accounts.where((a) => a.id == _draft.accountId).firstOrNull;
    final accountName = account == null
        ? l10n.recurringFormAnyAccount
        : linkedAccountTitle(l10n, account);
    final existing = widget.existing;
    final failure = _failure;

    InputDecoration field({String? hint, String? error, Widget? prefix}) =>
        InputDecoration(
          hintText: hint,
          errorText: error,
          prefixIcon: prefix,
          counterText: '',
          filled: true,
          fillColor: brand.tile,
          border: const OutlineInputBorder(borderRadius: Radii.rowAll),
        );

    String? nameError() {
      if (_errors.contains(RecurringDraftError.nameRequired)) {
        return l10n.recurringNameRequired;
      }
      if (_errors.contains(RecurringDraftError.nameTooLong)) {
        return l10n.recurringNameTooLong;
      }
      return null;
    }

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
              _editing
                  ? l10n.recurringFormEditTitle
                  : l10n.recurringFormNewTitle,
              style: textTheme.headlineSmall?.copyWith(fontSize: 22),
            ),
          ),
          Text(l10n.recurringFormName, style: label),
          TextField(
            controller: _name,
            autofocus: !_editing && widget.initial == null,
            textCapitalization: TextCapitalization.sentences,
            maxLength: RecurringDraft.maxNameLength,
            decoration: field(
              hint: l10n.recurringFormNameHint,
              error: nameError(),
            ),
          ),
          Text(l10n.recurringFormKeyword, style: label),
          TextField(
            controller: _keyword,
            textCapitalization: TextCapitalization.characters,
            maxLength: RecurringDraft.maxKeywordLength,
            decoration: field(
              hint: l10n.recurringFormKeywordHint,
              error: _errors.contains(RecurringDraftError.keywordInvalid)
                  ? l10n.recurringKeywordInvalid
                  : null,
            ),
          ),
          Text(
            l10n.recurringFormKeywordHelp,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(l10n.recurringFormAmount, style: label),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const <TextInputFormatter>[CopInputFormatter()],
            style: amountTextStyle.copyWith(fontSize: 24),
            decoration: field(
              prefix: const Icon(Icons.attach_money_rounded),
              error: _errors.contains(RecurringDraftError.amountRequired)
                  ? l10n.recurringAmountRequired
                  : null,
            ),
          ),
          _PickerRow(
            title: l10n.recurringFormDay,
            value: _draft.dayOfMonth == 0
                ? '—'
                : l10n.recurringFormDayValue(_draft.dayOfMonth),
            hint: _draft.dayOfMonth >= 29
                ? l10n.recurringFormDayShortMonth
                : null,
            error: _errors.contains(RecurringDraftError.dayInvalid)
                ? l10n.recurringDayInvalid
                : null,
            onTap: _busy ? null : () => unawaited(_pickDay()),
          ),
          Text(l10n.recurringFormTolerance, style: label),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final pct in toleranceChoices)
                ChoiceChip(
                  label: Text(l10n.recurringFormToleranceValue(pct)),
                  selected: _draft.tolerancePct == pct,
                  onSelected: (_) => setState(
                    () => _draft = _draft.copyWith(tolerancePct: pct),
                  ),
                ),
            ],
          ),
          Text(
            l10n.recurringFormToleranceHelp,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          _PickerRow(
            title: l10n.recurringFormCategory,
            value: categoryName,
            onTap: _busy ? null : () => unawaited(_pickCategory()),
          ),
          _PickerRow(
            title: l10n.recurringFormAccount,
            value: accountName,
            onTap: _busy ? null : () => unawaited(_pickAccount()),
          ),
          Text(l10n.recurringFormRemind, style: label),
          SegmentedButton<int>(
            segments: [
              for (final days in const [1, 2])
                ButtonSegment(
                  value: days,
                  label: Text(l10n.recurringFormRemindDays(days)),
                ),
            ],
            selected: {_draft.remindDaysBefore},
            onSelectionChanged: (value) => setState(
              () => _draft = _draft.copyWith(remindDaysBefore: value.first),
            ),
          ),
          if (failure != null)
            InlineNotice(
              message: recurringFailureMessage(l10n, failure),
              tone: NoticeTone.error,
            ),
          const SizedBox(height: Space.xs),
          Row(
            spacing: Space.sm,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: Text(l10n.recurringFormCancel),
                ),
              ),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _busy ? null : () => unawaited(_save()),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.recurringFormSave),
                ),
              ),
            ],
          ),
          if (existing != null) ...[
            OutlinedButton(
              onPressed: _busy ? null : () => unawaited(_toggleActive()),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(minTouchTarget),
              ),
              child: Text(
                existing.active
                    ? l10n.recurringFormPause
                    : l10n.recurringFormResume,
              ),
            ),
            TextButton.icon(
              onPressed: _busy ? null : () => unawaited(_delete()),
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              label: Text(
                l10n.recurringFormDelete,
                style: TextStyle(color: scheme.error),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(minTouchTarget),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.title,
    required this.value,
    required this.onTap,
    this.hint,
    this.error,
  });

  final String title;
  final String value;
  final String? hint;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brand = context.lukaColors;
    final error = this.error;
    final hint = this.hint;
    return Material(
      color: brand.tile,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.rowAll,
        side: BorderSide(color: error != null ? scheme.error : scheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                    spacing: 2,
                    children: [
                      Text(
                        title,
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        value,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hint != null)
                        Text(
                          hint,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      if (error != null)
                        Text(
                          error,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.error,
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
    );
  }
}

/// Selector del día de pago (1–31), 7 por fila con áreas de 48 dp.
class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.selected, required this.title});

  final int selected;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, 10, Space.lg, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.sm,
          children: [
            const SheetHandle(),
            Semantics(
              header: true,
              child: Text(
                title,
                style: textTheme.headlineSmall?.copyWith(fontSize: 22),
              ),
            ),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Space.xxs,
              crossAxisSpacing: Space.xxs,
              children: [
                for (var day = 1; day <= 31; day++)
                  _DayChoice(
                    day: day,
                    selected: day == selected,
                    scheme: scheme,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChoice extends StatelessWidget {
  const _DayChoice({
    required this.day,
    required this.selected,
    required this.scheme,
  });

  final int day;
  final bool selected;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? scheme.primary : context.lukaColors.tile,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(day),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: minTouchTarget,
            minHeight: minTouchTarget,
          ),
          child: Center(
            child: Text(
              '$day',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? scheme.onPrimary : null,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Borrador de "Crear gasto fijo con esto" (spec 008 §3.8): nombre y
/// palabra clave del comercio, monto, día (el de la fecha en Colombia) y
/// categoría del movimiento.
RecurringDraft recurringDraftFrom(TransactionView tx) {
  final merchant = tx.merchant ?? '';
  return RecurringDraft(
    name: merchant,
    merchantKeyword: merchant,
    expectedAmount: tx.amount,
    dayOfMonth: toColombiaLocal(tx.occurredAt).day,
    categoryId: tx.categoryId,
  );
}
