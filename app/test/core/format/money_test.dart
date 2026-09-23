import 'package:finanzia/core/format/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cop.parse', () {
    test('acepta el formato del backend', () {
      expect(Cop.parse('42900'), const Cop(4290000));
      expect(Cop.parse('42900.5'), const Cop(4290050));
      expect(Cop.parse('1234567.05'), const Cop(123456705));
      expect(Cop.parse('999999999999.99').cents, 99999999999999);
    });

    test('rechaza lo que no cumple el contrato', () {
      for (final raw in ['', '-1', '1,5', '1.234', '1234567890123', 'abc']) {
        expect(() => Cop.parse(raw), throwsFormatException, reason: raw);
      }
    });
  });

  group('formatCop', () {
    test('listas: sin decimales, punto de miles', () {
      expect(formatCop(Cop.pesos(1234567)), r'$1.234.567');
      expect(formatCop(Cop.pesos(0)), r'$0');
      expect(formatCop(Cop.parse('42900.99')), r'$42.900');
    });

    test('detalle: coma decimal', () {
      expect(
        formatCop(Cop.parse('1234567.5'), withDecimals: true),
        r'$1.234.567,50',
      );
    });

    test('signo de gasto (U+2212) e ingreso', () {
      expect(
        formatCop(Cop.pesos(42900), sign: AmountSign.negative),
        '−'
        r'$42.900',
      );
      expect(
        formatCop(Cop.pesos(3500000), sign: AmountSign.positive),
        r'+$3.500.000',
      );
    });
  });

  group('Cop.toWire', () {
    test('dos decimales, ida y vuelta con parse', () {
      expect(const Cop(4290000).toWire(), '42900.00');
      expect(const Cop(4290005).toWire(), '42900.05');
      expect(const Cop(0).toWire(), '0.00');
      expect(Cop.parse(const Cop(123456705).toWire()), const Cop(123456705));
    });
  });
}
