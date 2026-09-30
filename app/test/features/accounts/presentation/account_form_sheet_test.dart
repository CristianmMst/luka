import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/accounts/domain/account_draft.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';
import 'package:luka/features/accounts/presentation/account_form_sheet.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _Actions extends Mock implements AccountActions {}

const _saved = SyncedAccount(
  id: 'a-1',
  bank: 'nequi',
  kind: 'wallet',
  last4: '9876',
);

const _existing = LinkedAccount(
  id: 'a-1',
  bank: 'bancolombia',
  kind: 'savings',
  last4: '4821',
  alias: 'Nómina',
  transactionCount: 3,
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late _Actions actions;

  setUpAll(() => registerFallbackValue(const AccountDraft()));

  setUp(() {
    actions = _Actions();
    when(() => actions.create(any())).thenAnswer((_) async => _saved);
    when(() => actions.update(any(), any())).thenAnswer((_) async => _saved);
  });

  Future<void> open(WidgetTester tester, {LinkedAccount? existing}) async {
    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                final result = await AccountFormSheet.show(
                  context,
                  existing: existing,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('resultado: ${result?.id}')),
                  );
                }
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
      overrides: [accountActionsProvider.overrideWithValue(actions)],
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('crea con banco, tipo, últimos 4 y alias', (tester) async {
    await open(tester);
    expect(find.text('Nueva cuenta'), findsOneWidget);

    await _tap(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.text('Nequi').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Billetera'));
    await tester.enterText(find.byType(TextField).at(0), '9876');
    await tester.enterText(find.byType(TextField).at(1), 'Bolsillo');
    await _tap(tester, find.text('Guardar cuenta'));

    final draft =
        verify(() => actions.create(captureAny())).captured.single
            as AccountDraft;
    expect(draft.bank, 'nequi');
    expect(draft.kind, 'wallet');
    expect(draft.last4, '9876');
    expect(draft.alias, 'Bolsillo');
    expect(find.text('resultado: a-1'), findsOneWidget);
  });

  testWidgets('sin banco no envía y lo pide', (tester) async {
    await open(tester);

    await _tap(tester, find.text('Guardar cuenta'));

    expect(find.text('Elige el banco.'), findsOneWidget);
    verifyNever(() => actions.create(any()));
  });

  testWidgets('una cuenta repetida se avisa bajo los últimos 4', (
    tester,
  ) async {
    when(() => actions.create(any())).thenThrow(const AccountDuplicate());
    await open(tester);

    await _tap(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.text('BBVA').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Guardar cuenta'));

    expect(
      find.text('Ya tienes una cuenta de ese banco con esos últimos 4.'),
      findsOneWidget,
    );
    expect(find.text('Nueva cuenta'), findsOneWidget);
  });

  testWidgets('sin conexión lo dice y no cierra', (tester) async {
    when(() => actions.create(any())).thenThrow(const AccountOffline());
    await open(tester);

    await _tap(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.text('Nequi').last);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Guardar cuenta'));

    expect(
      find.text('Necesitas conexión para agregar, editar o borrar cuentas.'),
      findsOneWidget,
    );
  });

  testWidgets('editar precarga los datos y no deja cambiar el banco', (
    tester,
  ) async {
    await open(tester, existing: _existing);

    expect(find.text('Editar cuenta'), findsOneWidget);
    expect(find.text('Bancolombia'), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
    expect(find.text('Nómina'), findsOneWidget);
    expect(find.textContaining('El banco no se puede cambiar'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '');
    await _tap(tester, find.text('Guardar'));

    final captured = verify(
      () => actions.update(captureAny(), captureAny()),
    ).captured;
    expect(captured[0], 'a-1');
    final draft = captured[1] as AccountDraft;
    expect(draft.bank, 'bancolombia');
    expect(draft.alias, '');
  });
}
