import 'package:flutter/material.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/transactions/application/transaction_detail_controller.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';
import 'package:luka/features/transactions/domain/transactions_repository.dart';
import 'package:luka/features/transactions/presentation/widgets/transaction_format.dart';

/// "Fuentes" del detalle (diseño "DetalleA"): una tarjeta por fuente con
/// su canal y la hora de recepción y, con dos o más, el sello amarillo
/// "1 registro con N fuentes, sin duplicados". Sin red muestra el panel
/// "Las fuentes se consultan con conexión…" (diseño "Estados").
class SourcesSection extends StatelessWidget {
  const SourcesSection({required this.sources, super.key});

  final SourcesState sources;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final loaded = switch (sources) {
      SourcesLoaded(:final sources) => [
        ...sources,
      ]..sort((a, b) => a.receivedAt.compareTo(b.receivedAt)),
      _ => null,
    };
    final channels = loaded?.map((s) => s.channel).toSet().length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.xxs,
            22,
            Space.xxs,
            Space.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.detailSources, style: textTheme.titleMedium),
                ),
              ),
              if (channels > 0)
                Text(
                  l10n.detailSourcesCount(channels),
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        switch (sources) {
          SourcesLoading() => const Padding(
            padding: EdgeInsets.all(Space.md),
            child: Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
          SourcesOffline() => _DashedNotice(
            icon: Icons.wifi_off_rounded,
            text: l10n.sourcesOffline,
          ),
          SourcesLoaded() when loaded!.isEmpty => _DashedNotice(
            icon: Icons.info_outline_rounded,
            text: l10n.sourcesEmpty,
          ),
          SourcesLoaded() => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Space.xs,
            children: [
              for (final source in loaded!) _SourceCard(source),
              if (loaded.length >= 2) _SingleRecordSeal(count: loaded.length),
            ],
          ),
        },
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard(this.source);

  final TxSource source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (title, gender) = switch (source.channel) {
      TxChannel.notification => (l10n.sourceNotification, 'female'),
      TxChannel.smsNotification => (l10n.sourceSms, 'male'),
      TxChannel.email => (l10n.sourceEmail, 'male'),
      TxChannel.manual => (l10n.sourceManual, 'other'),
    };

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.lukaColors.card,
          borderRadius: Radii.noticeAll,
          border: Border.all(color: context.lukaColors.hairline),
        ),
        child: Row(
          spacing: Space.sm,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.lukaColors.neutralChip,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  channelIcon(source.channel),
                  size: 18,
                  color: scheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  Text(
                    l10n.sourceReceived(
                      gender,
                      shortDateTime(source.receivedAt),
                    ),
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El amarillo de marca se reserva para este sello (spec 008 §7.1).
class _SingleRecordSeal extends StatelessWidget {
  const _SingleRecordSeal({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: brand.goldContainer,
          borderRadius: Radii.noticeAll,
          border: Border.all(color: theme.colorScheme.tertiary, width: 1.5),
        ),
        child: Row(
          spacing: 10,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: brand.gold,
                ),
                child: Icon(Icons.check_rounded, size: 16, color: brand.onGold),
              ),
            ),
            Expanded(
              child: Text(
                l10n.sourcesSeal(count),
                style: textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedNotice extends StatelessWidget {
  const _DashedNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = scheme.onSurfaceVariant;

    return Semantics(
      container: true,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: scheme.outline),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            spacing: Space.sm,
            children: [
              ExcludeSemantics(child: Icon(icon, size: 22, color: muted)),
              Expanded(
                child: Text(
                  text,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  static const _dash = 4.0;
  static const _gap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = Path()
      ..addRRect(
        Radii.noticeAll.toRRect(Offset.zero & size).deflate(0.5),
      );
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
