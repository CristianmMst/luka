import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/accounts/application/account_actions.dart';
import 'package:luka/features/accounts/domain/accounts_ports.dart';
import 'package:luka/features/nfc/application/nfc_actions.dart';
import 'package:luka/features/nfc/domain/nfc_ports.dart';
import 'package:luka/features/nfc/presentation/nfc_tags_page.dart';
import 'package:luka/features/nfc/presentation/nfc_write_screen.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/domain/transactions_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _Store extends Mock implements NfcTagStore {}

class _Service extends Mock implements NfcService {}

class _Accounts extends Mock implements AccountsStore {}

class _Transactions extends Mock implements TransactionsRepository {}

const _cafe = NfcTagTemplate(
  id: 't-1',
  name: 'Café de la oficina',
  categoryId: 'c-rest',
);

void main() {
  late _Store store;
  late _Service service;
  late _Accounts accounts;
  late _Transactions transactions;
  late Completer<void> write;

  setUpAll(() {
    registerFallbackValue(const NfcTagTemplate(id: 'x', name: 'x'));
    registerFallbackValue(Uri());
  });

  setUp(() {
    store = _Store();
    service = _Service();
    accounts = _Accounts();
    transactions = _Transactions();
    when(() => store.upsert(any())).thenAnswer((_) async {});
    when(() => store.remove(any())).thenAnswer((_) async {});
    when(() => service.write(any())).thenAnswer((_) => write.future);
    when(() => service.cancel()).thenAnswer((_) async {});
    when(() => accounts.watchAll()).thenAnswer((_) => Stream.value(const []));
    when(() => transactions.watchCategories()).thenAnswer(
      (_) => Stream.value(const [
        CategoryOption(id: 'c-rest', name: 'Restaurantes', isSystem: true),
      ]),
    );
  });

  Future<void> pumpPage(WidgetTester tester, List<NfcTagTemplate> tags) async {
    // El Completer se crea dentro de la zona del test para que su future
    // avance con los pump.
    write = Completer<void>();
    when(() => store.watchAll()).thenAnswer((_) => Stream.value(tags));
    await tester.pumpApp(
      const NfcTagsPage(),
      overrides: [
        nfcTagStoreProvider.overrideWithValue(store),
        nfcServiceProvider.overrideWithValue(service),
        nfcWriteSupportedProvider.overrideWithValue(true),
        accountsStoreProvider.overrideWithValue(accounts),
        transactionsRepositoryProvider.overrideWithValue(transactions),
      ],
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('lista los tags con su categoría', (tester) async {
    await pumpPage(tester, const [_cafe]);

    expect(find.text('Café de la oficina'), findsOneWidget);
    expect(find.text('Restaurantes'), findsOneWidget);
    expect(find.byTooltip('Editar Café de la oficina'), findsOneWidget);
  });

  testWidgets('sin tags invita a crear uno', (tester) async {
    await pumpPage(tester, const []);

    expect(find.textContaining('Aún no tienes tags'), findsOneWidget);
  });

  testWidgets('crear pide nombre, guarda y abre la escritura', (tester) async {
    await pumpPage(tester, const []);

    await tapVisible(tester, find.text('Nuevo tag'));
    await tapVisible(tester, find.text('Guardar y escribir en un tag'));
    expect(find.text('Escribe un nombre.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Parqueadero');
    await tapVisible(tester, find.text('Guardar y escribir en un tag'));

    final saved =
        verify(() => store.upsert(captureAny())).captured.single
            as NfcTagTemplate;
    expect(saved.name, 'Parqueadero');
    expect(find.byType(NfcWriteScreen), findsOneWidget);
    expect(find.text('Acerca el tag al teléfono'), findsOneWidget);
    final uri = verify(() => service.write(captureAny())).captured.single;
    expect(uri.toString(), 'luka://quick-add?tag=${saved.id}');

    write.complete();
    await tester.pumpAndSettle();
    expect(find.text('Tag listo'), findsOneWidget);
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(find.byType(NfcWriteScreen), findsNothing);
  });

  testWidgets('un error de escritura se explica y se puede reintentar', (
    tester,
  ) async {
    await pumpPage(tester, const [_cafe]);
    await tapVisible(tester, find.byTooltip('Editar Café de la oficina'));
    await tapVisible(tester, find.text('Escribir en un tag'));

    write.completeError(const NfcTagNotWritable());
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Este tag no se puede escribir (es de solo lectura o no es '
        'NDEF).',
      ),
      findsOneWidget,
    );

    write = Completer<void>()..complete();
    await tester.tap(find.text('Intentar de nuevo'));
    await tester.pumpAndSettle();
    expect(find.text('Tag listo'), findsOneWidget);
  });

  testWidgets('borrar quita la plantilla', (tester) async {
    await pumpPage(tester, const [_cafe]);
    await tapVisible(tester, find.byTooltip('Editar Café de la oficina'));

    await tapVisible(tester, find.text('Borrar tag'));

    verify(() => store.remove('t-1')).called(1);
  });
}
