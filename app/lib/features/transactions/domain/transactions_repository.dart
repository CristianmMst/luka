import 'package:finanzia/features/transactions/domain/category_option.dart';
import 'package:finanzia/features/transactions/domain/transaction_filter.dart';
import 'package:finanzia/features/transactions/domain/transaction_view.dart';

/// Puerto de solo lectura para la lista y el detalle de movimientos
/// (los datos viven en Drift; ver spec 003 §3).
abstract interface class TransactionsRepository {
  /// Movimientos que cumplen [filter], recortados a [limit] (más recientes
  /// primero).
  Stream<List<TransactionView>> watch(
    TransactionFilter filter, {
    required int limit,
  });

  /// El detalle de una transacción; `null` si no existe (o se borró).
  Stream<TransactionView?> watchOne(String id);

  Stream<List<CategoryOption>> watchCategories();

  /// Fuentes crudas del detalle (`GET /transactions/{id}`); `null` sin red.
  Future<List<({TxChannel channel, DateTime receivedAt})>?> fetchSources(
    String id,
  );
}
