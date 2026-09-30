import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/search.dart';
import 'package:luka/features/transactions/domain/transaction_view.dart';

TransactionView _tx({
  String? merchant,
  String? categoryName,
  String? bank,
  String? notes,
}) => TransactionView(
  id: 't1',
  amount: Cop.pesos(10000),
  direction: TxDirection.debit,
  kind: TxKind.expense,
  occurredAt: DateTime.utc(2026, 9, 22, 15),
  channels: const {},
  sync: SyncMark.none,
  merchant: merchant,
  categoryName: categoryName,
  bank: bank,
  notes: notes,
);

void main() {
  group('normalizeForSearch', () {
    test('quita tildes y pasa a minusculas', () {
      expect(normalizeForSearch('ÉXITO Calle 80'), 'exito calle 80');
    });

    test('el resultado contiene la version sin tildes de la busqueda', () {
      expect(normalizeForSearch('ÉXITO Calle 80'), contains('exito calle'));
    });

    test('normaliza enies y otras vocales acentuadas', () {
      expect(normalizeForSearch('Peña Núñez'), 'pena nunez');
    });

    test('cadena vacia queda vacia', () {
      expect(normalizeForSearch(''), '');
    });
  });

  group('matchesText', () {
    test('coincide ignorando tildes y mayusculas en el comercio', () {
      final tx = _tx(merchant: 'Éxito Calle 80');
      expect(matchesText(tx, 'exito'), isTrue);
      expect(matchesText(tx, 'EXITO CALLE'), isTrue);
    });

    test('busqueda vacia siempre coincide', () {
      final tx = _tx(merchant: 'Éxito');
      expect(matchesText(tx, ''), isTrue);
      expect(matchesText(tx, '   '), isTrue);
    });

    test('no coincide si el texto no aparece en ningun campo', () {
      final tx = _tx(
        merchant: 'Éxito',
        categoryName: 'Mercado',
        bank: 'Bancolombia',
      );
      expect(matchesText(tx, 'walmart'), isFalse);
    });

    test('tambien busca en categoria y notas', () {
      expect(
        matchesText(_tx(categoryName: 'Transporte'), 'transporte'),
        isTrue,
      );
      expect(
        matchesText(_tx(notes: 'Almuerzo con el equipo'), 'almuerzo'),
        isTrue,
      );
    });

    test('el banco no se busca aqui: tiene su propio filtro', () {
      final tx = _tx(bank: 'Bancolombia');
      expect(matchesText(tx, 'bancolombia'), isFalse);
    });
  });
}
