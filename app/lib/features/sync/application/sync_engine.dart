import 'package:finanzia/features/sync/domain/sync_ports.dart';
import 'package:finanzia/features/sync/domain/sync_rules.dart';

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
  Future<PushOutcome> _push() async {
    final rejected = await _store.rejectedCreates();
    for (final entry in await _store.pendingOutbox()) {
      final op = entry.op;
      if (rejected.contains(op.targetId) || rejected.contains(op.relatedId)) {
        await _store.reject(entry, 'dependency_rejected');
        continue;
      }
      try {
        await _store.complete(entry, await _remote.send(entry));
      } on RemoteFailure catch (failure) {
        switch (classifyPushFailure(op, failure)) {
          case PushOutcome.done:
            await _store.complete(entry, null);
          case PushOutcome.rejected:
            await _store.reject(entry, failure.code ?? '${failure.statusCode}');
            if (op.createsRecord) rejected.add(op.targetId);
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

  Future<void> _pull() async {
    final since = await _store.transactionsCursor() ?? _epoch;
    String? cursor;
    do {
      final page = await _remote.transactionsSince(since, cursor: cursor);
      if (page.items.isNotEmpty) {
        final newest = page.items
            .map((t) => t.updatedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        await _store.applyTransactions(page.items, cursor: newest);
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    await _store.replaceCategories(await _remote.categories());
    await _store.replaceAccounts(await _remote.accounts());
    await _store.replaceReview(await _remote.openReview());
  }
}
