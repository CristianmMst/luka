import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/presentation/sync_refresh.dart';
import 'package:luka/features/transactions/application/dedupe_hint_controller.dart';
import 'package:luka/features/transactions/application/transaction_actions.dart';
import 'package:luka/features/transactions/application/transactions_list_controller.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/day_group.dart';
import 'package:luka/features/transactions/domain/transaction_filter.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';
import 'package:luka/features/transactions/presentation/widgets/change_category.dart';
import 'package:luka/features/transactions/presentation/widgets/day_card.dart';
import 'package:luka/features/transactions/presentation/widgets/dedupe_hint_banner.dart';
import 'package:luka/features/transactions/presentation/widgets/filter_sheet.dart';
import 'package:luka/features/transactions/presentation/widgets/list_states.dart';
import 'package:luka/features/transactions/presentation/widgets/offline_banner.dart';
import 'package:luka/features/transactions/presentation/widgets/rejected_banner.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// "Movimientos" (diseño S, spec 008 §3.3): buscador, filtros, el aviso
/// "Sin duplicados", tarjetas por día con paginación infinita y los estados
/// vacío, sin resultados, sin conexión y primera sincronización.
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  /// A cuántos píxeles del final se pide la página siguiente.
  static const loadMoreThreshold = 600.0;

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  /// Filas cargadas cuando se pidió la última página: evita pedir otra
  /// mientras no llegue la anterior.
  int? _requestedAt;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  TransactionsListController get _controller =>
      ref.read(transactionsListControllerProvider.notifier);

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter > TransactionsPage.loadMoreThreshold) {
      return;
    }
    final state = ref.read(transactionsListControllerProvider);
    final groups = state.groups.value;
    if (!state.hasMore || groups == null) return;
    final loaded = groups.fold(0, (sum, g) => sum + g.items.length);
    if (_requestedAt == loaded) return;
    _requestedAt = loaded;
    _controller.loadMore();
  }

  void _clearFilters() {
    _search.clear();
    _controller.clearFilters();
  }

  Future<void> _openFilters(TransactionFilter current) async {
    final next = await FilterSheet.show(context, current);
    if (next == null || !mounted) return;
    _controller.setFilter(next);
  }

  void _openDetail(TransactionView tx) =>
      context.go('${Routes.transactions}/${tx.id}');

  Future<void> _changeCategory(TransactionView tx) =>
      changeCategory(context, ref.read(transactionActionsProvider), tx);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(transactionsListControllerProvider);
    final sync = ref.watch(syncCoordinatorProvider);
    final now = ref.watch(transactionsClockProvider)();
    final categoryId = state.filter.categoryId;
    final categoryName = categoryId == null
        ? null
        : filterCategoryName(
            l10n,
            categoryId,
            ref.watch(transactionCategoriesProvider).value,
          );
    final summary = filterSummary(
      l10n,
      state.filter,
      now,
      categoryName: categoryName,
    );
    ref
      ..listen(
        transactionsListControllerProvider.select((s) => s.filter),
        (_, _) => _requestedAt = null,
      )
      // Si otra pantalla (el Inicio) reemplaza el filtro, el buscador muestra
      // el texto que de verdad filtra.
      ..listen(
        transactionsListControllerProvider.select((s) => s.filter.text),
        (_, next) {
          if (_search.text != next) _search.text = next;
        },
      );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              period: periodHeading(l10n, state.filter, now),
              summary: summary,
              activeCount: state.filter.activeCount,
              search: _search,
              onSearch: _controller.setText,
              onFilters: () => unawaited(_openFilters(state.filter)),
            ),
            if (sync.offline)
              const Padding(
                padding: EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
                child: OfflineBanner(),
              ),
            Expanded(
              child: switch (_body(state, sync, summary)) {
                final _DayList list => SyncRefresh(child: list),
                final other => SyncRefresh.fill(child: other),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(TransactionsListState state, SyncStatus sync, String summary) {
    final firstSync = sync.lastSyncedAt == null && sync.running;
    final groups = state.groups.value;
    if (groups == null) {
      if (state.groups.hasError) {
        return TransactionsLoadError(
          onRetry: () => _controller.setFilter(state.filter),
        );
      }
      return TransactionsSkeleton(firstSync: firstSync);
    }
    if (groups.isEmpty) {
      if (firstSync) return const TransactionsSkeleton(firstSync: true);
      final hasAny = ref.watch(hasAnyTransactionsProvider).value;
      if (hasAny == null) return const TransactionsSkeleton();
      if (!hasAny) {
        return EmptyTransactions(onRegister: () => context.go(Routes.register));
      }
      final filter = state.filter;
      if (filter.activeCount == 0 && filter.text.trim().isEmpty) {
        return EmptyPeriod(
          onLastMonth: () => _controller.setFilter(
            filter.copyWith(period: PeriodPreset.lastMonth),
          ),
          onFilters: () => unawaited(_openFilters(filter)),
        );
      }
      return NoResults(
        text: state.filter.text,
        summary: summary,
        onClear: _clearFilters,
      );
    }
    return _DayList(
      groups: groups,
      hasMore: state.hasMore,
      scroll: _scroll,
      onOpen: _openDetail,
      onChangeCategory: (tx) => unawaited(_changeCategory(tx)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.period,
    required this.summary,
    required this.activeCount,
    required this.search,
    required this.onSearch,
    required this.onFilters,
  });

  final String period;
  final String summary;
  final int activeCount;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.sm,
        children: [
          Row(
            spacing: Space.sm,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  // Se encoge antes que partirse junto a la píldora.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.navTransactionsLabel,
                      maxLines: 1,
                      style: textTheme.headlineLarge?.copyWith(
                        fontSize: 34,
                        letterSpacing: -1.2,
                      ),
                    ),
                  ),
                ),
              ),
              // El periodo se cambia en la hoja de filtros.
              Semantics(
                button: true,
                excludeSemantics: true,
                label: l10n.transactionsPeriodSemantics(period),
                onTap: onFilters,
                child: Material(
                  color: brand.card,
                  shape: StadiumBorder(side: BorderSide(color: brand.hairline)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onFilters,
                    child: Container(
                      height: minTouchTarget,
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: [
                          Text(
                            period,
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(Icons.expand_more_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            spacing: Space.xs,
            children: [
              Expanded(
                child: TextField(
                  controller: search,
                  onChanged: onSearch,
                  textInputAction: TextInputAction.search,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: l10n.transactionsSearchHint,
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: brand.card,
                    isDense: true,
                    constraints: const BoxConstraints(
                      minHeight: height,
                      maxHeight: height,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Space.md,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: Radii.pillAll,
                      borderSide: BorderSide(color: brand.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: Radii.pillAll,
                      borderSide: BorderSide(color: scheme.primary, width: 2),
                    ),
                  ),
                ),
              ),
              _FiltersButton(count: activeCount, onTap: onFilters),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xxs),
            child: Text(summary, style: muted),
          ),
        ],
      ),
    );
  }

  /// Alto del buscador y del botón de filtros.
  static const height = 52.0;
}

class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: l10n.transactionsFiltersSemantics(count),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: brand.card,
            shape: CircleBorder(side: BorderSide(color: brand.hairline)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox.square(
                dimension: _Header.height,
                child: Icon(
                  Icons.filter_list_rounded,
                  size: 22,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: brand.card, width: 2),
                  ),
                  child: Text(
                    '$count',
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayList extends ConsumerWidget {
  const _DayList({
    required this.groups,
    required this.hasMore,
    required this.scroll,
    required this.onOpen,
    required this.onChangeCategory,
  });

  final List<DayGroup> groups;
  final bool hasMore;
  final ScrollController scroll;
  final ValueChanged<TransactionView> onOpen;
  final ValueChanged<TransactionView> onChangeCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(transactionActionsProvider);
    final rejected = [
      for (final group in groups)
        for (final tx in group.items)
          if (tx.sync == SyncMark.rejected) tx,
    ];
    // El aviso explica el sello: solo si hay alguno a la vista.
    final showHint =
        (ref.watch(dedupeHintControllerProvider).value ?? false) &&
        groups.any((g) => g.items.any((tx) => tx.channels.length > 1));
    final children = <Widget>[
      if (showHint)
        DedupeHintBanner(
          key: const ValueKey('dedupe-hint'),
          onDismiss: () => unawaited(
            ref.read(dedupeHintControllerProvider.notifier).dismiss(),
          ),
        ),
      for (final tx in rejected)
        RejectedBanner(
          key: ValueKey('rejected-${tx.id}'),
          name: displayName(l10n, tx),
          onRetry: () => unawaited(actions.retryRejected(tx.id)),
          onDiscard: () => unawaited(actions.discardRejected(tx.id)),
        ),
      for (final group in groups)
        DayCard(
          key: ValueKey(group.day),
          group: group,
          onOpen: onOpen,
          onChangeCategory: onChangeCategory,
        ),
      if (hasMore)
        const Padding(
          padding: EdgeInsets.all(Space.md),
          child: Center(child: CircularProgressIndicator()),
        ),
    ];

    return ListView.separated(
      controller: scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      // La barra translúcida va encima: su alto entra en el margen.
      padding: const EdgeInsets.all(Space.md).copyWith(
        top: Space.sm,
        bottom: Space.md + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
      itemBuilder: (_, index) => children[index],
    );
  }
}
