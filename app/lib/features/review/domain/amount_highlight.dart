import 'package:finanzia/core/format/money.dart';

/// Posición de un monto dentro del texto: `[start, end)` en unidades de
/// código, como `String.substring`.
typedef AmountRange = ({int start, int end});

// Número con miles agrupados (`3.000`, `3,000.00`, `3.000,00`) o sin
// agrupar (`200000`, `1234.56`). No empieza pegado a otra cifra.
const _number =
    r'(?<![\d.,])'
    r'(?:\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)'
    r'(?![.,]?\d)';

// Miles agrupados sin signo, igual que `looks_monetary` del backend: dos
// grupos o más (`1.234.567`), o uno con centavos (`45.900,00`).
const _bare =
    r'(?<![\d.,])'
    r'(?:\d{1,3}(?:[.,]\d{3}){2,}(?:[.,]\d{1,2})?|\d{1,3}(?:[.,]\d{3})+[.,]\d{2})'
    r'(?![.,]?\d)';

// `$` o `COP` antes del número, o `COP` después.
const _prefix = r'(?:\$|\bCOP)\s?';
const _suffix = r'\s?COP\b';

final _amount = RegExp('$_prefix$_number|$_number$_suffix|$_bare');

// Mismo patrón de teléfonos que `excerpt.py` (spec 006 §4.1): 3-3-4
// (local o celular) y 3-3-3-3 (línea gratuita).
final _phone = RegExp(
  r'\d{3}[\s.\-]?\d{3}[\s.\-]?\d{4}|\d{3}[\s.\-]\d{3}[\s.\-]\d{3}[\s.\-]\d{3}',
);

/// Rangos de [text] que parecen montos, en orden: los que llevan `$` o
/// `COP` y los miles agrupados sin signo. Es la misma idea que
/// `looks_monetary` del backend (`parsing/domain/excerpt.py`): un trozo que
/// toca un teléfono no se resalta, y solo se resalta lo que
/// [parseAmount] sabe convertir en [Cop].
List<AmountRange> highlightAmounts(String text) {
  final phones = [for (final m in _phone.allMatches(text)) (m.start, m.end)];
  return [
    for (final m in _amount.allMatches(text))
      if (!phones.any((p) => m.start < p.$2 && p.$1 < m.end) &&
          parseAmount(m[0]!) != null)
        (start: m.start, end: m.end),
  ];
}

final _grouped = RegExp(r'^\d{1,3}(?:[.,]\d{3})*$');
final _plain = RegExp(r'^\d+$');
final _decimals = RegExp(r'[.,](\d{1,2})$');

/// Convierte un monto resaltado (`$3,000.00`, `$3.000,00`, `COP 45.900`,
/// `12.000 COP`) en [Cop]; `null` si no es un monto.
///
/// Un separador final seguido de una o dos cifras es el decimal, sea punto
/// o coma; los demás separan miles en grupos de tres.
Cop? parseAmount(String raw) {
  final digits = raw.replaceAll(RegExp(r'\$|COP|\s'), '');
  final decimals = _decimals.firstMatch(digits);
  final whole = decimals == null ? digits : digits.substring(0, decimals.start);
  if (!_plain.hasMatch(whole) && !_grouped.hasMatch(whole)) return null;
  final pesos = whole.replaceAll(RegExp('[.,]'), '');
  final fraction = decimals == null ? '' : '.${decimals[1]}';
  try {
    return Cop.parse('$pesos$fraction');
  } on FormatException {
    return null;
  }
}
