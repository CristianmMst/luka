import 'package:finanzia/core/time/colombia_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColombiaMonth.containing', () {
    test('el 31 a las 23:30 en Bogota (04:30Z del dia 1) es del mes que '
        'termina', () {
      final instant = DateTime.utc(2026, 9, 1, 4, 30);
      expect(ColombiaMonth.containing(instant), ColombiaMonth(2026, 8));
    });

    test('las 00:00 del dia 1 en Bogota (05:00Z) ya es el mes nuevo', () {
      final instant = DateTime.utc(2026, 9, 1, 5);
      expect(ColombiaMonth.containing(instant), ColombiaMonth(2026, 9));
    });

    test('el 31 de diciembre a las 23:30 local sigue en diciembre', () {
      final instant = DateTime.utc(2027, 1, 1, 4, 30);
      expect(ColombiaMonth.containing(instant), ColombiaMonth(2026, 12));
    });

    test('un DateTime local se convierte a UTC antes de calcular', () {
      final instant = DateTime.utc(2026, 9, 15, 12);
      expect(
        ColombiaMonth.containing(instant.toLocal()),
        ColombiaMonth(2026, 9),
      );
    });
  });

  group('range', () {
    test('va de la medianoche local del dia 1 al dia 1 siguiente', () {
      final r = ColombiaMonth(2026, 9).range();
      expect(r.from, DateTime.utc(2026, 9, 1, 5));
      expect(r.to, DateTime.utc(2026, 10, 1, 5));
    });

    test('diciembre termina en enero del ano siguiente', () {
      final r = ColombiaMonth(2026, 12).range();
      expect(r.from, DateTime.utc(2026, 12, 1, 5));
      expect(r.to, DateTime.utc(2027, 1, 1, 5));
    });

    test('el 31 a las 23:30 local cae dentro de [from, to)', () {
      final r = ColombiaMonth(2026, 8).range();
      final late = DateTime.utc(2026, 9, 1, 4, 30);
      expect(late.isBefore(r.to), isTrue);
      expect(late.isBefore(r.from), isFalse);
    });
  });

  group('navegacion', () {
    test('next de diciembre es enero del ano siguiente', () {
      expect(ColombiaMonth(2026, 12).next, ColombiaMonth(2027, 1));
    });

    test('previous de enero es diciembre del ano anterior', () {
      expect(ColombiaMonth(2026, 1).previous, ColombiaMonth(2025, 12));
    });

    test('el constructor normaliza meses fuera de 1-12', () {
      final month = ColombiaMonth(2026, 13);
      expect((month.year, month.month), (2027, 1));
      expect(ColombiaMonth(2026, 0), ColombiaMonth(2025, 12));
    });
  });

  group('orden e igualdad', () {
    test('isAfter e isBefore cruzan de ano', () {
      expect(ColombiaMonth(2027, 1).isAfter(ColombiaMonth(2026, 12)), isTrue);
      expect(ColombiaMonth(2026, 12).isBefore(ColombiaMonth(2027, 1)), isTrue);
      expect(ColombiaMonth(2026, 9).isAfter(ColombiaMonth(2026, 9)), isFalse);
      expect(ColombiaMonth(2026, 9).isBefore(ColombiaMonth(2026, 9)), isFalse);
    });

    test('compareTo ordena por ano y luego por mes', () {
      final months = [
        ColombiaMonth(2026, 3),
        ColombiaMonth(2025, 12),
        ColombiaMonth(2026, 1),
      ]..sort();
      expect(months, [
        ColombiaMonth(2025, 12),
        ColombiaMonth(2026, 1),
        ColombiaMonth(2026, 3),
      ]);
    });

    test('igualdad y hashCode por valor', () {
      expect(ColombiaMonth(2026, 9), ColombiaMonth(2026, 9));
      expect(ColombiaMonth(2026, 9).hashCode, ColombiaMonth(2026, 9).hashCode);
      expect(ColombiaMonth(2026, 9), isNot(ColombiaMonth(2026, 10)));
      expect(ColombiaMonth(2026, 9).toString(), 'ColombiaMonth(2026-09)');
    });
  });

  test('toColombiaLocal resta cinco horas', () {
    expect(
      toColombiaLocal(DateTime.utc(2026, 9, 1, 4, 30)),
      DateTime.utc(2026, 8, 31, 23, 30),
    );
  });
}
