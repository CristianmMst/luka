import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/features/review/domain/amount_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los trozos de [text] que [highlightAmounts] resalta.
List<String> highlighted(String text) => [
  for (final r in highlightAmounts(text)) text.substring(r.start, r.end),
];

void main() {
  group('highlightAmounts', () {
    test('resalta montos con signo de pesos', () {
      expect(
        highlighted(r'Compra por $42.900 en EXITO y $ 1.500'),
        [r'$42.900', r'$ 1.500'],
      );
    });

    test('resalta el formato con coma de miles y punto decimal', () {
      expect(highlighted(r'Pagaste $3,000.00 en Rappi'), [r'$3,000.00']);
    });

    test('resalta el formato con punto de miles y coma decimal', () {
      expect(highlighted(r'Pagaste $3.000,00 en Rappi'), [r'$3.000,00']);
    });

    test('resalta montos sin separadores con signo', () {
      expect(highlighted(r'Retiro $200000 cajero'), [r'$200000']);
    });

    test('resalta COP antes o despues del numero', () {
      expect(
        highlighted('Transferencia COP 45.900 y 12.000 COP recibidos'),
        ['COP 45.900', '12.000 COP'],
      );
    });

    test('resalta miles agrupados sin signo', () {
      expect(
        highlighted('Valor 1.234.567 y otro 45.900,00 hoy'),
        ['1.234.567', '45.900,00'],
      );
    });

    test('no resalta un solo grupo de miles sin signo ni decimales', () {
      expect(highlighted('Quedan 45.900 puntos'), isEmpty);
    });

    test('no resalta telefonos', () {
      expect(
        highlighted(
          'Llama al 604.510.9095, al 300 123 4567, al 3001234567 '
          'o a la linea 018 000 931 987',
        ),
        isEmpty,
      );
    });

    test('no resalta un telefono con signo de pesos', () {
      expect(highlighted(r'Codigo $3001234567'), isEmpty);
    });

    test('resalta el monto y no el telefono del mismo mensaje', () {
      expect(
        highlighted(r'Compra $42.900. Si no fuiste llama al 604.510.9095'),
        [r'$42.900'],
      );
    });

    test('no resalta fechas, horas, referencias ni tarjetas', () {
      expect(
        highlighted('El 23/09/2026 a las 10:30, ref 1234567, tarjeta *1234'),
        isEmpty,
      );
    });

    test('no resalta montos de mas de 12 cifras', () {
      expect(highlighted(r'$1.234.567.890.123'), isEmpty);
    });

    test('da rangos en orden y sin texto', () {
      expect(highlightAmounts(''), isEmpty);
      expect(highlightAmounts(r'a $1 b $2'), [
        (start: 2, end: 4),
        (start: 7, end: 9),
      ]);
    });
  });

  group('parseAmount', () {
    final cases = <String, Cop>{
      r'$42.900': Cop.pesos(42900),
      r'$ 1.500': Cop.pesos(1500),
      r'$3,000.00': Cop.pesos(3000),
      r'$3.000,00': Cop.pesos(3000),
      r'$3.000,5': const Cop(300050),
      r'$1,234,567.89': const Cop(123456789),
      r'$200000': Cop.pesos(200000),
      'COP 45.900': Cop.pesos(45900),
      '12.000 COP': Cop.pesos(12000),
      '1.234.567': Cop.pesos(1234567),
      '45.900,00': Cop.pesos(45900),
      r'$1234.56': const Cop(123456),
    };
    for (final MapEntry(key: raw, value: cents) in cases.entries) {
      test('"$raw" -> ${cents.cents} centavos', () {
        expect(parseAmount(raw), cents);
      });
    }

    for (final raw in [
      '',
      'COP',
      r'$',
      'abc',
      r'$1.2.3',
      '1.234.567.890.123',
    ]) {
      test('"$raw" no es un monto', () => expect(parseAmount(raw), isNull));
    }

    test('cada rango resaltado se puede parsear', () {
      const text = r'Compra $3,000.00, abono 1.234.567 y 12.000 COP';
      expect(
        [
          for (final r in highlightAmounts(text))
            parseAmount(text.substring(r.start, r.end)),
        ],
        [Cop.pesos(3000), Cop.pesos(1234567), Cop.pesos(12000)],
      );
    });
  });
}
