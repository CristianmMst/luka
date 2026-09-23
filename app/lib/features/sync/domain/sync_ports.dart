import 'package:finanzia/features/sync/domain/outbox_operation.dart';
import 'package:finanzia/features/sync/domain/sync_rules.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_ports.freezed.dart';

@freezed
abstract class OutboxEntry with _$OutboxEntry {
  const factory OutboxEntry({
    required int seq,
    required OutboxOperation op,
    required String idempotencyKey,
    required int attempts,
  }) = _OutboxEntry;
}

typedef TransactionsPage = ({
  List<SyncedTransaction> items,
  String? nextCursor,
});

typedef TransactionDetail = ({
  SyncedTransaction tx,
  List<SyncedSource> sources,
});

typedef SyncCounters = ({int pending, int rejected, DateTime? lastSyncedAt});

/// API del backend para sincronizar. Falla con [RemoteFailure].
abstract interface class SyncRemote {
  /// Envía la operación. Devuelve la transacción del servidor cuando el
  /// endpoint la retorna (crear, patch, emparejar, convertir).
  Future<SyncedTransaction?> send(OutboxEntry entry);

  /// `GET /transactions/{id}`; `null` si no existe (o no es del usuario).
  Future<SyncedTransaction?> fetchTransaction(String id);

  /// `GET /transactions/{id}` con sus fuentes; `null` si no existe (o no es
  /// del usuario).
  Future<TransactionDetail?> fetchTransactionDetail(String id);

  /// `GET /transactions?updated_since=` (orden `updated_at` ascendente).
  Future<TransactionsPage> transactionsSince(DateTime since, {String? cursor});
  Future<List<SyncedCategory>> categories();
  Future<List<SyncedAccount>> accounts();

  /// Todas las páginas de `GET /review` (solo ítems abiertos).
  Future<List<SyncedReviewItem>> openReview();
}

/// Base local (Drift). Cada método es atómico.
abstract interface class SyncStore {
  /// Borra todo si los datos guardados son de otro usuario.
  Future<void> claimFor(String userId);
  Future<void> clearAll();

  /// Aplica el cambio en local (optimista) y lo encola con una
  /// `Idempotency-Key` nueva.
  Future<void> enqueue(OutboxOperation op);
  Future<List<OutboxEntry>> pendingOutbox();

  /// `targetId` de creaciones rechazadas: sus operaciones dependientes no
  /// se envían.
  Future<Set<String>> rejectedCreates();

  /// Saca la operación del outbox. Si hay [server], la guarda y, si la
  /// operación creó un id local, lo canjea por el del servidor.
  Future<void> complete(OutboxEntry entry, SyncedTransaction? server);

  /// Cuenta un envío (`attempts`) antes de mandar la operación: con
  /// `attempts > 0` el servidor pudo haberla recibido.
  Future<void> markSending(OutboxEntry entry);

  /// Guarda el motivo del último fallo reintentable.
  Future<void> recordAttempt(OutboxEntry entry, String reason);

  /// Marca la operación `rejected`: queda para resolución manual, sin
  /// bloquear el pull ni contar como pendiente.
  Future<void> reject(OutboxEntry entry, String reason);

  /// Tras un rechazo, deja [id] como lo tiene el servidor: upsert de
  /// [server], o borra la fila local si es `null`. No toca nada si quedan
  /// operaciones pendientes para [id].
  ///
  /// Con `null`, las filas locales que tenían a [id] de pareja la pierden y,
  /// si quedaron como transferencia, vuelven al tipo por dirección.
  Future<void> restoreFromServer(String id, SyncedTransaction? server);

  /// Devuelve a `pending`, en su orden original, las operaciones
  /// rechazadas que tocan [id] (como objetivo o como pareja), para que el
  /// próximo ciclo las reenvíe.
  Future<void> retryRejected(String id);

  /// Borra las operaciones rechazadas que tocan [id] (como objetivo o como
  /// pareja) y las devuelve, para restaurar la verdad del servidor. Una
  /// creación descartada se quita en local: el servidor no la tiene.
  Future<List<OutboxOperation>> discardRejected(String id);

  Future<DateTime?> transactionsCursor();

  /// Upsert con [shouldApplyRemote]; el cursor solo avanza.
  Future<void> applyTransactions(
    List<SyncedTransaction> items, {
    required DateTime cursor,
  });
  Future<void> replaceCategories(List<SyncedCategory> items);

  /// Reemplaza y deja en `null` el `account_id` que ya no existe.
  Future<void> replaceAccounts(List<SyncedAccount> items);

  /// Reemplaza, salvo los ítems con convertir/descartar pendiente.
  Future<void> replaceReview(List<SyncedReviewItem> items);
  Future<void> markSynced(DateTime at);
  Stream<SyncCounters> watchCounters();
}
