import 'dart:async';

import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/routing/routes.dart';
import 'package:finanzia/core/theme/finanzia_colors.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/core/theme/tokens/type_tokens.dart';
import 'package:finanzia/core/widgets/inline_notice.dart';
import 'package:finanzia/features/review/application/review_actions.dart';
import 'package:finanzia/features/review/application/review_providers.dart';
import 'package:finanzia/features/review/domain/review_draft.dart';
import 'package:finanzia/features/review/domain/review_item.dart';
import 'package:finanzia/features/review/presentation/widgets/review_card.dart';
import 'package:finanzia/features/review/presentation/widgets/review_format.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/presentation/widgets/category_sheet.dart';
import 'package:finanzia/features/transactions/presentation/widgets/transaction_format.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Detalle de un mensaje en revisión (spec 008 §3.5, AC-8.1): el texto
/// completo con los montos resaltados y el formulario prellenado para
/// crear el movimiento, o descartar el mensaje.
class ReviewDetailPage extends ConsumerStatefulWidget {
  const ReviewDetailPage({required this.rawMessageId, super.key});

  final String rawMessageId;

  @override
  ConsumerState<ReviewDetailPage> createState() => _ReviewDetailPageState();
}

class _ReviewDetailPageState extends ConsumerState<ReviewDetailPage> {
  /// Último mensaje visto. Mientras se convierte o descarta se sigue
  /// mostrando: el outbox borra la fila (optimista) antes de volver.
  ReviewItem? _last;
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(reviewItemProvider(widget.rawMessageId));
    if (state.value case final item?) _last = item;
    final item = state.value ?? (_busy ? _last : null);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopBar(),
            Expanded(
              child: switch (state) {
                _ when item != null => _ReviewForm(
                  key: ValueKey(item.rawMessageId),
                  item: item,
                  onBusy: (busy) => setState(() => _busy = busy),
                ),
                AsyncData() => _Message(l10n.reviewNotFound),
                AsyncError() => _Message(l10n.reviewLoadError),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Vuelve a la lista (o la abre, si se llegó por deep link).
void _back(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(Routes.review);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
      child: Row(
        spacing: Space.xxs,
        children: [
          IconButton(
            tooltip: l10n.detailBack,
            onPressed: () => _back(context),
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
          ),
          Semantics(
            header: true,
            child: Text(
              l10n.reviewDetailTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({required this.item, required this.onBusy, super.key});

  final ReviewItem item;
  final ValueChanged<bool> onBusy;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  late final ReviewDraft _initial = ReviewDraft.fromPartialExtract(
    widget.item.partialExtract,
  );
  late final _amount = TextEditingController(
    text: switch (_initial.amount) {
      final amount? => copInputText(amount),
      null => '',
    },
  );
  late final _merchant = TextEditingController(text: _initial.merchant ?? '');
  late TxDirection? _direction = _initial.direction;

  /// Sin fecha extraída se propone la de recepción, visible y editable.
  late DateTime _occurredAt = _initial.occurredAt ?? widget.item.receivedAt;
  late bool _dateFromReceived = _initial.occurredAt == null;
  String? _categoryId;
  String? _categoryName;
  Set<ReviewDraftError> _errors = const {};
  var _busy = false;
  var _saveFailed = false;

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    super.dispose();
  }

  ReviewDraft get _draft => ReviewDraft(
    amount: parseCopInput(_amount.text),
    direction: _direction,
    occurredAt: _occurredAt,
    merchant: _merchant.text,
    categoryId: _categoryId,
  );

  void _clearError(ReviewDraftError error) {
    if (_errors.contains(error)) {
      setState(() => _errors = {..._errors}..remove(error));
    }
  }

  void _useAmount(Cop amount) {
    _amount.text = copInputText(amount);
    _clearError(ReviewDraftError.amountRequired);
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
      _dateFromReceived = false;
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
      _dateFromReceived = false;
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

  Future<void> _convert() async {
    final draft = _draft;
    final errors = draft.validate();
    setState(() {
      _errors = errors;
      _saveFailed = false;
    });
    if (errors.isNotEmpty) return;
    final l10n = AppLocalizations.of(context);
    await _run(
      () => ref.read(reviewActionsProvider).convert(widget.item, draft),
      l10n.reviewConverted,
    );
  }

  Future<void> _discard() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reviewDiscardTitle),
        content: Text(l10n.reviewDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.reviewDiscardCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.reviewDiscardConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saveFailed = false);
    await _run(
      () => ref.read(reviewActionsProvider).discard(widget.item),
      l10n.reviewDiscarded,
    );
  }

  /// Corre [action] y, si sale bien, vuelve a la lista con [done].
  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    widget.onBusy(true);
    try {
      await action();
    } on InvalidReviewDraft catch (e) {
      _failed(errors: e.errors);
      return;
    } on Object {
      _failed(saveFailed: true);
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(done)));
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.review);
    }
  }

  void _failed({
    Set<ReviewDraftError> errors = const {},
    bool saveFailed = false,
  }) {
    if (!mounted) return;
    widget.onBusy(false);
    setState(() {
      _busy = false;
      _errors = errors;
      _saveFailed = saveFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final item = widget.item;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xl),
      children: [
        _MessageCard(item: item, onAmount: _useAmount),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xxs, 22, Space.xxs, 10),
          child: Semantics(
            header: true,
            child: Text(
              l10n.reviewFormTitle,
              style: textTheme.headlineSmall?.copyWith(fontSize: 22),
            ),
          ),
        ),
        _FormCard(
          amount: _amount,
          merchant: _merchant,
          direction: _direction,
          occurredAt: _occurredAt,
          dateFromReceived: _dateFromReceived,
          categoryName: _categoryName,
          errors: _errors,
          onAmountChanged: () => _clearError(ReviewDraftError.amountRequired),
          onDirection: (direction) {
            setState(() => _direction = direction);
            _clearError(ReviewDraftError.directionRequired);
          },
          onPickDate: () => unawaited(_pickDate()),
          onPickTime: () => unawaited(_pickTime()),
          onPickCategory: () => unawaited(_pickCategory()),
        ),
        const SizedBox(height: Space.lg),
        if (_saveFailed)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: InlineNotice(
              message: l10n.reviewSaveError,
              tone: NoticeTone.error,
            ),
          ),
        FilledButton(
          onPressed: _busy ? null : () => unawaited(_convert()),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.reviewConvert),
        ),
        const SizedBox(height: Space.xs),
        TextButton(
          onPressed: _busy ? null : () => unawaited(_discard()),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(minTouchTarget),
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: Text(l10n.reviewDiscard),
        ),
      ],
    );
  }
}

