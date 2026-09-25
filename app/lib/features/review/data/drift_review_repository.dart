import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finanzia/core/db/app_database.dart';
import 'package:finanzia/features/review/domain/review_item.dart';
import 'package:finanzia/features/review/domain/review_repository.dart';

/// [ReviewRepository] sobre `local_review` en Drift. La tabla la llena el
/// pull (`DriftSyncStore.replaceReview`) y convertir o descartar borran la
/// fila en local, así que el stream ya refleja las acciones optimistas.
class DriftReviewRepository implements ReviewRepository {
  DriftReviewRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ReviewItem>> watchOpen() {
    final query = _db.select(_db.localReview)
      ..orderBy([
        (r) => OrderingTerm.desc(r.receivedAt),
        (r) => OrderingTerm.desc(r.rawMessageId),
      ]);
    return query.watch().map((rows) => [for (final row in rows) _toItem(row)]);
  }

  @override
  Stream<ReviewItem?> watchOne(String rawMessageId) {
    final query = _db.select(_db.localReview)
      ..where((r) => r.rawMessageId.equals(rawMessageId));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toItem(row),
    );
  }

  static ReviewItem _toItem(LocalReviewRow row) => ReviewItem(
    rawMessageId: row.rawMessageId,
    channel: row.channel,
    bank: row.bank,
    sender: row.sender,
    receivedAt: row.receivedAt,
    reason: row.reason,
    partialExtract: _extract(row.partialExtract),
    text: row.messageText,
  );

  /// `partial_extract` guardado como JSON; se quedan solo los valores de
  /// texto (el contrato es `dict[str, str]`).
  static Map<String, String> _extract(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) return const {};
    return {
      for (final MapEntry(:key, :value) in decoded.entries)
        if (value is String) key: value,
    };
  }
}
