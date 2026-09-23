import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/domain/transaction_filter.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:finanzia/features/transactions/presentation/widgets/category_sheet.dart';
import 'package:finanzia/features/transactions/presentation/widgets/sheet_frame.dart';
import 'package:finanzia/features/transactions/presentation/widgets/transaction_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hoja "Filtros" (diseño "Filtros"): periodo, tipo, banco, fuente y
/// categoría sobre un borrador; "Ver N movimientos" lo aplica y "Limpiar"
/// lo vuelve al filtro por defecto (el texto de búsqueda se conserva).
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({required this.initial, super.key});

  final TransactionFilter initial;

  /// Abre la hoja; devuelve el filtro a aplicar o `null` si se cerró.
  static Future<TransactionFilter?> show(
    BuildContext context,
    TransactionFilter initial,
  ) => showFinanziaSheet<TransactionFilter>(
    context,
    builder: (_) => FilterSheet(initial: initial),
  );

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late TransactionFilter _draft = widget.initial;

  void _update(TransactionFilter next) => setState(() => _draft = next);

  Set<T> _toggle<T>(Set<T> set, Set<T> values) {
    final on = values.every(set.contains);
    return on ? ({...set}..removeAll(values)) : {...set, ...values};
  }

  Future<void> _pickDates() async {
    final now = ref.read(transactionsClockProvider)();
    final today = colombiaLocal(now);
    final range = _draft.range(now);
    final from = colombiaLocal(range.from);
    final last = colombiaLocal(range.to).subtract(const Duration(days: 1));
    DateTime date(DateTime d) => DateTime(d.year, d.month, d.day);
    final lastDate = date(today);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: lastDate,
      initialDateRange: DateTimeRange(
        start: date(from).isAfter(lastDate) ? lastDate : date(from),
        end: date(last).isAfter(lastDate) ? lastDate : date(last),
      ),
    );
    if (picked == null || !mounted) return;
    _update(
      _draft.copyWith(
        period: PeriodPreset.custom,
        from: colombiaMidnight(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        to: colombiaMidnight(
          picked.end.year,
          picked.end.month,
          picked.end.day + 1,
        ),
      ),
    );
  }

  Future<void> _pickCategory() async {
    final choice = await CategorySheet.show(
      context,
      selectedId: _draft.categoryId,
      allowAll: true,
    );
    if (choice == null || !mounted) return;
    _update(_draft.copyWith(categoryId: choice.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = ref.watch(transactionsClockProvider)();
    final count = ref.watch(filteredCountProvider(_draft)).value;
    final categories = ref.watch(transactionCategoriesProvider).value;
    final categoryName = _draft.categoryId == null
        ? l10n.filterCategoryAll
        : categories
                  ?.where((c) => c.id == _draft.categoryId)
                  .firstOrNull
                  ?.name ??
              l10n.filterCategory;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Space.sm,
              children: [
                const SheetHandle(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.transactionsFilters,
                        style: textTheme.headlineSmall?.copyWith(fontSize: 22),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _update(TransactionFilter(text: widget.initial.text)),
                      child: Text(l10n.filterClear),
                    ),
                  ],
                ),
                _Group(
                  title: l10n.filterPeriod,
                  children: [
                    for (final preset in PeriodPreset.values)
                      _ToggleChip(
                        label:
                            preset == PeriodPreset.custom &&
                                _draft.period == PeriodPreset.custom
                            ? customRangeLabel(l10n, _draft, now)
                            : presetName(l10n, preset),
                        selected: _draft.period == preset,
                        onTap: preset == PeriodPreset.custom
                            ? _pickDates
                            : () => _update(
                                _draft.copyWith(
                                  period: preset,
                                  from: null,
                                  to: null,
                                ),
                              ),
                      ),
                  ],
                ),
                _Group(
                  title: l10n.filterKind,
                  children: [
                    for (final kind in TxKind.values)
                      _ToggleChip(
                        label: kindName(l10n, kind),
                        selected: _draft.kinds.contains(kind),
                        onTap: () => _update(
                          _draft.copyWith(kinds: _toggle(_draft.kinds, {kind})),
                        ),
                      ),
                  ],
                ),
                _Group(
                  title: l10n.filterBank,
                  children: [
                    for (final bank in bankOptions(l10n))
                      _ToggleChip(
                        label: bank.label,
                        selected: _draft.banks.contains(bank.wire),
                        onTap: () => _update(
                          _draft.copyWith(
                            banks: _toggle(_draft.banks, {bank.wire}),
                          ),
                        ),
                      ),
                  ],
                ),
                _Group(
                  title: l10n.filterSource,
                  children: [
                    for (final source in sourceOptions(l10n))
                      _ToggleChip(
                        label: source.label,
                        selected: source.channels.every(
                          _draft.channels.contains,
                        ),
                        onTap: () => _update(
                          _draft.copyWith(
                            channels: _toggle<TxChannel>(
                              _draft.channels,
                              source.channels,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  child: InkWell(
                    onTap: _pickCategory,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.filterCategory,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            categoryName,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w400,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, Space.md, 20, Space.lg),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(_draft),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: textTheme.titleMedium,
            ),
            child: Text(
              count != null && count < filteredCountCap
                  ? l10n.filterApply(count)
                  : l10n.filterApplyUncounted,
            ),
          ),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Wrap(spacing: Space.xs, children: children),
      ],
    );
  }
}

/// Opción de 36 dp de alto dentro de un área táctil de 48 dp.
class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.chipAll,
        child: SizedBox(
          height: minTouchTarget,
          child: Center(
            widthFactor: 1,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? scheme.primaryContainer : Colors.transparent,
                borderRadius: Radii.chipAll,
                border: Border.all(
                  color: selected ? scheme.primaryContainer : scheme.outline,
                ),
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
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
