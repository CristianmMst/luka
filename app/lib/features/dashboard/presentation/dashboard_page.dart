import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/routing/routes.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/features/auth/application/auth_controller.dart';
import 'package:luka/features/capture/presentation/widgets/capture_stopped_strip.dart';
import 'package:luka/features/dashboard/application/dashboard_controller.dart';
import 'package:luka/features/dashboard/domain/monthly_summary.dart';
import 'package:luka/features/dashboard/presentation/widgets/dashboard_format.dart';
import 'package:luka/features/dashboard/presentation/widgets/dashboard_hero.dart';
import 'package:luka/features/dashboard/presentation/widgets/dashboard_states.dart';
import 'package:luka/features/dashboard/presentation/widgets/dashboard_totals_card.dart';
import 'package:luka/features/dashboard/presentation/widgets/month_switcher.dart';
import 'package:luka/features/dashboard/presentation/widgets/top_categories_card.dart';
import 'package:luka/features/recurring/presentation/upcoming_payments_card.dart';
import 'package:luka/features/sync/application/sync_coordinator.dart';
import 'package:luka/features/sync/presentation/sync_refresh.dart';
import 'package:luka/features/transactions/application/transactions_list_controller.dart';
import 'package:luka/features/transactions/domain/transaction_filter.dart';
import 'package:luka/features/transactions/presentation/widgets/offline_banner.dart';

/// Inicio (F4.6, diseño Q, spec 008 §3.2): banda tomate con el balance del
/// mes, gastos e ingresos contra el mes anterior y "En qué se fue".
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

    final scheme = Theme.of(context).colorScheme;
    // Con cifras, la tarjeta de gastos e ingresos se monta sobre la banda.
    final overlap = shown != null ? DashboardTotalsCard.overlap : 0.0;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        // La banda tomate va detrás de la barra de estado en ambos temas.
        value: SystemUiOverlayStyle.light,
        child: SyncRefresh(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // La barra translúcida va encima: su alto entra en el margen.
            padding: EdgeInsets.only(
              bottom:
                  (overlap > 0 ? 0 : Space.md) +
                  MediaQuery.paddingOf(context).bottom,
            ),
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
                  alert: const CaptureStoppedStrip(),
                  overlap: overlap,
                ),
                // Subir el resto [overlap] px deja ese mismo blanco al final
                // del scroll, que hace de margen inferior.
                Transform.translate(
                  offset: Offset(0, -overlap),
                  // Al cambiar de mes, entra por el lado del elegido.
                  child: MonthSwitcher(
                    month: state.month,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (shown != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.md,
                            ),
                            child: DashboardTotalsCard(summary: shown),
                          ),
                        if (sync.offline)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Space.md,
                              Space.md,
                              Space.md,
                              0,
                            ),
                            child: OfflineBanner(
                              message: l10n.dashboardOffline,
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            Space.md,
                            shown != null ? 28 : Space.md,
                            Space.md,
                            Space.md,
                          ),
                          child: _body(context, ref, state, sync, shown),
                        ),
                        // Gastos fijos del mes elegido (spec 008 §3.2, F7.6).
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.md,
                          ),
                          child: UpcomingPaymentsCard(month: state.month),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
