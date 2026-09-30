import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/sync_ports.dart';
import 'package:luka/features/sync/domain/sync_rules.dart';

enum SyncRunResult { synced, offline, sessionEnded, skipped }

/// Un ciclo de sincronización (spec 005 §9): push del outbox y luego pull.
/// Push primero para que el pull traiga el estado ya confirmado.
class SyncEngine {
  SyncEngine({
    required SyncStore store,
    required SyncRemote remote,
    DateTime Function()? now,
  }) : _store = store,
       _remote = remote,
       _now = now ?? DateTime.now;

  static final _epoch = DateTime.utc(1970);

  /// Solape del pull incremental: una fila que commitea tarde con un
  /// `updated_at` anterior al cursor no se pierde. Es seguro porque el
  /// filtro es `>=` y aplicar dos veces la misma fila no cambia nada.
  static const _pullOverlap = Duration(minutes: 5);

  final SyncStore _store;
  final SyncRemote _remote;
  final DateTime Function() _now;

  Future<SyncRunResult> run() async {
    final pushed = await _push();
    if (pushed == PushOutcome.sessionEnded) return SyncRunResult.sessionEnded;
    try {
      await _pull();
    } on RemoteFailure catch (f) {
      return f.statusCode == 401
          ? SyncRunResult.sessionEnded
          : SyncRunResult.offline;
    }
    if (pushed == PushOutcome.retryLater) return SyncRunResult.offline;
    await _store.markSynced(_now().toUtc());
    return SyncRunResult.synced;
  }

  /// Devuelve `done`, o el resultado que detuvo el drenado.
  ///
  /// Relee el outbox antes de cada operación: completar una creación canjea
  /// su id local en las operaciones que siguen, y el usuario puede cancelar
  /// operaciones mientras el ciclo corre.
  Future<PushOutcome> _push() async {
    final rejected = await _store.rejectedCreates();
    var lastSeq = -1;
    while (true) {
      final entry = await _nextPending(after: lastSeq);
      if (entry == null) break;
      lastSeq = entry.seq;
      final op = entry.op;
      if (rejected.contains(op.targetId) || rejected.contains(op.relatedId)) {
        await _store.reject(entry, 'dependency_rejected');
        await _restoreAfterReject(op, rejected);
        continue;
      }
      try {
        await _store.markSending(entry);
        await _store.complete(entry, await _remote.send(entry));
      } on RemoteFailure catch (failure) {
        switch (classifyPushFailure(op, failure)) {
          case PushOutcome.done:
            await _store.complete(entry, null);
          case PushOutcome.rejected:
            await _store.reject(entry, failure.code ?? '${failure.statusCode}');
            if (op.createsRecord) rejected.add(op.targetId);
            await _restoreAfterReject(op, rejected);
          case PushOutcome.retryLater:
            await _store.recordAttempt(entry, failure.code ?? 'network');
            return PushOutcome.retryLater;
          case PushOutcome.sessionEnded:
            return PushOutcome.sessionEnded;
        }
      }
    }
    return PushOutcome.done;
  }

  Future<void> _restoreAfterReject(
    OutboxOperation op,
    Set<String> rejectedCreates,
  ) => restoreAfterReject(
    store: _store,
    remote: _remote,
    op: op,
    rejectedCreates: rejectedCreates,
  );

  Future<OutboxEntry?> _nextPending({required int after}) async {
    for (final entry in await _store.pendingOutbox()) {
      if (entry.seq > after) return entry;
    }
    return null;
  }

  Future<void> _pull() async {
    final cursor = await _store.transactionsCursor();
    final overlapped = cursor?.subtract(_pullOverlap);
    final since = overlapped == null || overlapped.isBefore(_epoch)
        ? _epoch
        : overlapped;
    String? pageCursor;
    do {
      final page = await _remote.transactionsSince(since, cursor: pageCursor);
      if (page.items.isNotEmpty) {
        final newest = page.items
            .map((t) => t.updatedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        await _store.applyTransactions(page.items, cursor: newest);
      }
      pageCursor = page.nextCursor;
    } while (pageCursor != null);
    await _store.replaceCategories(await _remote.categories());
    await _store.replaceAccounts(await _remote.accounts());
    await _store.replaceReview(await _remote.openReview());
  }
}

/// Tras rechazar (o descartar) [op], deja como las tiene el servidor las
/// transacciones que su efecto optimista cambió, para que no quede para
/// siempre (p. ej. un borrado rechazado que oculta la fila). Crear y
/// convertir no se tocan: la fila local es dato del usuario. Los ids de
/// [rejectedCreates] no existen en el servidor.
///
/// Desemparejar limpió también a la pareja, que la operación no nombra: se
/// restaura la pareja que el servidor conserva.
///
/// Sin red (o sin sesión) la fila queda con el efecto optimista; el fallo
/// no se propaga.
Future<void> restoreAfterReject({
  required SyncStore store,
  required SyncRemote remote,
  required OutboxOperation op,
  required Set<String> rejectedCreates,
}) async {
  final ids = switch (op) {
    PatchTransactionOp(:final id) ||
    UnsetTransferPairOp(:final id) ||
    DeleteTransactionOp(:final id) => [id],
    SetTransferPairOp(:final id, :final pairId) => [id, pairId],
    CreateTransactionOp() ||
    ConvertReviewOp() ||
    DiscardReviewOp() => const <String>[],
  };
  for (final id in ids) {
    if (rejectedCreates.contains(id)) continue;
    try {
      final server = await remote.fetchTransaction(id);
      await store.restoreFromServer(id, server);
      final partner = server?.transferPairId;
      if (op is UnsetTransferPairOp &&
          partner != null &&
          !rejectedCreates.contains(partner)) {
        await store.restoreFromServer(
          partner,
          await remote.fetchTransaction(partner),
        );
      }
    } on RemoteFailure {
      // Sin red o sin sesión: la fila queda con el efecto optimista.
    }
  }
}
