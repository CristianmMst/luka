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
// grupos o más sin decimales (`1.234.567`), o grupos con centavos de dos
// cifras (`45.900,00`). Una cola ambigua (`1.234.567.5`) no se resalta.
const _bare =
    r'(?<![\d.,])'
    r'(?:\d{1,3}(?:[.,]\d{3}){2,}|\d{1,3}(?:[.,]\d{3})+[.,]\d{2})'
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

final _valid = RegExp(r'^\d+(?:[.,]\d+)*$');
final _digits = RegExp(r'^\d+$');
final _currency = RegExp('cop', caseSensitive: false);

/// Pesos más grandes que caben en el wire de [Cop] (12 cifras).
const _maxPesos = 999999999999;

/// Convierte un monto (`$3,000.00`, `$3.000,00`, `COP 45.900`, `12.000 COP`)
/// en [Cop]; `null` si no es un monto o no es mayor que cero.
///
/// Es la misma regla que `parse_amount` del backend
/// (`parsing/domain/normalizers.py`): si hay `.` y `,`, el de más a la
/// derecha es el decimal; si hay un solo tipo de separador, es decimal solo
/// si aparece una vez seguido de exactamente dos cifras, y si no separa
/// miles (`$45.5` son 455 pesos). Los centavos se redondean a dos cifras
/// hacia arriba desde la mitad.
Cop? parseAmount(String raw) {
  final cleaned = raw
      .replaceAll(_currency, '')
      .replaceAll(r'$', '')
      .replaceAll(RegExp(r'\s+'), '');
  if (cleaned.isEmpty || !_valid.hasMatch(cleaned)) return null;
  final hasDot = cleaned.contains('.');
  final hasComma = cleaned.contains(',');
  String whole;
  var fraction = '';
  if (hasDot && hasComma) {
    final decimal = cleaned.lastIndexOf('.') > cleaned.lastIndexOf(',')
        ? '.'
        : ',';
    final thousands = decimal == '.' ? ',' : '.';
    final at = cleaned.lastIndexOf(decimal);
    whole = cleaned.substring(0, at).replaceAll(thousands, '');
    fraction = cleaned.substring(at + 1);
  } else if (hasDot || hasComma) {
    final parts = cleaned.split(hasDot ? '.' : ',');
    if (parts.length == 2 && parts[1].length == 2) {
      whole = parts[0];
      fraction = parts[1];
    } else {
      whole = parts.join();
    }
  } else {
    whole = cleaned;
  }
  // `1.2,3.4`: al quitar los miles queda otro punto; el backend lo rechaza.
  if (!_digits.hasMatch(whole)) return null;
  final pesosDigits = whole.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (pesosDigits.length > 12) return null;
  final roundUp = fraction.length > 2 && fraction.codeUnitAt(2) >= 0x35;
  final cents =
      int.parse(pesosDigits) * 100 +
      int.parse(fraction.padRight(2, '0').substring(0, 2)) +
      (roundUp ? 1 : 0);
  if (cents <= 0 || cents ~/ 100 > _maxPesos) return null;
  return Cop(cents);
}
