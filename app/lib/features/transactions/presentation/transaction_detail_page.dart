import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/recurring/presentation/recurring_form_sheet.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/application/transaction_actions.dart';
import 'package:luka/features/transactions/application/transaction_detail_controller.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';
import 'package:luka/features/transactions/presentation/widgets/category_icon.dart';
import 'package:luka/features/transactions/presentation/widgets/change_category.dart';
import 'package:luka/features/transactions/presentation/widgets/rejected_banner.dart';
import 'package:luka/features/transactions/presentation/widgets/sources_section.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// Detalle de un movimiento (diseño A "Monto protagonista", spec 008
/// §3.3): monto grande con decimales, campos, fuentes del servidor, par de
/// transferencia, marcar/desmarcar transferencia y notas.
class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = transactionDetailControllerProvider(id);
    final state = ref.watch(provider);
    // Las fuentes se piden al servidor: al volver la red se reintentan.
    ref.listen(syncCoordinatorProvider.select((s) => s.offline), (
      wasOffline,
      offline,
    ) {
      if ((wasOffline ?? false) && !offline) {
        unawaited(ref.read(provider.notifier).refreshSources());
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(
              onEdit: switch (state.tx) {
                AsyncData(value: final tx?) => () => unawaited(
                  GoRouter.of(context).push(Routes.transactionEdit(tx.id)),
                ),
                _ => null,
              },
            ),
            Expanded(
              child: switch (state.tx) {
                AsyncData(value: final tx?) => _DetailBody(
                  tx: tx,
                  sources: state.sources,
                ),
                AsyncData() => _Message(l10n.detailNotFound),
                AsyncError() => _Message(l10n.detailLoadError),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.onEdit});

  /// Abre "Editar movimiento"; `null` mientras el movimiento no cargó.
  final VoidCallback? onEdit;

  void _back(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.transactions);
    }
  }

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
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                l10n.detailTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: l10n.detailEdit,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 22),
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.tx, required this.sources});

  final TransactionView tx;
  final SourcesState sources;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(transactionActionsProvider);
    final isTransfer = tx.kind == TxKind.transfer;
    final pairId = tx.transferPairId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xl),
      children: [
        if (tx.sync == SyncMark.rejected)
          Padding(
            padding: const EdgeInsets.only(top: Space.xxs),
            child: RejectedBanner(
              name: displayName(l10n, tx),
              onRetry: () => unawaited(actions.retryRejected(tx.id)),
              onDiscard: () => unawaited(actions.discardRejected(tx.id)),
            ),
          ),
        _Hero(tx: tx),
        _FieldsCard(
          tx: tx,
          onChangeCategory: () =>
              unawaited(changeCategory(context, actions, tx)),
        ),
        SourcesSection(sources: sources),
        const SizedBox(height: 22),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.sm,
          children: [
            if (isTransfer && pairId != null) _PairCard(pairId: pairId),
            OutlinedButton.icon(
              onPressed: () => unawaited(
                actions.setTransfer(tx, isTransfer: !isTransfer),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              icon: isTransfer
                  ? null
                  : const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text(
                isTransfer
                    ? l10n.detailUnmarkTransfer
                    : l10n.detailMarkTransfer,
              ),
            ),
            if (tx.kind == TxKind.expense)
              OutlinedButton.icon(
                onPressed: () => unawaited(
                  RecurringFormSheet.show(
                    context,
                    initial: recurringDraftFrom(tx),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                icon: const Icon(Icons.event_repeat_rounded, size: 18),
                label: Text(l10n.detailCreateRecurring),
              ),
            _NotesField(key: ValueKey('notes-${tx.id}'), tx: tx),
            TextButton.icon(
              onPressed: () => unawaited(_delete(context, actions)),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(minTouchTarget),
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(l10n.detailDelete),
            ),
          ],
        ),
      ],
    );
  }

  /// Confirma, elimina por el outbox y vuelve a la lista.
  Future<void> _delete(BuildContext context, TransactionActions actions) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.detailDeleteTitle),
        // Una captura deja lápida: otro aviso de la compra no la recrea.
        content: Text(
          tx.parsedBy == 'manual'
              ? l10n.detailDeleteBody
              : l10n.detailDeleteBodyCaptured,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.detailDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.detailDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    await actions.delete(tx.id);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.transactions);
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.detailDeleted)));
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.tx});

  final TransactionView tx;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final muted = scheme.onSurfaceVariant;
    final isTransfer = tx.kind == TxKind.transfer;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.xxs,
        Space.sm,
        Space.xxs,
        Space.lg - Space.xxs,
      ),
      child: Column(
        spacing: Space.xs,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isTransfer
                    ? brand.transfer.withValues(alpha: 0.14)
                    : brand.neutralChip,
              ),
              child: Icon(
                isTransfer ? transferIcon : categoryIcon(tx.categorySlug),
                size: 28,
                color: isTransfer ? brand.transfer : scheme.primary,
              ),
            ),
          ),
          if (isTransfer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: Radii.chipAll,
                color: brand.transfer.withValues(alpha: 0.16),
              ),
              child: Text(
                l10n.detailTransferBadge,
                style: textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.4,
                  color: brand.transfer,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: Space.xxs),
            child: Semantics(
              header: true,
              child: Text(
                displayName(l10n, tx),
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(letterSpacing: -0.4),
              ),
            ),
          ),
          Semantics(
            container: true,
            label: amountSemantics(
              l10n,
              tx.amount,
              tx.kind,
              withDecimals: true,
            ),
            child: ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  detailAmount(tx.amount, tx.kind),
                  maxLines: 1,
                  style: textTheme.displayLarge?.copyWith(
                    fontSize: 48,
                    height: 1.1,
                    letterSpacing: -2,
                    color: amountColor(brand, tx.kind),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          Text(
            longDateTime(tx.occurredAt),
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: muted,
            ),
          ),
          if (isTransfer)
            Text(
              l10n.detailTransferNote,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: muted,
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldsCard extends StatelessWidget {
  const _FieldsCard({required this.tx, required this.onChangeCategory});

  final TransactionView tx;
  final VoidCallback onChangeCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bank = tx.bank;
    final parsedBy = parsedByLabel(l10n, tx.parsedBy);
    final account =
        accountLabel(l10n, tx) ??
        (bank == null ? l10n.detailNoAccount : bankLabel(l10n, bank));
    final kind = switch (tx.kind) {
      TxKind.expense => l10n.detailKindExpense,
      TxKind.income => l10n.detailKindIncome,
      TxKind.transfer => l10n.detailKindTransfer,
    };

    final rows = <Widget>[
      _FieldRow(
        label: l10n.detailCategory,
        minHeight: 56,
        child: _CategoryButton(
          label: tx.categoryName ?? l10n.txNoCategory,
          onTap: onChangeCategory,
        ),
      ),
      _FieldRow(label: l10n.detailAccount, value: account),
      _FieldRow(label: l10n.detailKind, value: kind),
      if (parsedBy != null)
        _FieldRow(label: l10n.detailParsedBy, value: parsedBy),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.lukaColors.card,
        borderRadius: Radii.cardAll,
        border: Border.all(color: context.lukaColors.hairline),
      ),
      child: Column(
        children: [
          for (final (index, row) in rows.indexed)
            DecoratedBox(
              decoration: BoxDecoration(
                border: index == 0
                    ? null
                    : Border(
                        top: BorderSide(color: context.lukaColors.hairline),
                      ),
              ),
              child: row,
            ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    this.value,
    this.child,
    this.minHeight = 52,
  });

  final String label;
  final String? value;
  final Widget? child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          child: Row(
            spacing: Space.md,
            children: [
              Text(
                label,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child:
                      child ??
                      Text(
                        value ?? '',
                        textAlign: TextAlign.end,
                        style: textTheme.titleSmall,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip de categoría de 36 dp, en un área táctil de 48 dp; abre la hoja.
class _CategoryButton extends StatelessWidget {
  const _CategoryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = scheme.onSurface;

    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      label: l10n.txChangeCategorySemantics(label),
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.pillAll,
        child: SizedBox(
          height: minTouchTarget,
          child: Center(
            widthFactor: 1,
            child: Container(
              height: 36,
              padding: const EdgeInsets.only(left: Space.sm, right: Space.xs),
              decoration: BoxDecoration(
                borderRadius: Radii.pillAll,
                border: Border.all(color: context.lukaColors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: Space.xxs,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
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

/// "La otra parte" de una transferencia propia (diseño "Estados"): abre el
/// detalle de la pareja.
class _PairCard extends ConsumerWidget {
  const _PairCard({required this.pairId});

  final String pairId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final pair = ref.watch(transactionByIdProvider(pairId)).value;
    final value = pair == null
        ? null
        : l10n.detailPairValue(
            switch (pair.bank) {
              final bank? => bankLabel(l10n, bank),
              null => accountLabel(l10n, pair) ?? displayName(l10n, pair),
            },
            pair.direction == TxDirection.credit ? 'credit' : 'debit',
            timeOfDay(pair.occurredAt),
          );
    void open() =>
        unawaited(GoRouter.of(context).push('${Routes.transactions}/$pairId'));

    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      label: value == null
          ? l10n.detailPairLabel
          : l10n.detailPairSemantics(value),
      onTap: open,
      child: Material(
        color: brand.card,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.noticeAll,
          side: BorderSide(color: brand.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: open,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                spacing: Space.sm,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: brand.transfer.withValues(alpha: 0.16),
                    ),
                    child: Icon(
                      Icons.sync_alt_rounded,
                      size: 20,
                      color: brand.transfer,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          l10n.detailPairLabel,
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (value != null)
                          Text(
                            value,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: scheme.onSurfaceVariant,
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

/// Notas: se guardan con debounce mientras se escribe, al perder el foco y
/// al salir de la pantalla. El contenido nunca se registra en logs.
class _NotesField extends ConsumerStatefulWidget {
  const _NotesField({required this.tx, super.key});

  final TransactionView tx;

  @override
  ConsumerState<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends ConsumerState<_NotesField> {
  static const _debounceDelay = Duration(milliseconds: 800);

  late final TextEditingController _controller = TextEditingController(
    text: widget.tx.notes ?? '',
  );
  final _focus = FocusNode();
  Timer? _debounce;

  /// Se lee aquí: en `dispose` ya no se puede usar `ref`.
  late final TransactionActions _actions;

  /// Última nota guardada (recortada), para no reenviar lo mismo.
  late String _saved = (widget.tx.notes ?? '').trim();

  @override
  void initState() {
    super.initState();
    _actions = ref.read(transactionActionsProvider);
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_NotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sin edición en curso, la nota sigue a la fila (p. ej. tras un pull).
    if (_focus.hasFocus || _debounce != null) return;
    final notes = widget.tx.notes ?? '';
    if (notes.trim() != _controller.text.trim()) _controller.text = notes;
    _saved = notes.trim();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _flush();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) _flush();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, _flush);
  }

  void _flush() {
    _debounce?.cancel();
    _debounce = null;
    final text = _controller.text.trim();
    if (text == _saved) return;
    _saved = text;
    unawaited(_actions.saveNotes(widget.tx, text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: Radii.noticeAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xxs),
          child: Text(
            l10n.detailNotes,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _onChanged,
          onTapOutside: (_) => _focus.unfocus(),
          minLines: 3,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: l10n.detailNotesHint,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: context.lukaColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: Space.sm,
            ),
            enabledBorder: border(scheme.outline),
            focusedBorder: border(scheme.primary, 2),
          ),
        ),
      ],
    );
  }
}
