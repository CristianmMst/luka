import 'package:flutter/material.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/tokens/color_tokens.dart';

/// Firma del login "Trazo" (spec 008 §7.1): la flecha del logo cruza la
/// pantalla y en su camino quedan tres compras capturadas; la del medio es
/// una sola aunque llegó por notificación y por correo.
///
/// [progress] es la entrada del login (0 → 1): la línea se dibuja sola y
/// cada compra aparece cuando el trazo pasa por su punto.
class CaptureTrace extends StatelessWidget {
  const CaptureTrace({required this.progress, super.key});

  final Animation<double> progress;

  /// Lienzo de diseño (390 × 352); se escala al ancho disponible.
  static const designSize = Size(390, 352);

  static final transportAmount = Cop.pesos(3200);
  static final merchantAmount = Cop.pesos(38450);
  static final incomeAmount = Cop.pesos(3503000);

  /// `cubic-bezier(0.23, 1, 0.32, 1)`: ease-out marcado de las entradas.
  static const entranceCurve = Cubic(0.23, 1, 0.32, 1);

  /// `cubic-bezier(0.65, 0, 0.35, 1)`: el trazo, que ya está en pantalla,
  /// acelera y frena.
  static const drawCurve = Cubic(0.65, 0, 0.35, 1);

  /// Tramos de la entrada (fracción de [progress]).
  static const line = Interval(0.108, 0.703, curve: drawCurve);
  static const head = Interval(0.692, 0.822, curve: entranceCurve);
  static const pins = [
    Interval(0.14, 0.281, curve: entranceCurve),
    Interval(0.378, 0.519, curve: entranceCurve),
    Interval(0.573, 0.714, curve: entranceCurve),
  ];
  static const chips = [
    Interval(0.162, 0.335, curve: entranceCurve),
    Interval(0.4, 0.573, curve: entranceCurve),
    Interval(0.595, 0.768, curve: entranceCurve),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final background = scheme.surfaceContainerLowest;

    return Semantics(
      label: l10n.tickerSemantics(formatCop(merchantAmount)),
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: designSize.width / designSize.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = constraints.maxWidth / designSize.width;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TracePainter(
                      progress: progress,
                      pinColor: scheme.onSurface,
                      ringColor: background,
                    ),
                  ),
                ),
                Positioned(
                  left: 20 * s,
                  top: 318 * s,
                  child: _Pop(
                    animation: _curved(chips[0]),
                    child: _Chip(
                      label: l10n.loginTraceTransport,
                      amount: formatCop(
                        transportAmount,
                        sign: AmountSign.negative,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 92 * s,
                  top: 34 * s,
                  width: 200 * s,
                  child: _Pop(
                    animation: _curved(chips[1]),
                    child: _MerchantChip(
                      label: l10n.loginTraceMerchant,
                      amount: formatCop(
                        merchantAmount,
                        sign: AmountSign.negative,
                      ),
                      note: l10n.loginTraceDeduped,
                    ),
                  ),
                ),
                Positioned(
                  left: 214 * s,
                  top: 214 * s,
                  child: _Pop(
                    animation: _curved(chips[2]),
                    child: _Chip(
                      label: l10n.loginTraceIncome,
                      amount: formatCop(
                        incomeAmount,
                        sign: AmountSign.positive,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Animation<double> _curved(Curve curve) =>
      CurvedAnimation(parent: progress, curve: curve);
}

/// La flecha del logo llevada al lienzo de diseño: el trazo con su sombra
/// amarilla, la punta y los tres puntos de las compras.
class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.progress,
    required this.pinColor,
    required this.ringColor,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color pinColor;
  final Color ringColor;

  static final _line = Path()
    ..moveTo(32, 279)
    ..cubicTo(99, 279, 116, 103, 192, 103)
    ..cubicTo(242, 103, 255, 187, 292, 153)
    ..lineTo(351, 86);

  static final _head = Path()
    ..moveTo(292, 78)
    ..lineTo(360, 78)
    ..lineTo(360, 145);

  static const _pins = [Offset(44, 279), Offset(192, 103), Offset(292, 153)];

  /// Tomate puro del logo: el trazo es la marca, no texto ni botón.
  static const _tomato = Color(0xFFE23D28);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    canvas
      ..save()
      ..scale(size.width / CaptureTrace.designSize.width);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final line = _partial(_line, CaptureTrace.line.transform(t));
    canvas
      ..drawPath(
        line.shift(const Offset(0, 22)),
        stroke..color = brandYellow,
      )
      ..drawPath(line, stroke..color = _tomato)
      ..drawPath(
        _partial(_head, CaptureTrace.head.transform(t)),
        stroke..color = _tomato,
      );

    for (var i = 0; i < _pins.length; i++) {
      final pop = CaptureTrace.pins[i].transform(t);
      if (pop == 0) continue;
      final radius = 7 * (0.4 + 0.6 * pop);
      canvas
        ..drawCircle(_pins[i], radius + 3, Paint()..color = ringColor)
        ..drawCircle(_pins[i], radius, Paint()..color = pinColor);
    }
    canvas.restore();
  }

  /// El tramo inicial de [path] hasta la fracción [fraction] de su largo.
  static Path _partial(Path path, double fraction) {
    if (fraction >= 1) return path;
    final out = Path();
    if (fraction <= 0) return out;
    for (final metric in path.computeMetrics()) {
      out.addPath(metric.extractPath(0, metric.length * fraction), Offset.zero);
    }
    return out;
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.pinColor != pinColor || old.ringColor != ringColor;
}

/// Aparece subiendo 6 px y creciendo de 0.96 a 1.
class _Pop extends AnimatedWidget {
  const _Pop({required Animation<double> animation, required this.child})
    : super(listenable: animation);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Opacity(
      opacity: t.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, 6 * (1 - t)),
        child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurface);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x145C1A10),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$label '),
              TextSpan(
                text: amount,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          style: style,
        ),
      ),
    );
  }
}

/// La compra deduplicada: chip oscuro con la nota "1 registro".
class _MerchantChip extends StatelessWidget {
  const _MerchantChip({
    required this.label,
    required this.amount,
    required this.note,
  });

  final String label;
  final String amount;
  final String note;

  static const _ink = Color(0xFF2A1210);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: brandCream);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(12),
        border: scheme.brightness == Brightness.dark
            ? Border.all(color: scheme.outlineVariant)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          spacing: 1,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$label '),
                  TextSpan(
                    text: amount,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              style: style,
              textAlign: TextAlign.center,
            ),
            Text(
              note,
              style: style?.copyWith(
                color: brandYellow,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
