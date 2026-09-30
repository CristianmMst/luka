import 'package:luka/core/format/money.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/recurring/domain/recurring_draft.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';

/// Por qué no se pudo hacer una acción sobre gastos fijos.
sealed class RecurringFailure implements Exception {
  const RecurringFailure({this.statusCode});

  /// HTTP que la causó, si hubo respuesta (el sync distingue el 401).
  final int? statusCode;
}

/// Sin conexión: los gastos fijos se cambian solo en línea.
final class RecurringOffline extends RecurringFailure {
  const RecurringOffline();
}

/// 404: el gasto fijo, la ocurrencia o el movimiento ya no existen.
final class RecurringGone extends RecurringFailure {
  const RecurringGone() : super(statusCode: 404);
}

/// 409: el movimiento ya paga otro gasto fijo, o la ocurrencia ya estaba
/// pendiente.
final class RecurringConflict extends RecurringFailure {
  const RecurringConflict() : super(statusCode: 409);
}

/// Cualquier otro fallo (400, 5xx, respuesta fuera de contrato).
final class RecurringUnexpected extends RecurringFailure {
  const RecurringUnexpected({super.statusCode});
}

/// `/v1/recurring-expenses` y `/v1/recurring-occurrences` (spec 005 §10).
/// Falla con [RecurringFailure].
abstract interface class RecurringRemote {
  Future<List<RecurringExpense>> expenses();

  /// Ocurrencias con `period` de [from] a [to] (incluidos).
  Future<List<RecurringOccurrence>> occurrences(
    ColombiaMonth from,
    ColombiaMonth to,
  );
  Future<RecurringExpense> create(RecurringDraft draft);
  Future<RecurringExpense> update(String id, RecurringDraft draft);
  Future<RecurringExpense> setActive(String id, {required bool active});
  Future<void> delete(String id);
  Future<RecurringOccurrence> markPaid(String id, {String? transactionId});
  Future<RecurringOccurrence> unmark(String id);
  Future<RecurringOccurrence> skip(String id);
}

/// Copia local (Drift) de los gastos fijos y sus ocurrencias.
abstract interface class RecurringStore {
  /// Todos, activos y pausados, por día y nombre.
  Stream<List<RecurringExpense>> watchExpenses();

  /// Las del mes, por vencimiento y nombre.
  Stream<List<RecurringOccurrence>> watchOccurrences(ColombiaMonth month);

  /// Reemplaza la copia entera (en cada sync).
  Future<void> replaceAll(
    List<RecurringExpense> expenses,
    List<RecurringOccurrence> occurrences,
  );
  Future<void> upsertExpense(RecurringExpense expense);

  /// Quita el gasto fijo y sus ocurrencias.
  Future<void> removeExpense(String id);
  Future<void> upsertOccurrence(RecurringOccurrence occurrence);

  /// Gastos locales dentro de la ventana de [dueDate] (±5 días), los de
  /// monto más cercano a [expected] primero.
  Future<List<PaymentCandidate>> candidates(DateTime dueDate, Cop expected);
}
