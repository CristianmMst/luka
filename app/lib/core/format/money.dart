import 'package:intl/intl.dart';

/// Monto en centavos de peso colombiano. Se evita `double` para no perder
/// precisión en sumas (los montos llegan como string decimal, spec 005 §1).
extension type const Cop(int cents) {
  /// Parsea el formato del backend: `^\d{1,12}(\.\d{1,2})?$`.
  factory Cop.parse(String raw) {
    final match = _wire.firstMatch(raw.trim());
    if (match == null) {
      throw FormatException('Monto con formato inválido', raw);
    }
    final pesos = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    return Cop(pesos * 100 + int.parse(fraction));
  }

  factory Cop.pesos(int pesos) => Cop(pesos * 100);

  static final _wire = RegExp(r'^(\d{1,12})(?:\.(\d{1,2}))?$');
}

enum AmountSign {
  /// Sin signo: transferencias entre cuentas propias.
  none,

  /// `−$42.900` (U+2212), gasto.
  negative,

  /// `+$3.500.000`, ingreso.
  positive,
}

/// Formato es-CO: `$1.234.567` en listas, `$1.234.567,50` en detalle
/// (spec 008 §7).
String formatCop(
  Cop amount, {
  bool withDecimals = false,
  AmountSign sign = AmountSign.none,
}) {
  // El patrón de moneda de es_CO pone el símbolo al final ("1.234$"); se
  // formatea el número con sus separadores y el símbolo va adelante.
  final format = NumberFormat.decimalPatternDigits(
    locale: 'es_CO',
    decimalDigits: withDecimals ? 2 : 0,
  );
  final cents = amount.cents.abs();
  final text = '\$${format.format(withDecimals ? cents / 100 : cents ~/ 100)}';
  return switch (sign) {
    AmountSign.none => text,
    AmountSign.negative => '−$text',
    AmountSign.positive => '+$text',
  };
}
