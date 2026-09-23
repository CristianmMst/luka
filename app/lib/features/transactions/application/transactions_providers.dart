import 'package:finanzia/features/transactions/domain/category_option.dart';
import 'package:finanzia/features/transactions/domain/transaction_filter.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';
import 'package:finanzia/features/transactions/domain/transactions_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Puerto de lectura de movimientos; se sobrescribe en
/// `lib/app/composition.dart`.
final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => throw UnimplementedError(
    'transactionsRepositoryProvider se sobrescribe en la composición',
  ),
);

/// Reloj para las etiquetas "Hoy"/"Ayer" de la lista (los tests lo fijan).
final transactionsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Categorías para la hoja de categoría y el filtro.
final StreamProvider<List<CategoryOption>> transactionCategoriesProvider =
    StreamProvider.autoDispose<List<CategoryOption>>(
      (ref) => ref.watch(transactionsRepositoryProvider).watchCategories(),
    );

/// Tope del conteo de la hoja de filtros: más allá, el botón no dice el
/// número ("Ver movimientos").
const filteredCountCap = 1000;

/// Movimientos que cumplen un filtro, para "Ver N movimientos" (hasta
/// [filteredCountCap]).
final StreamProviderFamily<int, TransactionFilter> filteredCountProvider =
    StreamProvider.autoDispose.family<int, TransactionFilter>(
      (ref, filter) => ref
          .watch(transactionsRepositoryProvider)
          .watch(filter, limit: filteredCountCap)
          .map((items) => items.length),
    );

/// Una transacción local en vivo, sin sus fuentes (p. ej. la otra parte de
/// una transferencia en el detalle); `null` si no existe.
final StreamProviderFamily<TransactionView?, String> transactionByIdProvider =
    StreamProvider.autoDispose.family<TransactionView?, String>(
      (ref, id) => ref.watch(transactionsRepositoryProvider).watchOne(id),
    );
