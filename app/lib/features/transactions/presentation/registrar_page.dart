import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/widgets/inline_notice.dart';
import 'package:luka/features/accounts/presentation/account_picker_sheet.dart';
import 'package:luka/features/categories/presentation/category_visuals.dart';
import 'package:luka/features/nfc/application/nfc_actions.dart';
import 'package:luka/features/nfc/domain/nfc_ports.dart';
import 'package:luka/features/nfc/presentation/nfc_format.dart';
import 'package:luka/features/review/presentation/widgets/review_format.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/application/transaction_actions.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/category_fit.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/domain/manual_draft.dart';
import 'package:luka/features/transactions/presentation/widgets/category_icon.dart';
import 'package:luka/features/transactions/presentation/widgets/category_sheet.dart';
import 'package:luka/features/transactions/presentation/widgets/offline_banner.dart';
import 'package:luka/features/transactions/presentation/widgets/registrar_form.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_row.dart';

/// "Registrar" (spec 008 §3.4, AC-4.4; diseño Y2): un gasto o ingreso a
/// mano. El interruptor Gasto / Ingreso tiñe el monto y la categoría, y la
/// hoja de categorías solo ofrece las de ese tipo. Va por el outbox, así que
/// funciona sin red; al guardar avisa con "Deshacer" y deja el formulario
/// limpio.
class RegistrarPage extends ConsumerStatefulWidget {
  const RegistrarPage({super.key});

  @override
  ConsumerState<RegistrarPage> createState() => _RegistrarPageState();
}

class _RegistrarPageState extends ConsumerState<RegistrarPage>
    with SingleTickerProviderStateMixin {
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

  /// Lo recién guardado: aterriza arriba del formulario y se desvanece solo
  /// (momento de logro; el aviso de abajo ofrece "Deshacer").
  _Saved? _saved;
  late final AnimationController _savedAnimation;

  @override
  void initState() {
    super.initState();
    // Se crea aquí y no perezoso: crearlo por primera vez en dispose()
    // buscaría el TickerMode de un árbol ya desmontado.
    _savedAnimation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2400),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _saved = null);
          }
        });
  }

  @override
  void dispose() {
    _savedAnimation.dispose();
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

  /// iOS: lee un tag en primer plano y abre su registro rápido (spec 006
  /// §5). En Android el tag abre la app solo.
  Future<void> _readNfc() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final uri = await ref.read(nfcServiceProvider).readUri();
      final location = uri == null ? null : quickAddLocation(uri);
      if (location == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.registerReadNfcUnknown)),
        );
        return;
      }
      unawaited(router.push(location));
    } on NfcFailure catch (failure) {
      if (failure is NfcCancelled) return;
      messenger.showSnackBar(
        SnackBar(content: Text(nfcFailureMessage(l10n, failure))),
      );
    }
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
      _saved = (
        merchant: draft.merchant?.trim() ?? '',
        category: _categoryName,
        amount: draft.amount!,
        direction: draft.direction,
      );
      _reset();
    });
    unawaited(_savedAnimation.forward(from: 0));
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
    final categories =
        ref.watch(transactionCategoriesProvider).value ??
        const <CategoryOption>[];
    final category = categories.where((c) => c.id == _categoryId).firstOrNull;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: ListView(
          // La barra translúcida va encima: su alto entra en el margen.
          padding: EdgeInsets.fromLTRB(
            Space.md,
            18,
            Space.md,
            Space.xl + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Space.sm,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.navRegisterLabel,
                          style: textTheme.headlineLarge?.copyWith(
                            fontSize: 34,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),
                      Text(
                        l10n.registerSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ref.watch(nfcManualReadProvider))
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => unawaited(_readNfc()),
                    icon: const Icon(Icons.nfc_rounded, size: 18),
                    label: Text(l10n.registerReadNfc),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, minTouchTarget),
                      shape: const StadiumBorder(),
                      side: BorderSide(color: context.lukaColors.hairline),
                    ),
                  ),
              ],
            ),
            if (offline) ...[
              const SizedBox(height: Space.md),
              OfflineBanner(message: l10n.registerOfflineBanner),
            ],
            if (_saved case final saved?) ...[
              const SizedBox(height: Space.md),
              _SavedCard(saved: saved, animation: _savedAnimation),
            ],
            const SizedBox(height: 20),
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
              now: _now(),
              merchant: _merchant,
              notes: _notes,
              accountName: _accountName,
              onPickDate: () => unawaited(_pickDate()),
              onPickTime: () => unawaited(_pickTime()),
              onPickAccount: () => unawaited(_pickAccount()),
            ),
            const SizedBox(height: 22),
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
                minimumSize: const Size.fromHeight(58),
                shape: const StadiumBorder(),
                textStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(l10n.registerSave),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _Saved = ({
  String merchant,
  String? category,
  Cop amount,
  TxDirection direction,
});

/// El movimiento recién guardado: aterriza (baja 24 px y crece de 0.96 a 1
/// en el primer 15 % de la animación) y se desvanece en el último 15 %. Con
/// "reducir movimiento" solo aparece y desaparece.
class _SavedCard extends StatelessWidget {
  const _SavedCard({required this.saved, required this.animation});

  final _Saved saved;
  final Animation<double> animation;

  static const _land = Interval(0, 0.15, curve: Cubic(0.23, 1, 0.32, 1));
  static const _fade = Interval(0.85, 1, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final still = MediaQuery.disableAnimationsOf(context);
    final expense = saved.direction == TxDirection.debit;
    final detail = [
      if (saved.merchant.isNotEmpty) saved.merchant,
      saved.category ?? l10n.txNoCategory,
    ].join(' · ');
    final amount = formatCop(
      saved.amount,
      sign: expense ? AmountSign.negative : AmountSign.positive,
    );

    final card = Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: brand.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: brand.hairline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E5C1A10),
              blurRadius: 24,
              spreadRadius: -8,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          spacing: Space.sm,
          children: [
            const DedupeSeal(size: 36),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.registerSavedCardTitle,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: textTheme.titleMedium?.copyWith(
                color: expense ? brand.expense : brand.income,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final land = still ? 1.0 : _land.transform(animation.value);
        final fade = 1 - _fade.transform(animation.value);
        return Opacity(
          opacity: (land * fade).clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -24 * (1 - land)),
            child: Transform.scale(scale: 0.96 + 0.04 * land, child: child),
          ),
        );
      },
      child: card,
    );
  }
}
