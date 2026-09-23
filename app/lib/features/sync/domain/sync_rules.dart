import 'package:finanzia/features/sync/domain/outbox_operation.dart';

typedef LocalVersion = ({DateTime updatedAt, bool pendingPush});

/// Regla de conflicto (spec 003 §3): una edición local pendiente siempre
/// gana; si no hay, gana el `updated_at` más reciente (empate: servidor).
bool shouldApplyRemote({
  required LocalVersion? local,
  required DateTime remoteUpdatedAt,
}) {
  if (local == null) return true;
  if (local.pendingPush) return false;
  return !remoteUpdatedAt.isBefore(local.updatedAt);
}

/// Fallo al hablar con el backend, sin depender de dio.
final class RemoteFailure implements Exception {
  const RemoteFailure({this.statusCode, this.code, this.retryAfter})
    : isNetwork = false;
  const RemoteFailure.network()
    : statusCode = null,
      code = null,
      retryAfter = null,
      isNetwork = true;

  final int? statusCode;
  final String? code;
  final Duration? retryAfter;
  final bool isNetwork;

  @override
  String toString() => 'RemoteFailure($statusCode, $code, network: $isNetwork)';
}

enum PushOutcome { done, retryLater, sessionEnded, rejected }

PushOutcome classifyPushFailure(OutboxOperation op, RemoteFailure failure) {
  final status = failure.statusCode;
  if (failure.isNetwork || status == null) return PushOutcome.retryLater;
  return switch ((status, op)) {
    (401, _) => PushOutcome.sessionEnded,
    (429, _) => PushOutcome.retryLater,
    (>= 500, _) => PushOutcome.retryLater,
    (409, _) when failure.retryAfter != null => PushOutcome.retryLater,
    (404, DeleteTransactionOp()) => PushOutcome.done,
    (409, DiscardReviewOp()) => PushOutcome.done,
    // Ya resuelta en otro dispositivo o vencida: el pull trae lo que haya.
    (409 || 404, ConvertReviewOp()) => PushOutcome.done,
    _ => PushOutcome.rejected,
  };
}
