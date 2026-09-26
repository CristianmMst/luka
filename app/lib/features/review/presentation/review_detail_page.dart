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
import 'package:finanzia/features/transactions/presentation/widgets/transaction_form_card.dart';
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
    if (!mounted) return;
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
        TransactionFormCard(
          amount: _amount,
          merchant: _merchant,
          direction: _direction,
          occurredAt: _occurredAt,
          categoryName: _categoryName,
          amountError: _errors.contains(ReviewDraftError.amountRequired)
              ? l10n.reviewAmountRequired
              : null,
          directionError: _errors.contains(ReviewDraftError.directionRequired)
              ? l10n.reviewDirectionRequired
              : null,
          dateError: _errors.contains(ReviewDraftError.occurredAtRequired)
              ? l10n.reviewDateRequired
              : null,
          dateHint: _dateFromReceived ? l10n.reviewDateFromReceived : null,
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

/// Encabezado del mensaje y su texto, seleccionable, con los montos
/// resaltados; debajo, los montos como botones de 48 dp en una fila que se
/// desplaza de lado. Un texto largo se muestra recortado hasta que se pide
/// completo: así el formulario queda cerca y no hay un desplazamiento
/// vertical dentro de otro.
class _MessageCard extends StatefulWidget {
  const _MessageCard({required this.item, required this.onAmount});

  final ReviewItem item;
  final ValueChanged<Cop> onAmount;

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard> {
  /// Alto del texto recortado.
  static const _collapsedHeight = 320.0;

  var _expanded = false;
  var _overflows = false;

  bool _onMetrics(ScrollMetricsNotification notification) {
    final overflows = notification.metrics.maxScrollExtent > 0;
    if (overflows != _overflows) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _overflows = overflows);
      });
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
    final item = widget.item;
    final text = item.text;
    final amounts = text == null ? const <Cop>[] : distinctAmounts(text);
    final highlighted = text == null
        ? null
        : _HighlightedText(text: text, onAmount: widget.onAmount);

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
            if (highlighted == null)
              Text(
                l10n.reviewNoText,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else if (_expanded)
              highlighted
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: _collapsedHeight),
                // Solo recorta: no se desplaza por dentro.
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: _onMetrics,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: highlighted,
                  ),
                ),
              ),
            if (highlighted != null && (_overflows || _expanded))
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, minTouchTarget),
                  ),
                  child: Text(
                    _expanded
                        ? l10n.reviewShowLessMessage
                        : l10n.reviewShowFullMessage,
                  ),
                ),
              ),
            if (amounts.isNotEmpty) ...[
              Text(l10n.reviewAmountsHint, style: muted),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: Space.xs,
                  children: [
                    for (final amount in amounts)
                      _AmountChip(
                        amount: amount,
                        onTap: () => widget.onAmount(amount),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// El texto con los montos tocables. Crea sus reconocedores de toque una
/// vez, los rehace solo si cambia el texto y los libera al salir.
class _HighlightedText extends StatefulWidget {
  const _HighlightedText({required this.text, required this.onAmount});

  final String text;
  final ValueChanged<Cop> onAmount;

  @override
  State<_HighlightedText> createState() => _HighlightedTextState();
}

class _HighlightedTextState extends State<_HighlightedText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _buildRecognizers();
  }

  @override
  void didUpdateWidget(_HighlightedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeRecognizers();
      _buildRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _buildRecognizers() {
    for (final amount in highlightedAmounts(widget.text.trim())) {
      // Lee `widget` al tocar: el callback puede cambiar sin cambiar el
      // texto.
      _recognizers.add(
        TapGestureRecognizer()..onTap = () => widget.onAmount(amount),
      );
    }
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SelectionArea(
      child: Text.rich(
        TextSpan(
          children: highlightedSpans(
            l10n,
            widget.text.trim(),
            highlightStyle(scheme),
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