/// Encabezado del mensaje y su texto completo, seleccionable, con los
/// montos resaltados; debajo, los montos como botones de 48 dp.
class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.item, required this.onAmount});

  final ReviewItem item;
  final ValueChanged<Cop> onAmount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
    final text = item.text;
    final amounts = text == null ? const <Cop>[] : distinctAmounts(text);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.finanziaColors.card,
        borderRadius: Radii.cardAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.sm,
          children: [
            ReviewHeader(item: item),
            Text(l10n.reviewMessageLabel, style: muted),
            if (text != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: _HighlightedText(text: text, onAmount: onAmount),
                  ),
                ),
              )
            else
              Text(
                l10n.reviewNoText,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            if (amounts.isNotEmpty) ...[
              Text(l10n.reviewAmountsHint, style: muted),
              Wrap(
                spacing: Space.xs,
                children: [
                  for (final amount in amounts)
                    _AmountChip(amount: amount, onTap: () => onAmount(amount)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// El texto con los montos tocables. Maneja sus reconocedores de toque.
class _HighlightedText extends StatefulWidget {
  const _HighlightedText({required this.text, required this.onAmount});

  final String text;
  final ValueChanged<Cop> onAmount;

  @override
  State<_HighlightedText> createState() => _HighlightedTextState();
}

class _HighlightedTextState extends State<_HighlightedText> {
  final _recognizers = <GestureRecognizer>[];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    _disposeRecognizers();

    return SelectionArea(
      child: Text.rich(
        TextSpan(
          children: highlightedSpans(
            l10n,
            widget.text.trim(),
            highlightStyle(scheme),
            onAmount: widget.onAmount,
            recognizers: _recognizers,
          ),
        ),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.amount, required this.onTap});

  final Cop amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: l10n.reviewUseAmountSemantics(spokenAmount(amount)),
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.chipAll,
        child: SizedBox(
          height: minTouchTarget,
          child: Center(
            widthFactor: 1,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: Space.sm),
              decoration: BoxDecoration(
                borderRadius: Radii.chipAll,
                color: scheme.primaryContainer,
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  formatCop(amount, withDecimals: amount.cents % 100 != 0),
                  style: amountTextStyle.copyWith(
                    fontSize: 14,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.amount,
    required this.merchant,
    required this.direction,
    required this.occurredAt,
    required this.dateFromReceived,
    required this.categoryName,
    required this.errors,
    required this.onAmountChanged,
    required this.onDirection,
    required this.onPickDate,
    required this.onPickTime,
    required this.onPickCategory,
  });

  final TextEditingController amount;
  final TextEditingController merchant;
  final TxDirection? direction;
  final DateTime occurredAt;
  final bool dateFromReceived;
  final String? categoryName;
  final Set<ReviewDraftError> errors;
  final VoidCallback onAmountChanged;
  final ValueChanged<TxDirection> onDirection;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onPickCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.finanziaColors;
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final muted = textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
    final error = textTheme.bodySmall?.copyWith(color: scheme.error);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: Radii.noticeAll,
          borderSide: BorderSide(color: color, width: width),
        );
    InputDecoration decoration({String? hint, String? errorText}) =>
        InputDecoration(
          hintText: hint,
          hintStyle: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          errorText: errorText,
          filled: true,
          fillColor: brand.tile,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: Space.sm,
          ),
          enabledBorder: border(scheme.outline),
          focusedBorder: border(scheme.primary, 2),
          errorBorder: border(scheme.error),
          focusedErrorBorder: border(scheme.error, 2),
        );
    final amountColor = switch (direction) {
      TxDirection.debit => brand.expense,
      TxDirection.credit => brand.income,
      null => scheme.onSurface,
    };
    final amountStyle = amountTextStyle.copyWith(
      fontSize: 28,
      color: amountColor,
    );

    return DecoratedBox(
      decoration: BoxDecoration(color: brand.card, borderRadius: Radii.cardAll),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.xs,
          children: [
            Text(l10n.reviewAmountLabel, style: label),
            TextField(
              controller: amount,
              onChanged: (_) => onAmountChanged(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [CopInputFormatter()],
              style: amountStyle,
              decoration:
                  decoration(
                    errorText: errors.contains(ReviewDraftError.amountRequired)
                        ? l10n.reviewAmountRequired
                        : null,
                  ).copyWith(
                    hintText: '0',
                    hintStyle: amountStyle.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 6),
                      child: Text(r'$', style: amountStyle),
                    ),
                    prefixIconConstraints: const BoxConstraints(),
                  ),
            ),
            const SizedBox(height: Space.xs),
            SegmentedButton<TxDirection>(
              segments: [
                ButtonSegment(
                  value: TxDirection.debit,
                  label: Text(l10n.detailKindExpense),
                  icon: const Icon(Icons.north_east_rounded, size: 18),
                ),
                ButtonSegment(
                  value: TxDirection.credit,
                  label: Text(l10n.detailKindIncome),
                  icon: const Icon(Icons.south_west_rounded, size: 18),
                ),
              ],
              selected: {?direction},
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) onDirection(selection.first);
              },
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(0, minTouchTarget),
                selectedBackgroundColor: scheme.primaryContainer,
                selectedForegroundColor: scheme.onPrimaryContainer,
              ),
            ),
            if (errors.contains(ReviewDraftError.directionRequired))
              Semantics(
                liveRegion: true,
                child: Text(l10n.reviewDirectionRequired, style: error),
              ),
            const SizedBox(height: Space.xs),
            Row(
              spacing: Space.xs,
              children: [
                Expanded(
                  child: _PickerTile(
                    label: l10n.reviewDateLabel,
                    value: longDate(occurredAt),
                    onTap: onPickDate,
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: _PickerTile(
                    label: l10n.reviewTimeLabel,
                    value: timeOfDay(occurredAt),
                    onTap: onPickTime,
                  ),
                ),
              ],
            ),
            if (errors.contains(ReviewDraftError.occurredAtRequired))
              Text(l10n.reviewDateRequired, style: error)
            else if (dateFromReceived)
              Text(l10n.reviewDateFromReceived, style: muted),
            const SizedBox(height: Space.xs),
            Text(l10n.reviewMerchantLabel, style: label),
            TextField(
              controller: merchant,
              textCapitalization: TextCapitalization.words,
              style: textTheme.bodyMedium,
              decoration: decoration(hint: l10n.reviewMerchantHint),
            ),
            const SizedBox(height: Space.xs),
            Row(
              children: [
                Expanded(child: Text(l10n.detailCategory, style: label)),
                _CategoryButton(
                  label: categoryName ?? l10n.txNoCategory,
                  onTap: onPickCategory,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fecha u hora del formulario: botón de 56 dp que abre su selector.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: l10n.reviewChangeSemantics(label, value),
      onTap: onTap,
      child: Material(
        color: context.finanziaColors.tile,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.noticeAll,
          side: BorderSide(color: scheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.sm,
                vertical: Space.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip de categoría de 36 dp en un área táctil de 48 dp; abre la hoja.
class _CategoryButton extends StatelessWidget {
  const _CategoryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final foreground = scheme.onPrimaryContainer;

    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      label: l10n.txChangeCategorySemantics(label),
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.chipAll,
        child: SizedBox(
          height: minTouchTarget,
          child: Center(
            widthFactor: 1,
            child: Container(
              height: 36,
              padding: const EdgeInsets.only(left: Space.sm, right: Space.xs),
              decoration: BoxDecoration(
                borderRadius: Radii.chipAll,
                color: scheme.primaryContainer,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: Space.xxs,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                  Icon(Icons.expand_more_rounded, size: 16, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
