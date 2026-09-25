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

    test('no resalta lineas gratuitas ni fijos, ni siquiera en parte', () {
      for (final phone in ['018000912345', '604 510 9095', '018 000 931 987']) {
        expect(highlightAmounts('Llama al $phone hoy'), isEmpty, reason: phone);
        expect(highlightAmounts(phone), isEmpty, reason: phone);
      }
    });

    test('resalta los montos pegados a esos telefonos', () {
      expect(
        highlighted(
          r'Pago $42.900 linea 018000912345 saldo $1.200,50 fijo '
          r'604 510 9095 y 12.000 COP o 018 000 931 987 y $3.500',
        ),
        [r'$42.900', r'$1.200,50', '12.000 COP', r'$3.500'],
      );
    });

    test('no resalta telefonos con prefijo de pais', () {
      for (final phone in ['+573001234567', '57 300 123 4567']) {
        expect(highlightAmounts('Llama al $phone hoy'), isEmpty, reason: phone);
        expect(highlightAmounts(phone), isEmpty, reason: phone);
      }
    });

    test('resalta el monto que sigue a un telefono sin perderlo', () {
      expect(highlighted('Dudas al 018 000 931 987 COP 3.500'), ['COP 3.500']);
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

    test(r'resalta $45.5 como 455 pesos y no una cola ambigua sin signo', () {
      const text = r'Pago $45.5 y saldo 1.234.567.5 hoy';
      expect(highlighted(text), [r'$45.5']);
      final range = highlightAmounts(text).single;
      expect(
        parseAmount(text.substring(range.start, range.end)),
        Cop.pesos(455),
      );
    });

    test('un texto de 8 KB se resalta rápido y completo', () {
      const line =
          r'Compra por $126.400 en EXITO. Llama al 604 510 9095. '
          'Saldo 1.254.300,50 y ref 1234567.\n';
      final text = line * (8192 ~/ line.length + 1);
      expect(text.length, greaterThanOrEqualTo(8192));
      final watch = Stopwatch()..start();
      final found = highlighted(text);
      watch.stop();

      final lines = text.split('\n').where((l) => l.isNotEmpty).length;
      expect(found, [
        for (var i = 0; i < lines; i++) ...[r'$126.400', '1.254.300,50'],
      ]);
      expect(watch.elapsed, lessThan(const Duration(milliseconds: 500)));
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
      // Casos cruzados con `parse_amount` del backend (normalizers.py): un
      // solo tipo de separador es decimal solo una vez y con dos cifras.
      r'$45.5': const Cop(45500),
      '1.234.56': const Cop(12345600),
      '45.900': Cop.pesos(45900),
      '1,5': Cop.pesos(15),
      r'$1.2.3': Cop.pesos(123),
      '0,005': Cop.pesos(5),
      r'$1.234.567.5': Cop.pesos(12345675),
      // Con los dos, el de la derecha es el decimal; redondeo desde la mitad.
      '1.234,567': const Cop(123457),
      '1,234.565': const Cop(123457),
      '1,234.564': const Cop(123456),
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
      r'$0',
      '0,00',
      '1.2,3.4',
      // Más de 12 cifras de pesos no cabe en el wire de `Cop`.
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
