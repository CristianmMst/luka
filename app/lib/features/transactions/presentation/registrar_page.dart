import 'dart:async';

import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/core/widgets/inline_notice.dart';
import 'package:finanzia/features/accounts/presentation/account_picker_sheet.dart';
import 'package:finanzia/features/review/presentation/widgets/review_format.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/application/transaction_actions.dart';
import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/domain/manual_draft.dart';
import 'package:finanzia/features/transactions/presentation/widgets/category_sheet.dart';
import 'package:finanzia/features/transactions/presentation/widgets/offline_banner.dart';
import 'package:finanzia/features/transactions/presentation/widgets/transaction_form_card.dart';
import 'package:finanzia/features/transactions/presentation/widgets/transaction_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Registrar" (spec 008 §3.4, AC-4.4; diseño A "Formulario en tarjeta",
/// F4.5a): un gasto o ingreso a mano. Va por el outbox, así que funciona
/// sin red; al guardar avisa con "Deshacer" y deja el formulario limpio.
class RegistrarPage extends ConsumerStatefulWidget {
  const RegistrarPage({super.key});

  @override
  ConsumerState<RegistrarPage> createState() => _RegistrarPageState();
}

class _RegistrarPageState extends ConsumerState<RegistrarPage> {
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _notes = TextEditingController();
  TxDirection _direction = TxDirection.debit;
  late DateTime _occurredAt = _now();

  /// La fecha la eligió el usuario: no se mueve sola a "ahora".
  var _dateTouched = false;
  String? _categoryId;
  String? _categoryName;
  String? _accountId;
  String? _accountName;
  Set<ManualDraftError> _errors = const {};
  var _saveFailed = false;
  var _busy = false;

  DateTime _now() => ref.read(transactionsClockProvider)().toUtc();

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _reset() {
    _amount.clear();
    _merchant.clear();
    _notes.clear();
    _direction = TxDirection.debit;
    _occurredAt = _now();
    _dateTouched = false;
    _categoryId = null;
    _categoryName = null;
    _accountId = null;
    _accountName = null;
    _errors = const {};
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
      _dateTouched = true;
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
      _dateTouched = true;
    });
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

  Future<void> _save() async {
    final draft = ManualDraft(
      // Sin tocar la fecha, el movimiento es de cuando se guarda.
      occurredAt: _dateTouched ? _occurredAt : _now(),
      amount: parseCopInput(_amount.text),
      direction: _direction,
      merchant: _merchant.text,
      categoryId: _categoryId,
      notes: _notes.text,
      accountId: _accountId,
    );
    final errors = draft.validate();
    setState(() {
      _errors = errors;
      _saveFailed = false;
    });
    if (errors.isNotEmpty) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(transactionActionsProvider);
    final offline = ref.read(syncCoordinatorProvider).offline;
    setState(() => _busy = true);
    final String localId;
    try {
      localId = await actions.create(draft);
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _saveFailed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _reset();
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(offline ? l10n.registerSavedOffline : l10n.registerSaved),
        action: SnackBarAction(
          label: l10n.registerUndo,
          onPressed: () => unawaited(() async {
            await actions.delete(localId);
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.registerUndone)),
            );
          }()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final offline = ref.watch(
      syncCoordinatorProvider.select((s) => s.offline),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.md,
            Space.screen,
            Space.xl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.navRegisterLabel,
                style: textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: Space.xxs),
            Text(
              l10n.registerSubtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            if (offline) ...[
              OfflineBanner(message: l10n.registerOfflineBanner),
              const SizedBox(height: Space.md),
            ],
            TransactionFormCard(
              amount: _amount,
              merchant: _merchant,
              notes: _notes,
              direction: _direction,
              occurredAt: _occurredAt,
              categoryName: _categoryName,
              amountError: _errors.contains(ManualDraftError.amountRequired)
                  ? l10n.registerAmountRequired
                  : null,
              onAmountChanged: () {
                if (_errors.isNotEmpty) setState(() => _errors = const {});
              },
              onDirection: (direction) =>
                  setState(() => _direction = direction),
              onPickDate: () => unawaited(_pickDate()),
              onPickTime: () => unawaited(_pickTime()),
              onPickCategory: () => unawaited(_pickCategory()),
              accountName: _accountName,
              onPickAccount: () => unawaited(_pickAccount()),
            ),
            const SizedBox(height: Space.lg),
            if (_saveFailed) ...[
              InlineNotice(
                message: l10n.registerSaveError,
                tone: NoticeTone.error,
              ),
              const SizedBox(height: Space.sm),
            ],
            FilledButton(
              onPressed: _busy ? null : () => unawaited(_save()),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(l10n.registerSave),
            ),
          ],
        ),
      ),
    );
  }
}
