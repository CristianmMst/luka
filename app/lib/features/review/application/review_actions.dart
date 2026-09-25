import 'package:finanzia/features/review/domain/review_draft.dart';
import 'package:finanzia/features/review/domain/review_item.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/sync/domain/outbox_operation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Convertir o descartar un mensaje en revisión (AC-8.1). Las dos son
/// optimistas: el mensaje sale de la lista en local y la operación se
/// encola en el outbox (P4, spec 005 §9).
class ReviewActions {
  ReviewActions(this._coordinator);

  final SyncCoordinator _coordinator;

  /// Crea la transacción de [item] con el borrador del formulario.
  ///
  /// Lanza [InvalidReviewDraft] sin encolar nada si falta el monto (o es
  /// cero), la dirección o la fecha. La fecha puede venir en hora local o
  /// UTC: el wire la envía como ISO 8601 en UTC.
  Future<void> convert(ReviewItem item, ReviewDraft draft) async {
    final errors = draft.validate();
    if (errors.isNotEmpty) throw InvalidReviewDraft(errors);
    final merchant = draft.merchant?.trim();
    await _coordinator.enqueue(
      OutboxOperation.convertReview(
        rawMessageId: item.rawMessageId,
        localId: _coordinator.newLocalId(),
        data: NewTransaction(
          amount: draft.amount!,
          direction: draft.direction!,
          occurredAt: draft.occurredAt!,
          merchant: merchant == null || merchant.isEmpty ? null : merchant,
          categoryId: draft.categoryId,
        ),
      ),
    );
  }

  /// Descarta [item]: no era un movimiento.
  Future<void> discard(ReviewItem item) => _coordinator.enqueue(
    OutboxOperation.discardReview(rawMessageId: item.rawMessageId),
  );
}

final reviewActionsProvider = Provider<ReviewActions>(
  (ref) => ReviewActions(ref.watch(syncCoordinatorProvider.notifier)),
);
