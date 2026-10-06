import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:luka/core/db/app_database.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/sync_ports.dart';
import 'package:luka/features/sync/domain/sync_rules.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/domain/search.dart';
import 'package:luka/features/transactions/domain/transaction_filter.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';
import 'package:luka/features/transactions/domain/transactions_repository.dart';

/// [TransactionsRepository] sobre la base local Drift (spec 003 §3).
///
/// Una sola proyección sirve a la lista y al detalle: `local_transactions`
/// con left join a su categoría y su cuenta, más dos `EXISTS` sobre el
/// outbox para el sello de sync. Drift registra las tablas de los `FROM`
/// de las subconsultas como leídas, así que los streams también se
/// reemiten cuando cambia el outbox.
class DriftTransactionsRepository implements TransactionsRepository {
  DriftTransactionsRepository(
    this._db,
    this._remote, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final SyncRemote _remote;
  final DateTime Function() _now;

  static const _pending = 'pending';
  static const _rejected = 'rejected';
  static const _uncategorizedSlug = 'sin_categoria';

  // ---------------------------------------------------------------- lista

  @override
  Stream<List<TransactionView>> watch(
    TransactionFilter filter, {
    required int limit,
  }) {
    final t = _db.localTransactions;
    final range = filter.range(_now());
    final query = _projection()
      ..where(
        t.occurredAt.isBiggerOrEqualValue(range.from) &
            t.occurredAt.isSmallerThanValue(range.to),
      );
    if (filter.kinds.isNotEmpty) {
      query.where(t.kind.isIn([for (final k in filter.kinds) k.name]));
    }
    if (filter.banks.isNotEmpty) query.where(t.bank.isIn(filter.banks));
    if (filter.accountIds.isNotEmpty) {
      query.where(t.accountId.isIn(filter.accountIds));
    }
    if (filter.categoryId case final categoryId?) {
      query.where(_inCategory(categoryId));
    }
    query.orderBy([
      OrderingTerm.desc(t.occurredAt),
      OrderingTerm.desc(t.id),
    ]);

    // Canales (JSON) y texto se filtran en Dart. Si hay alguno activo, el
    // límite se aplica después de filtrar; si no, en SQL.
    final filtersInDart =
        filter.channels.isNotEmpty || filter.text.trim().isNotEmpty;
    if (!filtersInDart) query.limit(limit);

    return query.watch().map((rows) {
      final views = rows.map(_toView);
      if (!filtersInDart) return views.toList();
      return views
          .where(
            (v) =>
                (filter.channels.isEmpty ||
                    v.channels.any(filter.channels.contains)) &&
                matchesText(v, filter.text),
          )
          .take(limit)
          .toList();
    });
  }

  /// `category_id = :id`, y si :id es la fila `sin_categoria` también
  /// `category_id IS NULL`: el mismo reparto del Inicio
  /// (`DriftInsightsRepository` + `buildSummary`), así "Sin categoría"
  /// abre los mismos movimientos que suma.
  ///
  /// ```sql
  /// t.category_id = :id
  /// OR (t.category_id IS NULL AND :id = (SELECT id FROM local_categories
  ///       WHERE slug = 'sin_categoria' LIMIT 1))
  /// ```
  Expression<bool> _inCategory(String categoryId) {
    final t = _db.localTransactions;
    final u = _db.alias(_db.localCategories, 'uncategorized');
    final uncategorizedId = subqueryExpression<String>(
      _db.selectOnly(u)
        ..addColumns([u.id])
        ..where(u.slug.equals(_uncategorizedSlug))
        ..limit(1),
    );
    return t.categoryId.equals(categoryId) |
        (t.categoryId.isNull() & uncategorizedId.equals(categoryId));
  }

  // -------------------------------------------------------------- detalle

  @override
  Stream<TransactionView?> watchOne(String id) {
    final query = _projection()..where(_db.localTransactions.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toView(row),
    );
  }

  // ----------------------------------------------------------- categorías

  @override
  Stream<List<CategoryOption>> watchCategories() {
    final c = _db.localCategories;
    final query = _db.select(c)
      ..where((c) => c.slug.isNull() | c.slug.isNotValue(_uncategorizedSlug));
    return query.watch().map((rows) {
      return [
        for (final row in rows)
          CategoryOption(
            id: row.id,
            name: row.name,
            isSystem: row.isSystem,
            slug: row.slug,
            icon: row.icon,
            color: row.color,
            fiscalTag: row.fiscalTag,
          ),
      ]..sort(_categoryOrder);
    });
  }

  /// Sistema primero; luego por nombre sin tildes (SQLite ordena por bytes
  /// y dejaría "Árbol" después de "Zapatos").
  static int _categoryOrder(CategoryOption a, CategoryOption b) {
    if (a.isSystem != b.isSystem) return a.isSystem ? -1 : 1;
    return normalizeForSearch(a.name).compareTo(normalizeForSearch(b.name));
  }

  // --------------------------------------------------------------- fuentes

  @override
  Future<List<TxSource>?> fetchSources(String id) async {
    final TransactionDetail? detail;
    try {
      detail = await _remote.fetchTransactionDetail(id);
    } on RemoteFailure {
      return null;
    }
    // 404: el servidor aún no la tiene (creación local sin enviar).
    if (detail == null) return const [];
    return [
      for (final source in detail.sources)
        if (TxChannel.fromWire(source.channel) case final channel?)
          (channel: channel, receivedAt: source.receivedAt),
    ];
  }

  // ----------------------------------------------------------- proyección

  late final Expression<bool> _hasPending = _outboxExists(_pending);
  late final Expression<bool> _hasRejected = _outboxExists(_rejected);

  /// `EXISTS` de una operación con [status] que toca la fila, como objetivo
  /// o como pareja (`related_id`).
  Expression<bool> _outboxExists(String status) {
    final o = _db.outbox;
    final id = _db.localTransactions.id;
    return existsQuery(
      _db.selectOnly(o)
        ..addColumns([o.seq])
        ..where(
          o.status.equals(status) &
              (o.targetId.equalsExp(id) | o.relatedId.equalsExp(id)),
        ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _projection() {
    final t = _db.localTransactions;
    final c = _db.localCategories;
    final a = _db.localAccounts;
    return _db.select(t).join([
      leftOuterJoin(c, c.id.equalsExp(t.categoryId)),
      leftOuterJoin(a, a.id.equalsExp(t.accountId)),
    ])..addColumns([_hasPending, _hasRejected]);
  }

  TransactionView _toView(TypedResult row) {
    final tx = row.readTable(_db.localTransactions);
    final category = row.readTableOrNull(_db.localCategories);
    final account = row.readTableOrNull(_db.localAccounts);
    // Un rechazo pide acción del usuario: gana sobre lo pendiente.
    final sync = (row.read(_hasRejected) ?? false)
        ? SyncMark.rejected
        : (row.read(_hasPending) ?? false)
        ? SyncMark.pending
        : SyncMark.none;
    return TransactionView(
      id: tx.id,
      amount: Cop(tx.amountCents),
      direction: TxDirection.values.byName(tx.direction),
      kind: TxKind.values.byName(tx.kind),
      occurredAt: tx.occurredAt,
      channels: _decodeChannels(tx.channels),
      sync: sync,
      merchant: tx.merchant,
      categoryId: tx.categoryId,
      categoryName: category?.name,
      categorySlug: category?.slug,
      bank: tx.bank,
      accountId: tx.accountId,
      accountBank: account?.bank,
      accountKind: account?.kind,
      accountLast4: account?.last4,
      accountAlias: account?.alias,
      notes: tx.notes,
      transferPairId: tx.transferPairId,
      parsedBy: tx.parsedBy,
    );
  }

  /// `channels` es un arreglo JSON de strings del cable; los desconocidos
  /// se ignoran.
  static Set<TxChannel> _decodeChannels(String json) => {
    for (final wire in (jsonDecode(json) as List<dynamic>).cast<String>())
      ?TxChannel.fromWire(wire),
  };
}
