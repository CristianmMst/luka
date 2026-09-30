import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';
import 'package:luka/features/accounts/presentation/account_picker_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _Store extends Mock implements AccountsStore {}

const _nomina = LinkedAccount(
  id: 'a-1',
  bank: 'bancolombia',
  kind: 'savings',
  last4: '8761',
  alias: 'Nómina',
  transactionCount: 3,
);

void main() {
  late _Store store;

  setUp(() {
    store = _Store();
    when(() => store.watchAll()).thenAnswer((_) => Stream.value([_nomina]));
  });

  Future<void> open(WidgetTester tester, {String? selectedId}) async {
    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                final pick = await AccountPickerSheet.show(
                  context,
                  selectedId: selectedId,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        pick == null
                            ? 'cerrada'
                            : 'elegida ${pick.id} ${pick.name}',
                      ),
                    ),
                  );
                }
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
      overrides: [accountsStoreProvider.overrideWithValue(store)],
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista las cuentas y devuelve la elegida', (tester) async {
    await open(tester);

    expect(find.text('Bancolombia · Ahorros ···8761'), findsOneWidget);
    await tester.tap(find.text('Nómina'));
    await tester.pumpAndSettle();

    expect(find.text('elegida a-1 Nómina'), findsOneWidget);
  });

  testWidgets('"Sin cuenta" devuelve la elección vacía', (tester) async {
    await open(tester, selectedId: 'a-1');

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.tap(find.text('Sin cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('elegida null null'), findsOneWidget);
  });

  testWidgets('"Agregar cuenta" abre la hoja de cuenta', (tester) async {
    await open(tester);

    await tester.tap(find.text('Agregar cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Nueva cuenta'), findsOneWidget);
  });
}
