import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/recurring/domain/recurring_draft.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/recurring_ports.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/domain/sync_ports.dart';
import 'package:luka/features/sync/domain/sync_rules.dart';

/// Puertos de gastos fijos; se sobrescriben en `lib/app/composition.dart`.
final recurringRemoteProvider = Provider<RecurringRemote>(
  (ref) => throw UnimplementedError(
    'recurringRemoteProvider se sobrescribe en la composición',
  ),
);
final recurringStoreProvider = Provider<RecurringStore>(
  (ref) => throw UnimplementedError(
    'recurringStoreProvider se sobrescribe en la composición',
  ),
);

/// Reloj de la feature (los tests lo fijan).
final recurringClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Gastos fijos propios, activos y pausados.
final StreamProvider<List<RecurringExpense>> recurringExpensesProvider =
    StreamProvider.autoDispose<List<RecurringExpense>>(
      (ref) => ref.watch(recurringStoreProvider).watchExpenses(),
    );

/// Ocurrencias de un mes, por vencimiento.
final StreamProviderFamily<List<RecurringOccurrence>, ColombiaMonth>
recurringOccurrencesProvider = StreamProvider.autoDispose
    .family<List<RecurringOccurrence>, ColombiaMonth>(
      (ref, month) => ref.watch(recurringStoreProvider).watchOccurrences(month),
    );

/// El borrador no se puede enviar; [errors] dice por qué.
class InvalidRecurringDraft implements Exception {
  const InvalidRecurringDraft(this.errors);

  final Set<RecurringDraftError> errors;

  @override
  String toString() => 'InvalidRecurringDraft($errors)';
}

/// Crear, editar, pausar y borrar gastos fijos, y marcar sus ocurrencias
/// (spec 005 §10). Van directo al servidor, sin outbox: sin conexión fallan
/// con `RecurringOffline`. Tras un éxito la copia local se actualiza al
/// instante; crear o editar además pide un sync para traer las ocurrencias
/// que el servidor generó o tachó.
class RecurringActions {
  RecurringActions({
    required RecurringRemote remote,
    required RecurringStore store,
    required void Function() requestSync,
  }) : _remote = remote,
       _store = store,
       _requestSync = requestSync;

  final RecurringRemote _remote;
  final RecurringStore _store;
  final void Function() _requestSync;

  Future<RecurringExpense> create(RecurringDraft draft) async {
    final created = await _remote.create(_checked(draft));
    await _store.upsertExpense(created);
    _requestSync();
    return created;
  }

  Future<RecurringExpense> update(String id, RecurringDraft draft) async {
    final updated = await _remote.update(id, _checked(draft));
    await _store.upsertExpense(updated);
    _requestSync();
    return updated;
  }

  /// Pausar borra en el servidor las ocurrencias futuras; reanudar las
  /// vuelve a crear. El sync trae el resultado.
  Future<RecurringExpense> setActive(String id, {required bool active}) async {
    final updated = await _remote.setActive(id, active: active);
    await _store.upsertExpense(updated);
    _requestSync();
    return updated;
  }

  Future<void> delete(String id) async {
    await _remote.delete(id);
    await _store.removeExpense(id);
  }

  Future<RecurringOccurrence> markPaid(String id, {String? transactionId}) =>
      _apply(() => _remote.markPaid(id, transactionId: transactionId));

  Future<RecurringOccurrence> unmark(String id) =>
      _apply(() => _remote.unmark(id));

  Future<RecurringOccurrence> skip(String id) => _apply(() => _remote.skip(id));

  Future<RecurringOccurrence> _apply(
    Future<RecurringOccurrence> Function() call,
  ) async {
    final occurrence = await call();
    await _store.upsertOccurrence(occurrence);
    return occurrence;
  }

  RecurringDraft _checked(RecurringDraft draft) {
    final errors = draft.validate();
    if (errors.isNotEmpty) throw InvalidRecurringDraft(errors);
    return draft.copyWith(name: draft.cleanName);
  }
}

final recurringActionsProvider = Provider<RecurringActions>(
  (ref) => RecurringActions(
    remote: ref.watch(recurringRemoteProvider),
    store: ref.watch(recurringStoreProvider),
    requestSync: () =>
        unawaited(ref.read(syncCoordinatorProvider.notifier).sync()),
  ),
);

/// Snapshot de gastos fijos para el pull (spec 005 §9): los gastos y las
/// ocurrencias del mes anterior al siguiente, que reemplazan la copia local.
class RecurringSnapshot implements SyncSnapshot {
  RecurringSnapshot({
    required RecurringRemote remote,
    required RecurringStore store,
    required DateTime Function() now,
  }) : _remote = remote,
       _store = store,
       _now = now;

  final RecurringRemote _remote;
  final RecurringStore _store;
  final DateTime Function() _now;

  @override
  Future<void> refresh() async {
    final month = ColombiaMonth.containing(_now());
    try {
      final expenses = await _remote.expenses();
      final occurrences = await _remote.occurrences(
        month.previous,
        month.next,
      );
      await _store.replaceAll(expenses, occurrences);
    } on RecurringOffline {
      throw const RemoteFailure.network();
    } on RecurringFailure catch (failure) {
      throw RemoteFailure(statusCode: failure.statusCode, code: 'recurring');
    }
  }
}

final recurringSnapshotProvider = Provider<RecurringSnapshot>(
  (ref) => RecurringSnapshot(
    remote: ref.watch(recurringRemoteProvider),
    store: ref.watch(recurringStoreProvider),
    now: ref.watch(recurringClockProvider),
  ),
);
