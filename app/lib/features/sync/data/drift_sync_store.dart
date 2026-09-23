import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/features/sync/data/outbox_codec.dart';
import 'package:finanzia/features/sync/domain/outbox_operation.dart';
import 'package:finanzia/features/sync/domain/sync_ports.dart';
import 'package:finanzia/features/sync/domain/sync_rules.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:uuid/uuid.dart';

/// [SyncStore] sobre la base local Drift (spec 004 §5, 005 §9, 003 §3).
///
/// Cada método que escribe corre en una sola transacción. Las operaciones
/// guardan sus ids solo en `target_id`/`related_id`, así que canjear un id
/// local por el del servidor es reescribir esas columnas.
class DriftSyncStore implements SyncStore {
  DriftSyncStore(this._db, {DateTime Function()? now})
    : _clock = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// Toda fecha se guarda en UTC: las columnas son texto ISO y
  /// `ORDER BY occurred_at` compara el texto, así que mezclar zonas
  /// desordenaría la lista.
  DateTime _now() => _clock().toUtc();

  static const _pending = 'pending';
  static const _rejected = 'rejected';

  static const _ownerKey = 'owner_user_id';
  static const _cursorKey = 'transactions_cursor';
  static const _lastSyncedKey = 'last_synced_at';

  // ---------------------------------------------------------------- dueño

  @override
  Future<void> claimFor(String userId) => _db.transaction(() async {
    final owner = await _readState(_ownerKey);
    if (owner != null && owner != userId) await _wipe();
    await _writeState(_ownerKey, userId);
  });

  @override
  Future<void> clearAll() => _db.transaction(_wipe);

  Future<void> _wipe() async {
    await _db.delete(_db.localTransactions).go();
    await _db.delete(_db.localCategories).go();
    await _db.delete(_db.localAccounts).go();
    await _db.delete(_db.localReview).go();
    await _db.delete(_db.outbox).go();
    await _db.delete(_db.syncState).go();
  }

  // --------------------------------------------------------------- outbox

  @override
  Future<void> enqueue(OutboxOperation op) => _db.transaction(() async {
    final shouldQueue = await _applyOptimistic(op);
    if (shouldQueue) await _insertOutbox(op);
  });

  /// Aplica [op] a las tablas locales. Devuelve `false` si la operación se
  /// resolvió en local y no hay que enviarla.
  Future<bool> _applyOptimistic(OutboxOperation op) async {
    switch (op) {
      case CreateTransactionOp(:final localId, :final data):
        await _insertLocalTransaction(localId, data);
      case PatchTransactionOp(:final id, :final patch):
        await _applyPatch(id, patch);
      case SetTransferPairOp(:final id, :final pairId):
        await _setPair(id, pairId);
        await _setPair(pairId, id);
      case UnsetTransferPairOp(:final id):
        await _clearPairOf(id);
      case DeleteTransactionOp(:final id):
        final cancelled = await _cancelUnsentCreate(id);
        await _deleteLocalTransaction(id);
        return !cancelled;
      case ConvertReviewOp(:final rawMessageId, :final localId, :final data):
        await _deleteReviewItem(rawMessageId);
        await _insertLocalTransaction(localId, data);
      case DiscardReviewOp(:final rawMessageId):
        await _deleteReviewItem(rawMessageId);
    }
    return true;
  }

  Future<void> _insertOutbox(OutboxOperation op) async {
    final encoded = OutboxCodec.encode(op);
    await _db
        .into(_db.outbox)
        .insert(
          OutboxCompanion.insert(
            kind: encoded.kind,
            targetId: encoded.targetId,
            relatedId: Value(encoded.relatedId),
            payload: encoded.payload,
            idempotencyKey: const Uuid().v4(),
            createdAt: _now(),
          ),
        );
  }

  @override
  Future<List<OutboxEntry>> pendingOutbox() async {
    final rows =
        await (_db.select(_db.outbox)
              ..where((o) => o.status.equals(_pending))
              ..orderBy([(o) => OrderingTerm.asc(o.seq)]))
            .get();
    return [
      for (final row in rows)
        OutboxEntry(
          seq: row.seq,
          op: _decode(row),
          idempotencyKey: row.idempotencyKey,
          attempts: row.attempts,
        ),
    ];
  }

