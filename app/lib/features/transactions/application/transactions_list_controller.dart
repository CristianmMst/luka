import 'dart:async';

import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/domain/day_group.dart';
import 'package:finanzia/features/transactions/domain/transaction_filter.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transactions_list_controller.freezed.dart';

@freezed
abstract class TransactionsListState with _$TransactionsListState {
  const factory TransactionsListState({
    required TransactionFilter filter,
    required int limit,
    required AsyncValue<List<DayGroup>> groups,
    required bool hasMore,
  }) = _TransactionsListState;
}

/// Lista de movimientos agrupada por día (spec 008): filtro, búsqueda con
/// debounce y paginación creciente sobre `TransactionsRepository.watch`.
///
/// Cada cambio de filtro y cada `loadMore` vuelve a suscribirse; así el
/// repositorio recalcula el rango del periodo con la hora actual sin
/// timers.
class TransactionsListController extends Notifier<TransactionsListState> {
  static const pageSize = 50;
  static const textDebounce = Duration(milliseconds: 250);

  StreamSubscription<List<TransactionView>>? _subscription;
  Timer? _debounce;

  @override
  TransactionsListState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      unawaited(_subscription?.cancel());
    });
    const filter = TransactionFilter();
    _subscribe(filter, pageSize);
    return const TransactionsListState(
      filter: filter,
      limit: pageSize,
      groups: AsyncLoading(),
      hasMore: false,
    );
  }

  /// Reemplaza el filtro y vuelve a la primera página.
  void setFilter(TransactionFilter filter) {
    state = state.copyWith(filter: filter, limit: pageSize);
    _subscribe(filter, pageSize);
  }

  /// Aplica el texto de búsqueda cuando el usuario deja de teclear.
  void setText(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      textDebounce,
      () => setFilter(state.filter.copyWith(text: text)),
    );
  }

  /// Vuelve al filtro por defecto, texto incluido ("Quitar filtros").
  void clearFilters() {
    _debounce?.cancel();
    setFilter(const TransactionFilter());
  }

  /// Pide otra página; los grupos actuales se conservan mientras llega.
  void loadMore() {
    final limit = state.limit + pageSize;
    state = state.copyWith(limit: limit);
    _subscribe(state.filter, limit);
  }

  void _subscribe(TransactionFilter filter, int limit) {
    unawaited(_subscription?.cancel());
    final now = ref.read(transactionsClockProvider);
    _subscription = ref
        .read(transactionsRepositoryProvider)
        .watch(filter, limit: limit)
        .listen(
          (items) => state = state.copyWith(
            groups: AsyncData(groupByDay(items, now())),
            hasMore: items.length >= limit,
          ),
          onError: (Object error, StackTrace stack) =>
              state = state.copyWith(groups: AsyncError(error, stack)),
        );
  }
}

final transactionsListControllerProvider =
    NotifierProvider<TransactionsListController, TransactionsListState>(
      TransactionsListController.new,
    );
