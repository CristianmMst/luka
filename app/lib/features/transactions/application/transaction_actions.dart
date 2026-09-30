import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/manual_draft.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';

/// Registro manual y ediciones del detalle de un movimiento. Todas son
/// optimistas: se aplican en local y se encolan en el outbox (spec 005 §9).
class TransactionActions {
  TransactionActions(this._coordinator);

  final SyncCoordinator _coordinator;

  /// Cambia la categoría. Con [always] y un comercio conocido, el servidor
  /// aprende la regla para los próximos movimientos de ese comercio.
  Future<void> changeCategory(
    TransactionView tx,
    String categoryId, {
    required bool always,
  }) {
    final hasMerchant = tx.merchant?.trim().isNotEmpty ?? false;
    return _patch(
      tx,
      TransactionPatch(
        categoryId: categoryId,
        learnMerchantRule: always && hasMerchant,
      ),
    );
  }

  /// Marca o desmarca la transferencia; al desmarcar vuelve al tipo por
  /// dirección (débito → gasto, crédito → ingreso).
  Future<void> setTransfer(TransactionView tx, {required bool isTransfer}) {
    final kind = isTransfer
        ? TxKind.transfer
        : tx.direction == TxDirection.debit
        ? TxKind.expense
        : TxKind.income;
    return _patch(tx, TransactionPatch(kind: kind, learnMerchantRule: false));
  }

  /// Guarda la nota; vacía (o solo espacios) la borra.
  Future<void> saveNotes(TransactionView tx, String notes) {
    final trimmed = notes.trim();
    return _patch(
      tx,
      TransactionPatch(
        notes: (value: trimmed.isEmpty ? null : trimmed),
        learnMerchantRule: false,
      ),
    );
  }

  /// Registra un movimiento manual (spec 008 §3.4) y devuelve su id local.
  /// Funciona sin red: se envía cuando haya conexión.
  Future<String> create(ManualDraft draft) async {
    final data = draft.toNewTransaction();
    final localId = _coordinator.newLocalId();
    await _coordinator.enqueue(
      OutboxOperation.createTransaction(localId: localId, data: data),
    );
    return localId;
  }

  /// El id vigente de un movimiento creado en este proceso: el del servidor
  /// si el sync ya canjeó el local.
  String resolveId(String id) => _coordinator.resolveId(id);

  /// Elimina un movimiento manual (el backend rechaza los demás). Si su
  /// creación todavía no se envió, se cancela y no viaja nada.
  Future<void> delete(String id) => _coordinator.enqueue(
    OutboxOperation.deleteTransaction(id: _coordinator.resolveId(id)),
  );

  Future<void> retryRejected(String id) => _coordinator.retryRejected(id);

  Future<void> discardRejected(String id) => _coordinator.discardRejected(id);

  Future<void> _patch(TransactionView tx, TransactionPatch patch) =>
      _coordinator.enqueue(
        OutboxOperation.patchTransaction(id: tx.id, patch: patch),
      );
}

final transactionActionsProvider = Provider<TransactionActions>(
  (ref) => TransactionActions(ref.watch(syncCoordinatorProvider.notifier)),
);