  @override
  Future<Set<String>> rejectedCreates() async {
    final rows = await (_db.select(
      _db.outbox,
    )..where((o) => o.status.equals(_rejected))).get();
    return {
      for (final row in rows)
        if (_decode(row).createsRecord) row.targetId,
    };
  }

  @override
  Future<void> complete(OutboxEntry entry, SyncedTransaction? server) =>
      _db.transaction(() async {
        final op = entry.op;
        final removed = await (_db.delete(
          _db.outbox,
        )..where((o) => o.seq.equals(entry.seq))).go();
        if (removed == 0) return _completeStale(op, server);

        // Una creación sin respuesta (p. ej. convertir ya resuelto en otro
        // dispositivo) no existe en el servidor con este id: se quita la
        // fila optimista y el pull trae la copia real, si la hay.
        if (server == null && op.createsRecord) {
          await _dropLocalRecord(op.targetId);
          return;
        }

        if (server != null && op.createsRecord && server.id != op.targetId) {
          await _swapId(from: op.targetId, to: server.id);
        }

        if (server != null && !await _hasPendingOps(server.id)) {
          await _upsertServer(server);
        }

        // Todas las marcadas: desemparejar también marcó a la pareja, que
        // la operación no nombra.
        await _refreshAllPendingPush();
      });

  /// La operación ya no estaba en el outbox: se canceló o se borró todo
  /// mientras viajaba. Tras un borrado total (sin dueño) no se escribe
  /// nada; si era una creación que el servidor sí guardó, se encola su
  /// borrado para no dejar la copia remota.
  Future<void> _completeStale(
    OutboxOperation op,
    SyncedTransaction? server,
  ) async {
    if (await _readState(_ownerKey) == null) return;
    if (op.createsRecord && server != null) {
      await _insertOutbox(OutboxOperation.deleteTransaction(id: server.id));
    }
  }

  /// Canjea el id local [from] por el del servidor [to] en el outbox y en
  /// las parejas. La fila local se renombra si todavía hay operaciones
  /// para ella (conserva su contenido optimista); si no, se borra y la
  /// reemplaza la fila del servidor.
  Future<void> _swapId({required String from, required String to}) async {
    final ids = [Variable.withString(from), Variable.withString(to)];
    await _db.customUpdate(
      'UPDATE outbox SET '
      'target_id = CASE WHEN target_id = ?1 THEN ?2 ELSE target_id END, '
      'related_id = CASE WHEN related_id = ?1 THEN ?2 ELSE related_id END',
      variables: ids,
      updates: {_db.outbox},
    );
    await _db.customUpdate(
      'UPDATE local_transactions SET transfer_pair_id = ?2 '
      'WHERE transfer_pair_id = ?1',
      variables: ids,
      updates: {_db.localTransactions},
    );
    if (await _hasPendingOps(to)) {
      await _deleteLocalTransaction(to);
      await _db.customUpdate(
        'UPDATE local_transactions SET id = ?2 WHERE id = ?1',
        variables: ids,
        updates: {_db.localTransactions},
      );
    } else {
      await _deleteLocalTransaction(from);
    }
  }

  @override
  Future<void> markSending(OutboxEntry entry) => _db.transaction(() async {
    await (_db.update(
      _db.outbox,
    )..where((o) => o.seq.equals(entry.seq))).write(
      OutboxCompanion.custom(attempts: _db.outbox.attempts + const Constant(1)),
    );
  });

  @override
  Future<void> recordAttempt(OutboxEntry entry, String reason) =>
      _db.transaction(() async {
        await (_db.update(_db.outbox)..where((o) => o.seq.equals(entry.seq)))
            .write(OutboxCompanion(lastError: Value(reason)));
      });

