import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/sync/domain/outbox_operation.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/domain/manual_draft.dart';

void main() {
  final at = DateTime.utc(2026, 9, 25, 20, 42);

  test('por defecto es un gasto', () {
    expect(ManualDraft(occurredAt: at).direction, TxDirection.debit);
  });

  test('sin monto o con monto en cero no es válido', () {
    expect(ManualDraft(occurredAt: at).validate(), {
      ManualDraftError.amountRequired,
    });
    expect(ManualDraft(occurredAt: at, amount: Cop.pesos(0)).validate(), {
      ManualDraftError.amountRequired,
    });
    expect(
      ManualDraft(occurredAt: at, amount: Cop.pesos(1)).validate(),
      isEmpty,
    );
  });

  test('toNewTransaction recorta textos y deja vacíos en null', () {
    final draft = ManualDraft(
      occurredAt: at,
      amount: Cop.pesos(12500),
      direction: TxDirection.credit,
      merchant: '  Panadería  ',
      notes: '   ',
      categoryId: 'c-1',
    );
    expect(
      draft.toNewTransaction(),
      NewTransaction(
        amount: Cop.pesos(12500),
        direction: TxDirection.credit,
        occurredAt: at,
        merchant: 'Panadería',
        categoryId: 'c-1',
      ),
    );
  });

  test('toNewTransaction con un borrador inválido falla', () {
    expect(
      () => ManualDraft(occurredAt: at).toNewTransaction(),
      throwsA(isA<InvalidManualDraft>()),
    );
  });

  test('toNewTransaction lleva la cuenta y el tag NFC', () {
    final draft = ManualDraft(
      occurredAt: at,
      amount: Cop.pesos(8500),
      accountId: 'a-1',
      nfcTagId: 'tag-1',
    );
    final data = draft.toNewTransaction();
    expect(data.accountId, 'a-1');
    expect(data.nfcTagId, 'tag-1');
  });
}
