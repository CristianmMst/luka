import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/nfc/application/nfc_actions.dart';
import 'package:luka/features/nfc/domain/nfc_ports.dart';
import 'package:luka/features/transactions/application/transaction_actions.dart';
import 'package:luka/features/transactions/domain/manual_draft.dart';
import 'package:mocktail/mocktail.dart';

class _Store extends Mock implements NfcTagStore {}

class _Service extends Mock implements NfcService {}

class _Transactions extends Mock implements TransactionActions {}

final _now = DateTime.utc(2026, 9, 29, 15, 30);

void main() {
  late _Store store;
  late _Service service;
  late _Transactions transactions;
  late NfcActions actions;

  setUpAll(() {
    registerFallbackValue(const NfcTagTemplate(id: 'x', name: 'x'));
    registerFallbackValue(ManualDraft(occurredAt: _now));
    registerFallbackValue(Uri());
  });

  setUp(() {
    store = _Store();
    service = _Service();
    transactions = _Transactions();
    when(() => store.upsert(any())).thenAnswer((_) async {});
    when(() => store.remove(any())).thenAnswer((_) async {});
    when(() => service.write(any())).thenAnswer((_) async {});
    when(() => transactions.create(any())).thenAnswer((_) async => 'local-1');
    actions = NfcActions(
      store: store,
      service: service,
      transactions: transactions,
      now: () => _now,
      newId: () => 'nuevo-id',
    );
  });

  test('guardar una plantilla nueva le da id y recorta los textos', () async {
    final saved = await actions.save(
      const NfcTagTemplate(
        id: '',
        name: '  Café de la oficina ',
        categoryId: 'c-rest',
        note: '  ',
      ),
    );

    expect(saved.id, 'nuevo-id');
    expect(saved.name, 'Café de la oficina');
    expect(saved.note, isNull);
    verify(() => store.upsert(saved)).called(1);
  });

  test('editar conserva el id', () async {
    final saved = await actions.save(
      const NfcTagTemplate(id: 't-1', name: 'Parqueadero'),
    );
    expect(saved.id, 't-1');
  });

  test('escribir manda el enlace de la plantilla al tag', () async {
    await actions.writeTag(const NfcTagTemplate(id: 't-1', name: 'Café'));

    final uri = verify(() => service.write(captureAny())).captured.single;
    expect(uri.toString(), 'luka://quick-add?tag=t-1');
  });

  test('el registro rápido crea el gasto con el tag, ahora', () async {
    final id = await actions.saveQuickAdd(
      tagId: 't-1',
      amount: Cop.pesos(8500),
      categoryId: 'c-rest',
      accountId: 'a-1',
      note: 'tinto',
    );

    expect(id, 'local-1');
    final draft =
        verify(() => transactions.create(captureAny())).captured.single
            as ManualDraft;
    expect(draft.amount, Cop.pesos(8500));
    expect(draft.occurredAt, _now);
    expect(draft.categoryId, 'c-rest');
    expect(draft.accountId, 'a-1');
    expect(draft.nfcTagId, 't-1');
    expect(draft.toNewTransaction().notes, 'tinto');
    verifyNever(() => store.upsert(any()));
  });

  test('un tag desconocido se puede guardar como plantilla', () async {
    await actions.saveQuickAdd(
      tagId: 't-9',
      amount: Cop.pesos(5000),
      categoryId: 'c-trans',
      rememberAs: 'Parqueadero',
    );

    final saved =
        verify(() => store.upsert(captureAny())).captured.single
            as NfcTagTemplate;
    expect(saved.id, 't-9');
    expect(saved.name, 'Parqueadero');
    expect(saved.categoryId, 'c-trans');
  });

  test('si el gasto no se pudo encolar no se guarda la plantilla', () async {
    when(() => transactions.create(any())).thenThrow(StateError('sin base'));

    await expectLater(
      actions.saveQuickAdd(
        tagId: 't-9',
        amount: Cop.pesos(5000),
        rememberAs: 'Parqueadero',
      ),
      throwsStateError,
    );
    verifyNever(() => store.upsert(any()));
  });

  test('borrar quita la plantilla', () async {
    await actions.delete('t-1');
    verify(() => store.remove('t-1')).called(1);
  });
}