  @override
  Future<void> reject(OutboxEntry entry, String reason) =>
      _db.transaction(() async {
        await (_db.update(
          _db.outbox,
        )..where((o) => o.seq.equals(entry.seq))).write(
          OutboxCompanion(
            status: const Value(_rejected),
            lastError: Value(reason),
          ),
        );
        // Lo rechazado no cuenta como pendiente: el pull vuelve a tocar
        // esas filas.
        await _refreshAllPendingPush();
      });

  @override
  Future<void> restoreFromServer(String id, SyncedTransaction? server) =>
      _db.transaction(() async {
        if (await _hasPendingOps(id)) return;
        if (server == null) {
          await _unlinkPartnersOf(id);
          await _deleteLocalTransaction(id);
        } else {
          await _upsertServer(server);
        }
      });

  @override
  Future<void> retryRejected(String id) => _db.transaction(() async {
    final rows = await _rejectedTouching(id);
    await (_db.update(_db.outbox)
          ..where((o) => o.seq.isIn([for (final row in rows) row.seq])))
        .write(const OutboxCompanion(status: Value(_pending)));
    for (final other in _idsOf(rows)) {
      await _refreshPendingPush(other);
    }
  });

  @override
  Future<List<OutboxOperation>> discardRejected(String id) =>
      _db.transaction(() async {
        final rows = await _rejectedTouching(id);
        final ops = [for (final row in rows) _decode(row)];
        await (_db.delete(
          _db.outbox,
        )..where((o) => o.seq.isIn([for (final row in rows) row.seq]))).go();
        for (final op in ops) {
          if (op.createsRecord) await _dropLocalRecord(op.targetId);
        }
        for (final other in _idsOf(rows)) {
          await _refreshPendingPush(other);
        }
        return ops;
      });

  /// Operaciones rechazadas que tocan [id], como objetivo o como pareja,
  /// en orden.
  Future<List<OutboxRow>> _rejectedTouching(String id) =>
      (_db.select(_db.outbox)
            ..where(
              (o) =>
                  o.status.equals(_rejected) &
                  (o.targetId.equals(id) | o.relatedId.equals(id)),
            )
            ..orderBy([(o) => OrderingTerm.asc(o.seq)]))
          .get();

  static Set<String> _idsOf(List<OutboxRow> rows) => {
    for (final row in rows) ...[row.targetId, ?row.relatedId],
  };

  // ----------------------------------------------------------------- pull

  @override
  Future<DateTime?> transactionsCursor() async {
    final raw = await _readState(_cursorKey);
    return raw == null ? null : DateTime.parse(raw);
  }

  @override
  Future<void> applyTransactions(
    List<SyncedTransaction> items, {
    required DateTime cursor,
  }) => _db.transaction(() async {
    for (final item in items) {
      if (await _remoteWins(item)) await _upsertServer(item);
    }
    final stored = await transactionsCursor();
    final next = stored != null && stored.isAfter(cursor) ? stored : cursor;
    await _writeState(_cursorKey, _iso(next));
  });

  Future<bool> _remoteWins(SyncedTransaction item) async {
    final local = await _findLocalTransaction(item.id);
    // Sin fila pero con operaciones: un borrado local pendiente. No revive.
    if (local == null && await _hasPendingOps(item.id)) return false;
    return shouldApplyRemote(
      local: local == null
          ? null
          : (updatedAt: local.updatedAt, pendingPush: local.pendingPush),
      remoteUpdatedAt: item.updatedAt,
    );
  }

  @override
  Future<void> replaceCategories(List<SyncedCategory> items) =>
      _db.transaction(() async {
        await _db.delete(_db.localCategories).go();
        await _db.batch((b) {
          b.insertAll(_db.localCategories, [
            for (final c in items)
              LocalCategoriesCompanion.insert(
                id: c.id,
                userId: Value(c.userId),
                slug: Value(c.slug),
                name: c.name,
                icon: Value(c.icon),
                color: Value(c.color),
                fiscalTag: c.fiscalTag,
                isSystem: c.isSystem,
              ),
          ]);
        });
      });

