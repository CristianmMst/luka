import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

/// Logo de luka: círculo con la flecha que sube + wordmark "luka".
///
/// Las proporciones son las del logo horizontal oficial: el símbolo mide
/// 100 unidades, el wordmark 56 y los separa un hueco de 10.
class BrandMark extends StatelessWidget {
  const BrandMark({
    required this.textColor,
    this.onDark = false,
    this.size = 26,
    this.showWordmark = true,
    this.direction = Axis.horizontal,
    super.key,
  });

  /// Color del wordmark.
  final Color textColor;

  /// Sobre fondos oscuros (el hero en oscuro) el símbolo va en su variante
  /// amarilla con la flecha tomate.
  final bool onDark;

  /// Tamaño de referencia del wordmark (como un tamaño de fuente); el
  /// símbolo escala con él.
  final double size;
  final bool showWordmark;
  final Axis direction;

  /// El palo de la "l" (51 unidades) mide lo mismo que las ascendentes de
  /// una fuente de tamaño [size] (0.75 × size).
  static const double _unit = 0.75 / 51;

  @override
  Widget build(BuildContext context) {
    final unit = size * _unit;
    final mark = SvgPicture(
      AssetBytesLoader(
        onDark
            ? 'assets/brand/logo_mark_on_dark.svg'
            : 'assets/brand/logo_mark.svg',
      ),
      height: 100 * unit,
      excludeFromSemantics: true,
    );
    if (!showWordmark) return mark;

    // Compilado, el `currentColor` del wordmark queda fijo: se tiñe con un
    // filtro (es de un solo color).
    final wordmark = SvgPicture(
      const AssetBytesLoader('assets/brand/wordmark.svg'),
      height: 56 * unit,
      colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
    return Semantics(
      label: 'luka',
      excludeSemantics: true,
      child: Flex(
        direction: direction,
        mainAxisSize: MainAxisSize.min,
        spacing: direction == Axis.horizontal ? 10 * unit : size * 0.5,
        children: [mark, wordmark],
      ),
    );
  }
}

/// La marca sobre la cabecera `hero` (splash, onboarding): blanca en claro,
/// así que va la variante del login (símbolo tomate y wordmark `#AA2E1E`);
/// en oscuro, la variante para fondo oscuro con el wordmark crema.
class HeroBrandMark extends StatelessWidget {
  const HeroBrandMark({
    this.size = 26,
    this.direction = Axis.horizontal,
    super.key,
  });

  final double size;
  final Axis direction;

  static const _wordmarkRed = Color(0xFFAA2E1E);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BrandMark(
      onDark: dark,
      textColor: dark ? const Color(0xFFFFF6F0) : _wordmarkRed,
      size: size,
      direction: direction,
    );
  }
}
