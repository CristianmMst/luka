import 'package:finanzia/features/sync/domain/sync_rules.dart';

/// Máximo de ítems por lote que acepta el backend (spec 005 §5).
const ingestBatchLimit = 50;

/// La config de captura se vuelve a pedir pasado este tiempo, como su
/// `Cache-Control: max-age=3600`.
const captureConfigMaxAge = Duration(hours: 1);

enum IngestOutcome {
  /// Sin red o el servidor no pudo: el lote queda en la cola.
  retryLater,

  /// 401: la sesión terminó; se envía al volver a entrar.
  sessionEnded,

  /// El servidor rechazó el lote: reenviarlo igual no sirve.
  invalid,
}

/// Qué hacer con un lote que falló, con las reglas de reintento del outbox
/// (spec 005 §9).
IngestOutcome classifyIngestFailure(RemoteFailure failure) {
  final status = failure.statusCode;
  if (failure.isNetwork || status == null) return IngestOutcome.retryLater;
  return switch (status) {
    401 => IngestOutcome.sessionEnded,
    429 || >= 500 => IngestOutcome.retryLater,
    409 when failure.retryAfter != null => IngestOutcome.retryLater,
    _ => IngestOutcome.invalid,
  };
}
