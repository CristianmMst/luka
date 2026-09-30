import 'dart:async';

import 'package:flutter/material.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/core/theme/tokens/type_tokens.dart';

/// Firma del login: una notificación y un correo de la misma compra caen y se
/// funden en un solo registro. Con "reducir movimiento" se muestra quieto.
class CaptureTicker extends StatefulWidget {
  const CaptureTicker({super.key});

  static final exampleAmount = Cop.pesos(42900);

  @override
  State<CaptureTicker> createState() => _CaptureTickerState();
}

class _CaptureTickerState extends State<CaptureTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end, [Curve? curve]) =>
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: curve ?? Curves.easeOutCubic),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final amount = formatCop(CaptureTicker.exampleAmount);

    return Semantics(
      label: l10n.tickerSemantics(amount),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.sm - 2,
        children: [
          _Drop(
            animation: _interval(0.05, 0.35),
            child: _SourceCard(
              icon: Icons.notifications_none_rounded,
              source: l10n.tickerNotificationSource,
              text: l10n.tickerNotificationText,
              amount: amount,
            ),
          ),
          _Drop(
            animation: _interval(0.22, 0.52),
            child: _SourceCard(
              icon: Icons.mail_outline_rounded,
              source: l10n.tickerEmailSource,
              text: l10n.tickerEmailText,
              amount: amount,
            ),
          ),
          SizeTransition(
            sizeFactor: _interval(0.55, 0.7),
            axisAlignment: -1,
            child: Center(
              child: Container(
                width: 2,
                height: 22,
                decoration: BoxDecoration(
                  color: brand.gold,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _interval(0.7, 0.85),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.92,
                end: 1,
              ).animate(_interval(0.7, 1, Curves.easeOutBack)),
              child: _ResultCard(
                amount: formatCop(
                  CaptureTicker.exampleAmount,
                  sign: AmountSign.negative,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Drop extends StatelessWidget {
  const _Drop({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.35),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.source,
    required this.text,
    required this.amount,
  });

  final IconData icon;
  final String source;
  final String text;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: brand.heroCard,
        borderRadius: Radii.noticeAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md - 2,
          vertical: Space.sm,
        ),
        child: Row(
          spacing: Space.sm,
          children: [
            _IconBubble(icon: icon, color: brand.heroChip),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    source,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: amountTextStyle.copyWith(
                fontSize: 14,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.brightness == Brightness.light
            ? scheme.surfaceContainerLowest
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.gold, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.md - 2),
        child: Row(
          spacing: Space.sm,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: brand.gold,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: brand.onGold, size: 22),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    l10n.tickerResultTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontFamily: FontFamilies.display,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    l10n.tickerResultSubtitle,
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: amountTextStyle.copyWith(
                fontSize: 16,
                color: brand.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