  @override
  Future<void> replaceAccounts(List<SyncedAccount> items) =>
      _db.transaction(() async {
        await _db.delete(_db.localAccounts).go();
        await _db.batch((b) {
          b.insertAll(_db.localAccounts, [
            for (final a in items)
              LocalAccountsCompanion.insert(
                id: a.id,
                bank: a.bank,
                kind: a.kind,
                last4: Value(a.last4),
                alias: Value(a.alias),
              ),
          ]);
        });
        await _db.customUpdate(
          'UPDATE local_transactions SET account_id = NULL '
          'WHERE account_id IS NOT NULL AND pending_push = 0 '
          'AND account_id NOT IN (SELECT id FROM local_accounts)',
          updates: {_db.localTransactions},
        );
      });

  @override
  Future<void> replaceReview(List<SyncedReviewItem> items) =>
      _db.transaction(() async {
        final resolvedLocally = await _reviewItemsWithPendingOps();
        await _db.delete(_db.localReview).go();
        await _db.batch((b) {
          b.insertAll(_db.localReview, [
            for (final r in items)
              if (!resolvedLocally.contains(r.rawMessageId))
                LocalReviewCompanion.insert(
                  rawMessageId: r.rawMessageId,
                  channel: r.channel,
                  bank: Value(r.bank),
                  sender: r.sender,
                  receivedAt: r.receivedAt.toUtc(),
                  reason: r.reason,
                  partialExtract: jsonEncode(r.partialExtract),
                  messageText: Value(r.text),
                  createdAt: r.createdAt.toUtc(),
                ),
          ]);
        });
      });

  /// `rawMessageId` con convertir (en `related_id`) o descartar (en
  /// `target_id`) todavía en el outbox.
  Future<Set<String>> _reviewItemsWithPendingOps() async {
    final rows = await _db.select(_db.outbox).get();
    return {
      for (final row in rows)
        if (_decode(row)
            case ConvertReviewOp(
                  :final rawMessageId,
                ) ||
                DiscardReviewOp(:final rawMessageId))
          rawMessageId,
    };
  }

  @override
  Future<void> markSynced(DateTime at) =>
      _db.transaction(() => _writeState(_lastSyncedKey, _iso(at)));

  @override
  Stream<SyncCounters> watchCounters() => _db
      .customSelect(
        "SELECT (SELECT COUNT(*) FROM outbox WHERE status = 'pending') "
        'AS pending, '
        "(SELECT COUNT(*) FROM outbox WHERE status = 'rejected') AS rejected, "
        "(SELECT value FROM sync_state WHERE key = 'last_synced_at') AS last",
        readsFrom: {_db.outbox, _db.syncState},
      )
      .watchSingle()
      .map((row) {
        final last = row.read<String?>('last');
        return (
          pending: row.read<int>('pending'),
          rejected: row.read<int>('rejected'),
          lastSyncedAt: last == null ? null : DateTime.parse(last),
        );
      });

  @override
  Stream<int> watchOpenReviewCount() => _db
      .customSelect(
        'SELECT COUNT(*) AS c FROM local_review',
        readsFrom: {_db.localReview},
      )
      .watchSingle()
      .map((row) => row.read<int>('c'));

  // ------------------------------------------------ transacciones locales

