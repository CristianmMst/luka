import 'dart:async';

import 'package:finanzia/features/transactions/application/transactions_providers.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:finanzia/features/transactions/domain/transactions_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_detail_controller.freezed.dart';

/// Fuentes crudas del detalle: se piden al servidor, así que pueden faltar
/// sin red.
@freezed
sealed class SourcesState with _$SourcesState {
  const factory SourcesState.loading() = SourcesLoading;
  const factory SourcesState.offline() = SourcesOffline;
  const factory SourcesState.loaded(List<TxSource> sources) = SourcesLoaded;
}

@freezed
abstract class TransactionDetailState with _$TransactionDetailState {
  const factory TransactionDetailState({
    required AsyncValue<TransactionView?> tx,
    required SourcesState sources,
  }) = _TransactionDetailState;
}

/// Detalle de una transacción (spec 008): la fila local en vivo y sus
/// fuentes del servidor. `tx` en `null` significa que ya no existe.
class TransactionDetailController extends Notifier<TransactionDetailState> {
  TransactionDetailController(this.id);

  final String id;

  @override
  TransactionDetailState build() {
    final subscription = ref
        .read(transactionsRepositoryProvider)
        .watchOne(id)
        .listen(
          (tx) => state = state.copyWith(tx: AsyncData(tx)),
          onError: (Object error, StackTrace stack) =>
              state = state.copyWith(tx: AsyncError(error, stack)),
        );
    ref.onDispose(() => unawaited(subscription.cancel()));
    // Microtask: no tocar `state` antes de que build() devuelva.
    unawaited(Future.microtask(_loadSources));
    return const TransactionDetailState(
      tx: AsyncLoading(),
      sources: SourcesState.loading(),
    );
  }

  /// Vuelve a pedir las fuentes (p. ej. al recuperar la red).
  Future<void> refreshSources() {
    state = state.copyWith(sources: const SourcesState.loading());
    return _loadSources();
  }

  Future<void> _loadSources() async {
    final sources = await ref
        .read(transactionsRepositoryProvider)
        .fetchSources(id);
    if (!ref.mounted) return;
    state = state.copyWith(
      sources: sources == null
          ? const SourcesState.offline()
          : SourcesState.loaded(sources),
    );
  }
}

final NotifierProviderFamily<
  TransactionDetailController,
  TransactionDetailState,
  String
>
transactionDetailControllerProvider = NotifierProvider.autoDispose
    .family<TransactionDetailController, TransactionDetailState, String>(
      TransactionDetailController.new,
    );
