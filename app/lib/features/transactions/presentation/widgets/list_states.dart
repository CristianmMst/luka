import 'package:flutter/material.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/widgets/brand_mark.dart';

/// Estados de la lista sin filas (diseño "Estados").

/// "Aún no hay movimientos" con el CTA "Registrar un gasto".
class EmptyTransactions extends StatelessWidget {
  const EmptyTransactions({required this.onRegister, super.key});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final gem = context.lukaColors.gem;

    return _CenteredState(
      // La gema de marca, como en el login y el splash.
      art: BrandMark(
        gemColor: gem,
        textColor: gem,
        size: 51,
        showWordmark: false,
      ),
      title: l10n.emptyTitle,
      body: l10n.emptyBody,
      action: FilledButton(onPressed: onRegister, child: Text(l10n.emptyCta)),
    );
  }
}

/// "Nada coincide con …" con "Quitar filtros".
class NoResults extends StatelessWidget {
  const NoResults({
    required this.text,
    required this.summary,
    required this.onClear,
    super.key,
  });

  /// Texto buscado (vacío si solo hay filtros).
  final String text;

  /// Resumen del filtro ("Este mes · Solo gastos").
  final String summary;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return _CenteredState(
      art: ExcludeSemantics(
        child: Icon(
          Icons.search_rounded,
          size: 40,
          color: scheme.onSurfaceVariant,
        ),
      ),
      title: text.trim().isEmpty
          ? l10n.noResultsTitle
          : l10n.noResultsTitleText(text.trim()),
      titleSize: 20,
      body: l10n.noResultsBody(summary),
      action: OutlinedButton(
        onPressed: onClear,
        style: OutlinedButton.styleFrom(foregroundColor: scheme.onSurface),
        child: Text(l10n.noResultsClear),
      ),
    );
  }
}

/// El mes en curso está vacío pero hay movimientos anteriores (sin
/// filtros activos): "Ver mes pasado" o "Cambiar filtros".
class EmptyPeriod extends StatelessWidget {
  const EmptyPeriod({
    required this.onLastMonth,
    required this.onFilters,
    super.key,
  });

  final VoidCallback onLastMonth;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return _CenteredState(
      art: ExcludeSemantics(
        child: Icon(
          Icons.event_busy_outlined,
          size: 40,
          color: scheme.onSurfaceVariant,
        ),
      ),
      title: l10n.emptyPeriodTitle,
      titleSize: 20,
      body: l10n.emptyPeriodBody,
      action: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Space.xs,
        children: [
          FilledButton(
            onPressed: onLastMonth,
            child: Text(l10n.emptyPeriodLastMonth),
          ),
          TextButton(
            onPressed: onFilters,
            child: Text(l10n.emptyPeriodFilters),
          ),
        ],
      ),
    );
  }
}

/// Esqueleto de carga; con [firstSync] muestra la barra y "Trayendo tus
/// movimientos…" (primera sincronización).
class TransactionsSkeleton extends StatelessWidget {
  const TransactionsSkeleton({this.firstSync = false, super.key});

  final bool firstSync;

  static const _widths = [0.62, 0.48, 0.70, 0.54, 0.40];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bone = scheme.surfaceContainerHigh;

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bone,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.sm,
        children: [
          if (firstSync) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: scheme.outlineVariant,
                color: scheme.primary,
              ),
            ),
            Text(
              l10n.firstSyncLoading,
              style: textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  for (final width in _widths)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.xs),
                      child: Row(
                        spacing: Space.sm,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: Space.xs,
                              children: [
                                bar(constraints.maxWidth * width, 14),
                                bar(72, 12),
                              ],
                            ),
                          ),
                          bar(80, 14),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// No pudimos leer la base local.
class TransactionsLoadError extends StatelessWidget {
  const TransactionsLoadError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _CenteredState(
      title: l10n.transactionsLoadError,
      titleSize: 20,
      action: OutlinedButton(
        onPressed: onRetry,
        child: Text(l10n.transactionsRetry),
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.title,
    required this.action,
    this.art,
    this.body,
    this.titleSize = 22,
  });

  final Widget? art;
  final String title;
  final double titleSize;
  final String? body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Space.sm,
          children: [
            ?art,
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(fontSize: titleSize),
              ),
            ),
            if (body case final body?)
              Text(
                body,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            Padding(padding: const EdgeInsets.only(top: 6), child: action),
          ],
        ),
      ),
    );
  }
}
