import 'package:flutter/material.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';

/// Estados del Inicio sin resumen que mostrar (diseño "Estados").

/// "Sin movimientos en julio"; con [onBackToCurrent] ofrece volver al mes
/// en curso ([currentMonthName]).
class DashboardEmptyMonth extends StatelessWidget {
  const DashboardEmptyMonth({
    required this.monthName,
    required this.currentMonthName,
    this.onBackToCurrent,
    super.key,
  });

  final String monthName;
  final String currentMonthName;
  final VoidCallback? onBackToCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return _StateCard(
      art: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: ExcludeSemantics(
          child: Icon(
            Icons.calendar_month_outlined,
            size: 26,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
      title: l10n.dashboardEmptyTitle(monthName),
      body: l10n.dashboardEmptyBody,
      action: onBackToCurrent == null
          ? null
          : FilledButton(
              onPressed: onBackToCurrent,
              child: Text(l10n.dashboardBackToMonth(currentMonthName)),
            ),
    );
  }
}

/// Primera sincronización: "Trayendo tus movimientos" y el esqueleto.
class DashboardFirstSync extends StatelessWidget {
  const DashboardFirstSync({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.md,
      children: [
        _StateCard(
          art: SizedBox.square(
            dimension: 48,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: scheme.primary,
              backgroundColor: scheme.primaryContainer,
              semanticsLabel: l10n.syncStatusRunning,
            ),
          ),
          title: l10n.dashboardFirstSyncTitle,
          body: l10n.dashboardFirstSyncBody,
        ),
        const DashboardSkeleton(),
      ],
    );
  }
}

/// Bloques en gris mientras llega el resumen.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = Theme.of(context).colorScheme.surfaceContainerHigh;

    Widget block(double height) => Container(
      height: height,
      decoration: BoxDecoration(color: bone, borderRadius: Radii.cardAll),
    );

    return ExcludeSemantics(
      child: Opacity(
        opacity: 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [block(96), block(220)],
        ),
      ),
    );
  }
}

/// No se pudo leer el resumen de la base local.
class DashboardLoadError extends StatelessWidget {
  const DashboardLoadError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return _StateCard(
      art: ExcludeSemantics(
        child: Icon(
          Icons.error_outline_rounded,
          size: 40,
          color: scheme.onSurfaceVariant,
        ),
      ),
      title: l10n.dashboardLoadError,
      action: OutlinedButton(
        onPressed: onRetry,
        style: OutlinedButton.styleFrom(foregroundColor: scheme.onSurface),
        child: Text(l10n.transactionsRetry),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.art,
    required this.title,
    this.body,
    this.action,
  });

  final Widget art;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: Radii.cardAll,
        border: Border.all(color: brand.hairline),
      ),
      child: Column(
        spacing: 10,
        children: [
          art,
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(fontSize: 20),
            ),
          ),
          if (body case final body?)
            Text(
              body,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          if (action case final action?)
            Padding(padding: const EdgeInsets.only(top: 6), child: action),
        ],
      ),
    );
  }
}
