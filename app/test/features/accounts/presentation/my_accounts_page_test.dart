import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';
import 'package:luka/features/accounts/presentation/my_accounts_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _Actions extends Mock implements AccountActions {}

class _Store extends Mock implements AccountsStore {}

const _nomina = LinkedAccount(
  id: 'a-1',
  bank: 'bancolombia',
  kind: 'savings',
  last4: '4821',
  alias: 'Nómina',
  transactionCount: 12,
);

const _nequi = LinkedAccount(
  id: 'a-2',
  bank: 'nequi',
  kind: 'wallet',
  transactionCount: 1,
);

void main() {
  late _Actions actions;
  late _Store store;

  setUp(() {
    actions = _Actions();
    store = _Store();
    when(() => actions.delete(any())).thenAnswer((_) async {});
  });

  Future<void> pumpPage(WidgetTester tester, List<LinkedAccount> all) async {
    when(() => store.watchAll()).thenAnswer((_) => Stream.value(all));
    await tester.pumpApp(
      const MyAccountsPage(),
      overrides: [
        accountActionsProvider.overrideWithValue(actions),
        accountsStoreProvider.overrideWithValue(store),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista las cuentas con alias o banco y su detalle', (
    tester,
  ) async {
    await pumpPage(tester, const [_nomina, _nequi]);

    expect(find.text('Nómina'), findsOneWidget);
    expect(find.text('Bancolombia · Ahorros ···4821'), findsOneWidget);
    expect(find.text('Nequi'), findsOneWidget);
    expect(find.text('Nequi · Billetera'), findsOneWidget);
    expect(find.byTooltip('Editar Nómina'), findsOneWidget);
    expect(find.byTooltip('Borrar Nequi'), findsOneWidget);
  });

  testWidgets('sin cuentas invita a agregar', (tester) async {
    await pumpPage(tester, const []);

    expect(find.textContaining('Aún no tienes cuentas'), findsOneWidget);
    expect(find.text('Agregar cuenta'), findsOneWidget);
  });

  testWidgets('borrar pide confirmación con el conteo y borra', (
    tester,
  ) async {
    await pumpPage(tester, const [_nomina]);

    await tester.tap(find.byTooltip('Borrar Nómina'));
    await tester.pumpAndSettle();
    expect(find.text('¿Borrar «Nómina»?'), findsOneWidget);
    expect(
      find.textContaining('Sus 12 movimientos quedan sin cuenta.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Borrar cuenta'));
    await tester.pumpAndSettle();

    verify(() => actions.delete('a-1')).called(1);
    expect(find.text('Cuenta borrada'), findsOneWidget);
  });

  testWidgets('cancelar no borra', (tester) async {
    await pumpPage(tester, const [_nomina]);

    await tester.tap(find.byTooltip('Borrar Nómina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(() => actions.delete(any()));
  });

  testWidgets('si borrar falla sin conexión, lo dice', (tester) async {
    when(() => actions.delete(any())).thenThrow(const AccountOffline());
    await pumpPage(tester, const [_nomina]);

    await tester.tap(find.byTooltip('Borrar Nómina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar cuenta'));
    await tester.pumpAndSettle();

    expect(
      find.text('Necesitas conexión para agregar, editar o borrar cuentas.'),
      findsOneWidget,
    );
  });

  testWidgets('las acciones miden 48 dp o más', (tester) async {
    await pumpPage(tester, const [_nomina]);

    for (final icon in [Icons.edit_outlined, Icons.delete_outline_rounded]) {
      final size = tester.getSize(find.widgetWithIcon(IconButton, icon));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });
}
