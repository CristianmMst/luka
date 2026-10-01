import 'package:flutter/material.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/time/colombia_month.dart';
import 'package:luka/core/widgets/brand_mark.dart';
import 'package:luka/features/dashboard/domain/monthly_summary.dart';
import 'package:luka/features/dashboard/presentation/widgets/dashboard_format.dart';
import 'package:luka/features/dashboard/presentation/widgets/month_switcher.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// Banda tomate del Inicio (diseño Q, spec 008 §3.2): saludo, línea de
/// sync, selector de mes y, si hay [summary], el balance. Al final, [alert]
/// (la franja de captura detenida), que pone su propio espacio arriba.
///
/// [overlap] es el alto extra de la banda bajo el que se monta la tarjeta
/// de gastos e ingresos (`DashboardTotalsCard`).
class DashboardHero extends StatelessWidget {
  const DashboardHero({
    required this.greeting,
    required this.syncLine,
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    this.summary,
    this.alert,
    this.overlap = 0,
    super.key,
  });

  final String greeting;
  final String syncLine;
  final ColombiaMonth month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final MonthlySummary? summary;
  final Widget? alert;
  final double overlap;

  static const _radius = 28.0;

  @override
  Widget build(BuildContext context) {
    final brand = context.lukaColors;
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(
        Space.md,
        top + Space.sm,
        Space.md,
        22 + overlap,
      ),
      decoration: BoxDecoration(
        color: brand.band,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_radius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _content(context),
          ?alert,
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        Row(
          spacing: Space.sm,
          children: [
            BrandMark(
              onDark: true,
              textColor: brand.onBand,
              showWordmark: false,
              size: 18,
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: brand.onBand,
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: _SyncChip(text: syncLine),
            ),
          ],
        ),
        _MonthSelector(
          month: month,
          canGoNext: canGoNext,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
        if (summary case final summary?)
          MonthSwitcher(
            month: month,
            child: _Balance(summary: summary),
          ),
      ],
    );
  }
}

/// La línea de sync en una píldora translúcida, con el punto amarillo.
class _SyncChip extends StatelessWidget {
  const _SyncChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final brand = context.lukaColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      // Oscurece la banda (no la aclara): el texto de 12 px pasa AA.
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: Radii.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: brand.gold,
              shape: BoxShape.circle,
            ),
          ),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: brand.onBand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final ColombiaMonth month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final style = IconButton.styleFrom(
      fixedSize: const Size.square(minTouchTarget),
      minimumSize: const Size.square(minTouchTarget),
      backgroundColor: brand.onBand.withValues(alpha: 0.16),
      foregroundColor: brand.onBand,
      disabledBackgroundColor: Colors.transparent,
      disabledForegroundColor: brand.onBand.withValues(alpha: 0.4),
    );

    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: l10n.dashboardPreviousMonth,
          style: style,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              monthHeading(month),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 20,
                color: brand.onBand,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: canGoNext ? onNext : null,
          tooltip: l10n.dashboardNextMonth,
          style: style,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({required this.summary});

  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final balance = summary.balance;
    final (sign, spoken) = switch (balance.cents) {
      > 0 => (AmountSign.positive, 'positive'),
      < 0 => (AmountSign.negative, 'negative'),
      _ => (AmountSign.none, 'none'),
    };

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l10n.dashboardBalanceSemantics(spoken, spokenNumber(balance)),
      child: Column(
        spacing: 2,
        children: [
          Text(
            l10n.dashboardBalance,
            style: textTheme.labelMedium?.copyWith(
              fontSize: 14,
              color: brand.onBand,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatCop(balance, sign: sign),
              maxLines: 1,
              style: textTheme.displayLarge?.copyWith(
                color: brand.onBand,
                letterSpacing: -2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
