import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/routing/routes.dart';
import 'package:finanzia/core/theme/tokens/spacing.dart';
import 'package:finanzia/core/time/colombia_month.dart';
import 'package:finanzia/features/auth/application/auth_controller.dart';
import 'package:finanzia/features/dashboard/application/dashboard_controller.dart';
import 'package:finanzia/features/dashboard/domain/monthly_summary.dart';
import 'package:finanzia/features/dashboard/presentation/widgets/dashboard_format.dart';
import 'package:finanzia/features/dashboard/presentation/widgets/dashboard_hero.dart';
import 'package:finanzia/features/dashboard/presentation/widgets/dashboard_states.dart';
import 'package:finanzia/features/dashboard/presentation/widgets/top_categories_card.dart';
import 'package:finanzia/features/sync/application/sync_coordinator.dart';
import 'package:finanzia/features/transactions/application/transactions_list_controller.dart';
import 'package:finanzia/features/transactions/domain/transaction_filter.dart';
import 'package:finanzia/features/transactions/presentation/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Inicio (F4.6, diseño A "Balance protagonista", spec 008 §3.2): balance
/// del mes, gastos e ingresos contra el mes anterior y "En qué se fue".
/// Las cifras se calculan en local, sin red.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(dashboardControllerProvider);
    final controller = ref.read(dashboardControllerProvider.notifier);
    final sync = ref.watch(syncCoordinatorProvider);
    final user = switch (ref.watch(authControllerProvider)) {
      AsyncData(value: Authenticated(:final user)) => user,
      _ => null,
    };
    final summary = state.summary.value;
    final shown = summary != null && hasMovements(summary) ? summary : null;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        // La banda esmeralda va detrás de la barra de estado en ambos temas.
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHero(
                greeting: l10n.homeGreeting(user?.greetingName ?? ''),
                syncLine: syncLine(l10n, sync),
                month: state.month,
                canGoNext: state.canGoNext,
                onPrevious: controller.previousMonth,
                onNext: controller.nextMonth,
                summary: shown,
              ),
              if (sync.offline)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.md,
                    Space.md,
                    Space.md,
                    0,
                  ),
                  child: OfflineBanner(message: l10n.dashboardOffline),
                ),
              Padding(
                padding: const EdgeInsets.all(Space.md),
                child: _body(context, ref, state, sync, shown),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    DashboardState state,
    SyncStatus sync,
    MonthlySummary? shown,
  ) {
    final controller = ref.read(dashboardControllerProvider.notifier);
    if (shown != null) {
      // Mientras Drift emite el mes nuevo se ven las cifras del anterior:
      // abrir una categoría mezclaría ese gasto con el mes del encabezado.
      final stale = shown.month != state.month;
      return TopCategoriesCard(
        summary: shown,
        onOpen: stale
            ? null
            : (id) => _openCategory(context, ref, shown.month, id),
      );
    }
    final firstSync = sync.lastSyncedAt == null && sync.running;
    final summary = state.summary;
    if (!summary.hasValue && summary.hasError) {
      return DashboardLoadError(onRetry: controller.retry);
    }
    if (firstSync) return const DashboardFirstSync();
    if (!summary.hasValue) return const DashboardSkeleton();
    return DashboardEmptyMonth(
      monthName: monthName(state.month),
      currentMonthName: monthName(state.currentMonth),
      onBackToCurrent: state.month == state.currentMonth
          ? null
          : controller.showCurrentMonth,
    );
  }

  /// Movimientos con el mes y la categoría del Inicio (el resto del filtro
  /// vuelve al de por defecto).
  void _openCategory(
    BuildContext context,
    WidgetRef ref,
    ColombiaMonth month,
    String categoryId,
  ) {
    final range = month.range();
    ref
        .read(transactionsListControllerProvider.notifier)
        .setFilter(
          TransactionFilter(
            period: PeriodPreset.custom,
            from: range.from,
            to: range.to,
            categoryId: categoryId,
          ),
        );
    context.go(Routes.transactions);
  }
}