  Future<LocalTransaction?> _findLocalTransaction(String id) => (_db.select(
    _db.localTransactions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> _deleteLocalTransaction(String id) => (_db.delete(
    _db.localTransactions,
  )..where((t) => t.id.equals(id))).go();

  Future<void> _updateLocalTransaction(
    String id,
    LocalTransactionsCompanion changes,
  ) => (_db.update(
    _db.localTransactions,
  )..where((t) => t.id.equals(id))).write(changes);

  Future<void> _insertLocalTransaction(String id, NewTransaction data) async {
    final now = _now();
    final kind =
        data.kind ??
        (data.direction == TxDirection.debit ? TxKind.expense : TxKind.income);
    await _db
        .into(_db.localTransactions)
        .insert(
          LocalTransactionsCompanion.insert(
            id: id,
            amountCents: data.amount.cents,
            currency: 'COP',
            direction: data.direction.name,
            kind: kind.name,
            occurredAt: data.occurredAt.toUtc(),
            merchant: Value(data.merchant),
            description: Value(data.description),
            accountId: Value(data.accountId),
            categoryId: Value(data.categoryId),
            fiscalTag: Value(await _fiscalTagOf(data.categoryId)),
            parsedBy: 'manual',
            notes: Value(data.notes),
            createdAt: now,
            updatedAt: now,
            pendingPush: const Value(true),
          ),
        );
  }

  Future<void> _applyPatch(String id, TransactionPatch patch) async {
    final categoryId = patch.categoryId;
    final fiscalTag = categoryId == null
        ? null
        : await _fiscalTagOf(categoryId);
    final kind = patch.kind;
    final notes = patch.notes;
    final merchant = patch.merchant;
    await _updateLocalTransaction(
      id,
      LocalTransactionsCompanion(
        categoryId: categoryId == null
            ? const Value.absent()
            : Value(categoryId),
        // Sin la categoría en local, el servidor corrige el tag al responder.
        fiscalTag: fiscalTag == null ? const Value.absent() : Value(fiscalTag),
        kind: kind == null ? const Value.absent() : Value(kind.name),
        notes: notes == null ? const Value.absent() : Value(notes.value),
        merchant: merchant == null
            ? const Value.absent()
            : Value(merchant.value),
        updatedAt: Value(_now()),
        pendingPush: const Value(true),
      ),
    );
  }

  /// Sin tocar `updatedAt`: la pareja no recibe la fila del servidor al
  /// completar, y un `updatedAt` local adelantado bloquearía el pull.
  Future<void> _setPair(String id, String pairId) => _updateLocalTransaction(
    id,
    LocalTransactionsCompanion(
      transferPairId: Value(pairId),
      kind: Value(TxKind.transfer.name),
      pendingPush: const Value(true),
    ),
  );

  Future<void> _clearPairOf(String id) async {
    final pairId = (await _findLocalTransaction(id))?.transferPairId;
    const cleared = LocalTransactionsCompanion(
      transferPairId: Value(null),
      pendingPush: Value(true),
    );
    await _updateLocalTransaction(id, cleared);
    if (pairId != null) await _updateLocalTransaction(pairId, cleared);
  }

  /// Si [id] se creó en local y el servidor no puede tenerlo (nunca se
  /// envió, o fue rechazado), borra todas sus operaciones y devuelve
  /// `true`: el borrado no se envía.
  ///
  /// También borra las operaciones que lo usan como pareja y limpia el
  /// `transfer_pair_id` que lo referencia.
  ///
  /// `attempts` cuenta envíos y se marca antes de enviar ([markSending]):
  /// si ya se envió (aunque siga en vuelo o la app muriera durante el
  /// request) el servidor pudo haberlo creado, así que el borrado se encola
  /// detrás (el canje de id lo reescribe).
  Future<bool> _cancelUnsentCreate(String id) async {
    final ops = await (_db.select(
      _db.outbox,
    )..where((o) => o.targetId.equals(id))).get();
    final unsent = ops.any(
      (row) =>
          _decode(row).createsRecord &&
          (row.status == _rejected || row.attempts == 0),
    );
    if (!unsent) return false;
    await _dropLocalRecord(id);
    return true;
  }

  /// Quita el registro local [id] que el servidor no tiene: su fila, sus
  /// operaciones y las que lo usan como pareja. Las filas que lo tenían de
  /// pareja la pierden y, si quedaron como transferencia, vuelven al tipo
  /// por dirección (débito → gasto, crédito → ingreso).
  Future<void> _dropLocalRecord(String id) async {
    final dependentOps = await (_db.select(
      _db.outbox,
    )..where((o) => o.relatedId.equals(id))).get();
    final pairedRows = await (_db.select(
      _db.localTransactions,
    )..where((t) => t.transferPairId.equals(id))).get();
    await (_db.delete(
      _db.outbox,
    )..where((o) => o.targetId.equals(id) | o.relatedId.equals(id))).go();
    await _unlinkPartnersOf(id);
    await _deleteLocalTransaction(id);
    final affected = {
      for (final row in dependentOps) row.targetId,
      for (final row in pairedRows) row.id,
    }..remove(id);
    for (final other in affected) {
      await _refreshPendingPush(other);
    }
  }

  /// Las filas que tenían a [id] de pareja la pierden y, si quedaron como
  /// transferencia, vuelven al tipo por dirección (débito → gasto,
  /// crédito → ingreso).
  Future<void> _unlinkPartnersOf(String id) => _db.customUpdate(
    'UPDATE local_transactions SET transfer_pair_id = NULL, '
    "kind = CASE WHEN kind = 'transfer' THEN "
    "CASE direction WHEN 'debit' THEN 'expense' ELSE 'income' END "
    'ELSE kind END '
    'WHERE transfer_pair_id = ?1',
    variables: [Variable.withString(id)],
    updates: {_db.localTransactions},
  );

  Future<void> _upsertServer(SyncedTransaction t) => _db
      .into(_db.localTransactions)
      .insertOnConflictUpdate(
        LocalTransactionsCompanion.insert(
          id: t.id,
          amountCents: t.amount.cents,
          currency: t.currency,
          direction: t.direction.name,
          kind: t.kind.name,
          occurredAt: t.occurredAt.toUtc(),
          merchant: Value(t.merchant),
          description: Value(t.description),
          bank: Value(t.bank),
          accountId: Value(t.accountId),
          categoryId: Value(t.categoryId),
          fiscalTag: Value(t.fiscalTag),
          transferPairId: Value(t.transferPairId),
          transferAuto: Value(t.transferAuto),
          parsedBy: t.parsedBy,
          confidence: Value(t.confidence),
          notes: Value(t.notes),
          createdAt: t.createdAt.toUtc(),
          updatedAt: t.updatedAt.toUtc(),
          pendingPush: const Value(false),
          channels: Value(jsonEncode(t.channels)),
        ),
      );

  /// Hay operaciones pendientes que tocan [id], como objetivo o como
  /// pareja. Las rechazadas no cuentan: no bloquean el pull.
  Future<bool> _hasPendingOps(String id) async {
    final row =
        await (_db.select(_db.outbox)
              ..where(
                (o) =>
                    o.status.equals(_pending) &
                    (o.targetId.equals(id) | o.relatedId.equals(id)),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// `pending_push` queda en `true` solo mientras haya operaciones
  /// pendientes para la fila.
  static const _pendingPushSql =
      'UPDATE local_transactions SET pending_push = EXISTS ( '
      "SELECT 1 FROM outbox WHERE status = 'pending' AND ( "
      'target_id = local_transactions.id OR '
      'related_id = local_transactions.id)) WHERE ';

  Future<void> _refreshPendingPush(String id) => _db.customUpdate(
    '${_pendingPushSql}id = ?1',
    variables: [Variable.withString(id)],
    updates: {_db.localTransactions},
  );

  /// Para todas las filas marcadas.
  Future<void> _refreshAllPendingPush() => _db.customUpdate(
    '${_pendingPushSql}pending_push = 1',
    updates: {_db.localTransactions},
  );

  Future<String?> _fiscalTagOf(String? categoryId) async {
    if (categoryId == null) return null;
    final category = await (_db.select(
      _db.localCategories,
    )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
    return category?.fiscalTag;
  }

  Future<void> _deleteReviewItem(String rawMessageId) => (_db.delete(
    _db.localReview,
  )..where((r) => r.rawMessageId.equals(rawMessageId))).go();

  // ------------------------------------------------------------ utilidades

  OutboxOperation _decode(OutboxRow row) => OutboxCodec.decode(
    kind: row.kind,
    targetId: row.targetId,
    relatedId: row.relatedId,
    payload: row.payload,
  );

  Future<String?> _readState(String key) async {
    final row = await (_db.select(
      _db.syncState,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _writeState(String key, String value) => _db
      .into(_db.syncState)
      .insertOnConflictUpdate(
        SyncStateCompanion.insert(key: key, value: value),
      );

  static String _iso(DateTime at) => at.toUtc().toIso8601String();
}
