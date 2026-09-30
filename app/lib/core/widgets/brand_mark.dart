import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:luka/core/theme/tokens/type_tokens.dart';

/// Gema de talla esmeralda + wordmark "luka".
class BrandMark extends StatelessWidget {
  const BrandMark({
    required this.gemColor,
    required this.textColor,
    this.size = 26,
    this.showWordmark = true,
    this.direction = Axis.horizontal,
    super.key,
  });

  /// Relleno de la gema (el borde y las facetas son siempre oro).
  final Color gemColor;
  final Color textColor;

  /// Tamaño del wordmark; la gema escala con él.
  final double size;
  final bool showWordmark;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    final gem = SvgPicture.asset(
      'assets/brand/gem.svg',
      height: size * 1.25,
      theme: SvgTheme(currentColor: gemColor),
      excludeFromSemantics: true,
    );
    if (!showWordmark) return gem;

    final wordmark = Text(
      'luka',
      style: TextStyle(
        fontFamily: FontFamilies.display,
        fontWeight: FontWeight.w700,
        fontSize: size,
        letterSpacing: -size * 0.02,
        color: textColor,
        height: 1,
      ),
    );
    return Semantics(
      label: 'luka',
      excludeSemantics: true,
      child: Flex(
        direction: direction,
        mainAxisSize: MainAxisSize.min,
        spacing: size * (direction == Axis.horizontal ? 0.4 : 0.5),
        children: [gem, wordmark],
      ),
    );
  }
}
