import 'dart:async';

import 'package:finanzia/core/time/colombia_month.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/dashboard/application/dashboard_providers.dart';
import 'package:finanzia/features/dashboard/domain/monthly_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_controller.freezed.dart';

@freezed
abstract class DashboardState with _$DashboardState {
  const factory DashboardState({
    /// Mes que se muestra.
    required ColombiaMonth month,

    /// Mes en curso según el reloj, el tope de la navegación.
    required ColombiaMonth currentMonth,
    required AsyncValue<MonthlySummary> summary,
  }) = _DashboardState;

  const DashboardState._();

  /// No hay meses futuros: "›" se deshabilita en el mes en curso.
  bool get canGoNext => month.isBefore(currentMonth);
}

/// Inicio (F4.6): mes seleccionado y su resumen en vivo desde
/// `InsightsRepository.watchMonth`.
///
/// Arranca en el mes en curso. El mes es del usuario: al cerrar sesión o
/// entrar con otra cuenta el controlador se reconstruye en el mes en curso.
class DashboardController extends Notifier<DashboardState> {
  StreamSubscription<MonthlySummary>? _subscription;

  @override
  DashboardState build() {
    ref
      ..watch(authControllerProvider.select(_sessionUserId))
      ..onDispose(() => unawaited(_subscription?.cancel()));
    final current = _currentMonth();
    _subscribe(current);
    return DashboardState(
      month: current,
      currentMonth: current,
      summary: const AsyncLoading(),
    );
  }

  static String? _sessionUserId(AsyncValue<AuthState> auth) =>
      switch (auth.value) {
        Authenticated(:final user) => user.id,
        _ => null,
      };

  ColombiaMonth _currentMonth() =>
      ColombiaMonth.containing(ref.read(dashboardClockProvider)());

  void previousMonth() => _show(state.month.previous, _currentMonth());

  /// Avanza un mes sin pasar del mes en curso.
  void nextMonth() {
    final current = _currentMonth();
    final next = state.month.next;
    if (next.isAfter(current)) {
      state = state.copyWith(currentMonth: current);
      return;
    }
    _show(next, current);
  }

  void _show(ColombiaMonth month, ColombiaMonth current) {
    state = state.copyWith(
      month: month,
      currentMonth: current,
      summary: const AsyncLoading(),
    );
    _subscribe(month);
  }

  void _subscribe(ColombiaMonth month) {
    unawaited(_subscription?.cancel());
    _subscription = ref
        .read(insightsRepositoryProvider)
        .watchMonth(month)
        .listen(
          (summary) => state = state.copyWith(summary: AsyncData(summary)),
          onError: (Object error, StackTrace stack) =>
              state = state.copyWith(summary: AsyncError(error, stack)),
        );
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );
