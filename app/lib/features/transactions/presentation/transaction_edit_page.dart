import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/widgets/inline_notice.dart';
import 'package:luka/features/accounts/presentation/account_picker_sheet.dart';
import 'package:luka/features/categories/presentation/category_visuals.dart';
import 'package:luka/features/review/presentation/widgets/review_format.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/application/transaction_actions.dart';
import 'package:luka/features/transactions/application/transaction_detail_controller.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/category_fit.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/domain/manual_draft.dart';
import 'package:luka/features/transactions/domain/transaction_edit.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';
import 'package:luka/features/transactions/presentation/widgets/category_icon.dart';
import 'package:luka/features/transactions/presentation/widgets/category_sheet.dart';
import 'package:luka/features/transactions/presentation/widgets/merchant_rule_dialog.dart';
import 'package:luka/features/transactions/presentation/widgets/registrar_form.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// "Editar movimiento" (spec 008 §3.3): el formulario de Registrar con los
/// datos del movimiento (tipo, monto, categoría, fecha, hora, comercio y
/// cuenta). Guarda un solo `PATCH` con lo que cambió, por el outbox, así que
/// funciona sin red. En una transferencia emparejada el monto y el tipo no
/// se tocan: primero hay que desmarcarla.
class TransactionEditPage extends ConsumerWidget {
  const TransactionEditPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tx = ref.watch(transactionDetailControllerProvider(id)).tx;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xs),
              child: Row(
                spacing: Space.xxs,
                children: [
                  IconButton(
                    tooltip: l10n.detailBack,
                    onPressed: () => _close(context),
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  ),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.editTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (tx) {
                AsyncData(value: final tx?) => _EditForm(
                  key: ValueKey('edit-${tx.id}'),
                  tx: tx,
                ),
                AsyncData() => Center(child: Text(l10n.detailNotFound)),
                AsyncError() => Center(child: Text(l10n.detailLoadError)),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _close(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(Routes.transactions);
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.tx, super.key});

  /// El movimiento tal como estaba al abrir: los cambios se miden contra él.
  final TransactionView tx;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final TransactionView _original = widget.tx;
  late final _amount = TextEditingController(
    text: copInputText(_original.amount),
  );
  late final _merchant = TextEditingController(text: _original.merchant);
  late TxDirection _direction = _original.direction;
  late DateTime _occurredAt = _original.occurredAt;
  late String? _categoryId = _original.categoryId;
  late String? _categoryName = _original.categoryName;
  late String? _accountId = _original.accountId;

  /// `null` mientras la cuenta sea la original: se muestra su etiqueta.
  String? _accountName;
  var _accountTouched = false;
  Set<ManualDraftError> _errors = const {};
  var _busy = false;

  /// Transferencia emparejada: el backend no deja cambiar monto ni tipo.
  bool get _paired => _original.transferPairId != null;

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final local = colombiaLocal(_occurredAt);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(local.year, local.month, local.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _occurredAt = colombiaMidnight(
        picked.year,
        picked.month,
        picked.day,
      ).add(Duration(hours: local.hour, minutes: local.minute));
    });
  }

  Future<void> _pickTime() async {
    final local = colombiaLocal(_occurredAt);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: local.hour, minute: local.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _occurredAt = colombiaMidnight(
        local.year,
        local.month,
        local.day,
      ).add(Duration(hours: picked.hour, minutes: picked.minute));
    });
  }

  Future<void> _pickCategory() async {
    final choice = await CategorySheet.show(
      context,
      selectedId: _categoryId,
      direction: _direction,
    );
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
      _accountTouched = true;
    });
  }

  /// Cambia el tipo; la categoría elegida se suelta si no sirve para él.
  void _setDirection(TxDirection direction, List<CategoryOption> categories) {
    setState(() {
      _direction = direction;
      final current = categories.where((c) => c.id == _categoryId).firstOrNull;
      if (current != null && !fitsDirection(current, direction)) {
        _categoryId = null;
        _categoryName = null;
      }
    });
  }

  Future<void> _save() async {
    final edit = TransactionEdit(
      amount: parseCopInput(_amount.text),
      direction: _direction,
      occurredAt: _occurredAt,
      merchant: _merchant.text,
      categoryId: _categoryId,
      accountId: _accountId,
    );
    final errors = edit.validate();
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Como en el chip de categoría: con comercio, se pregunta si la nueva
    // categoría aplica siempre (AC-7.2). Cerrar el diálogo no guarda nada.
    var always = false;
    final merchant = _merchant.text.trim();
    if (edit.categoryChanged(_original) && merchant.isNotEmpty) {
      final answer = await MerchantRuleDialog.show(
        context,
        merchant: merchant,
        categoryName: _categoryName ?? '',
      );
      if (answer == null || !mounted) return;
      always = answer;
    }

    final patch = edit.patchFrom(_original, learnMerchantRule: always);
    if (patch != null) {
      setState(() => _busy = true);
      await ref.read(transactionActionsProvider).edit(_original, patch);
      if (!mounted) return;
    }
    _close(context);
    if (patch != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.editSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final categories =
        ref.watch(transactionCategoriesProvider).value ??
        const <CategoryOption>[];
    final category = categories.where((c) => c.id == _categoryId).firstOrNull;
    final accountName = _accountTouched
        ? _accountName
        : accountLabel(l10n, _original);

    final kindAndAmount = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KindSwitch(
          direction: _direction,
          onChanged: (direction) => _setDirection(direction, categories),
        ),
        const SizedBox(height: 22),
        AmountField(
          controller: _amount,
          direction: _direction,
          error: _errors.contains(ManualDraftError.amountRequired)
              ? l10n.registerAmountRequired
              : null,
          onChanged: () {
            if (_errors.isNotEmpty) setState(() => _errors = const {});
          },
        ),
      ],
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.md,
        Space.xl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (_paired) ...[
          InlineNotice(
            message: l10n.editTransferLocked,
            tone: NoticeTone.info,
          ),
          const SizedBox(height: Space.md),
          // Se ve, pero no se toca (el backend respondería 409).
          ExcludeSemantics(
            child: IgnorePointer(
              child: Opacity(opacity: 0.5, child: kindAndAmount),
            ),
          ),
        ] else
          kindAndAmount,
        const SizedBox(height: 22),
        CategoryField(
          name: _categoryName ?? l10n.txNoCategory,
          icon: category == null
              ? categoryIcon(null)
              : category.isSystem
              ? categoryIcon(category.slug)
              : ownCategoryIcon(category.icon),
          direction: _direction,
          onTap: () => unawaited(_pickCategory()),
        ),
        const SizedBox(height: Space.sm),
        RegistrarDetails(
          occurredAt: _occurredAt,
          now: ref.read(transactionsClockProvider)().toUtc(),
          merchant: _merchant,
          accountName: accountName,
          onPickDate: () => unawaited(_pickDate()),
          onPickTime: () => unawaited(_pickTime()),
          onPickAccount: () => unawaited(_pickAccount()),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _busy ? null : () => unawaited(_save()),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            shape: const StadiumBorder(),
            textStyle: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          child: Text(l10n.editSave),
        ),
      ],
    );
  }
}
