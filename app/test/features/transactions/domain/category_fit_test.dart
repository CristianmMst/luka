import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/category_fit.dart';
import 'package:luka/features/transactions/domain/category_option.dart';

CategoryOption _c(
  String name, {
  String? slug,
  String? tag,
  bool system = true,
}) => CategoryOption(
  id: slug ?? name,
  name: name,
  isSystem: system,
  slug: slug,
  fiscalTag: tag,
);

void main() {
  final mercado = _c(
    'Mercado y supermercado',
    slug: 'mercado',
    tag: 'no_deducible',
  );
  final salud = _c(
    'Medicina prepagada y seguros de salud',
    slug: 'medicina_prepagada',
    tag: 'deducible_salud',
  );
  final nomina = _c('Nómina y salario', slug: 'nomina', tag: 'ingreso_laboral');
  final sinCategoria = _c(
    'Sin categoría',
    slug: 'sin_categoria',
    tag: 'no_deducible',
  );
  final transferencias = _c(
    'Transferencias entre cuentas propias',
    slug: 'transferencias',
    tag: 'transferencia',
  );
  final propiaIngreso = _c('Ventas', tag: 'ingreso_no_laboral', system: false);
  final propiaGasto = _c('Mascotas', tag: 'no_deducible', system: false);
  final sinEtiqueta = _c('Vieja', system: false);

  group('fitsDirection', () {
    test('las de ingreso solo van con ingresos', () {
      expect(fitsDirection(nomina, TxDirection.credit), isTrue);
      expect(fitsDirection(nomina, TxDirection.debit), isFalse);
      expect(fitsDirection(propiaIngreso, TxDirection.credit), isTrue);
      expect(fitsDirection(propiaIngreso, TxDirection.debit), isFalse);
    });

    test('gastos, aportes y deducibles solo van con gastos', () {
      expect(fitsDirection(mercado, TxDirection.debit), isTrue);
      expect(fitsDirection(mercado, TxDirection.credit), isFalse);
      expect(fitsDirection(salud, TxDirection.debit), isTrue);
      expect(fitsDirection(propiaGasto, TxDirection.credit), isFalse);
    });

    test('"Sin categoría" y las que no tienen etiqueta van con ambos', () {
      for (final direction in TxDirection.values) {
        expect(fitsDirection(sinCategoria, direction), isTrue);
        expect(fitsDirection(sinEtiqueta, direction), isTrue);
      }
    });

    test('las transferencias no se registran a mano', () {
      for (final direction in TxDirection.values) {
        expect(fitsDirection(transferencias, direction), isFalse);
      }
    });
  });

  group('categoriesFor', () {
    final all = [mercado, salud, nomina, sinCategoria, transferencias];

    test('filtra por tipo y conserva el orden', () {
      expect(categoriesFor(all, TxDirection.debit), [
        mercado,
        salud,
        sinCategoria,
      ]);
      expect(categoriesFor(all, TxDirection.credit), [nomina, sinCategoria]);
    });

    test('busca sin tildes ni mayúsculas en el nombre', () {
      expect(
        categoriesFor(all, TxDirection.debit, query: 'SALUD'),
        [salud],
      );
      expect(
        categoriesFor(all, TxDirection.credit, query: 'nomina'),
        [nomina],
      );
      expect(categoriesFor(all, TxDirection.debit, query: '  '), [
        mercado,
        salud,
        sinCategoria,
      ]);
      expect(categoriesFor(all, TxDirection.debit, query: 'xyz'), isEmpty);
    });
  });
}
