import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/recurring/application/recurring_actions.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';
import 'package:luka/features/recurring/domain/reminder_plan.dart';

/// Programador de avisos locales; en iPhone la composición lo reemplaza
/// (spec 011 §5.1). En Android no programa nada.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => const NoReminderScheduler(),
);

/// Mantiene programados en el teléfono los avisos de los gastos fijos del
/// mes actual y del siguiente: cada cambio en Drift (sync, marcar pagado,
/// pausar…) los reprograma, así un pago tachado cancela su aviso.
class LocalReminderSync extends Notifier<void> {
  List<RecurringExpense>? _expenses;
  final _occurrences = <ColombiaMonth, List<RecurringOccurrence>>{};
  List<LocalReminder>? _scheduled;
  Future<void> _queue = Future.value();

  @override
  void build() {
    if (ref.read(reminderSchedulerProvider) is NoReminderScheduler) return;
    final store = ref.read(recurringStoreProvider);
    final now = ref.read(recurringClockProvider);
    final month = ColombiaMonth.containing(now());
    final subs = <StreamSubscription<Object?>>[
      store.watchExpenses().listen((items) {
        _expenses = items;
        _reschedule();
      }),
      for (final m in [month, month.next])
        store.watchOccurrences(m).listen((items) {
          _occurrences[m] = items;
          _reschedule();
        }),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
    });
  }

  void _reschedule() {
    final expenses = _expenses;
    if (expenses == null || _occurrences.length < 2) return;
    final planned = plannedReminders(
      occurrences: [for (final items in _occurrences.values) ...items],
      expenses: expenses,
      now: ref.read(recurringClockProvider)(),
    );
    // Sin cambios, no se toca el sistema.
    if (listEquals(planned, _scheduled)) return;
    _scheduled = planned;
    _queue = _queue
        .then((_) => ref.read(reminderSchedulerProvider).replaceAll(planned))
        // Solo el tipo (P1).
        .catchError(
          (Object e) => debugPrint('[recordatorios] ${e.runtimeType}'),
        );
  }

  /// Espera a que termine la última reprogramación (tests).
  @visibleForTesting
  Future<void> settle() => _queue;
}

final localReminderSyncProvider = NotifierProvider<LocalReminderSync, void>(
  LocalReminderSync.new,
);
