import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/categories/application/category_actions.dart';
import 'package:luka/features/categories/domain/categories_ports.dart';
import 'package:luka/features/categories/domain/category_draft.dart';
import 'package:luka/features/categories/presentation/category_form_sheet.dart';
import 'package:luka/features/sync/domain/synced_models.dart';
import 'package:luka/features/transactions/application/transactions_providers.dart';
import 'package:luka/features/transactions/domain/category_option.dart';
import 'package:luka/features/transactions/domain/transactions_repository.dart';
import 'package:luka/features/transactions/presentation/widgets/category_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _Actions extends Mock implements CategoryActions {}

class _Transactions extends Mock implements TransactionsRepository {}

const _created = SyncedCategory(
  id: 'c-1',
  name: 'Mascotas',
  fiscalTag: 'ingreso_laboral',
  isSystem: false,
  userId: 'u-1',
  icon: 'pets',
  color: '#6B4C9A',
);

/// Toca [finder] después de desplazar la hoja hasta verlo.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  late _Actions actions;
  late _Transactions transactions;

  setUpAll(() => registerFallbackValue(const CategoryDraft(name: 'x')));

  setUp(() {
    actions = _Actions();
    transactions = _Transactions();
    when(() => actions.create(any())).thenAnswer((_) async => _created);
    when(
      () => actions.update(any(), any()),
    ).thenAnswer((_) async => _created);
    when(() => transactions.watchCategories()).thenAnswer(
      (_) => Stream.value(const [
        CategoryOption(
          id: 'c-mer',
          name: 'Mercado',
          isSystem: true,
          slug: 'mercado',
        ),
      ]),
    );
  });

  /// Pantalla con un botón que abre [open] y muestra lo que devolvió.
  Future<void> pumpHost(
    WidgetTester tester,
    Future<Object?> Function(BuildContext) open,
  ) async {
    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: StatefulBuilder(
                builder: (context, setState) => TextButton(
                  onPressed: () async {
                    final result = await open(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('resultado: $result')),
                      );
                    }
                  },
                  child: const Text('abrir'),
                ),
              ),
            );
          },
        ),
      ),
      overrides: [
        categoryActionsProvider.overrideWithValue(actions),
        transactionsRepositoryProvider.overrideWithValue(transactions),
      ],
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('crea con nombre, ícono, color y etiqueta elegidos', (
    tester,
  ) async {
    await pumpHost(tester, CategoryFormSheet.show);

    expect(find.text('Nueva categoría'), findsOneWidget);
    expect(find.text('Gasto personal'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Mascotas ');
    await _tap(tester, find.bySemanticsLabel('Ícono Mascota'));
    await _tap(tester, find.bySemanticsLabel('Color Morado'));
    await tester.pump();
    await _tap(tester, find.text('Gasto personal'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Salario'));
    await tester.pumpAndSettle();
    expect(find.text('Salario'), findsOneWidget);
    await _tap(tester, find.text('Crear categoría'));
    await tester.pumpAndSettle();

    final draft =
        verify(() => actions.create(captureAny())).captured.single
            as CategoryDraft;
    expect(draft.name, '  Mascotas ');
    expect(draft.icon, 'pets');
    expect(draft.color, '#6B4C9A');
    expect(draft.fiscalTag, 'ingreso_laboral');
    expect(find.text('Nueva categoría'), findsNothing);
    expect(find.textContaining('resultado: SyncedCategory'), findsOneWidget);
  });

  testWidgets('sin nombre avisa y no envía', (tester) async {
    await pumpHost(tester, CategoryFormSheet.show);

    await _tap(tester, find.text('Crear categoría'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe un nombre.'), findsOneWidget);
    verifyNever(() => actions.create(any()));
  });

  testWidgets('nombre repetido se avisa bajo el campo', (tester) async {
    when(
      () => actions.create(any()),
    ).thenThrow(const CategoryDuplicateName());
    await pumpHost(tester, CategoryFormSheet.show);

    await tester.enterText(find.byType(TextField), 'Donaciones');
    await _tap(tester, find.text('Crear categoría'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ya existe una categoría con ese nombre (tuya o de luka).'),
      findsOneWidget,
    );
    expect(find.text('Nueva categoría'), findsOneWidget);
  });

  testWidgets('sin conexión lo dice y la hoja sigue abierta', (tester) async {
    when(() => actions.create(any())).thenThrow(const CategoryOffline());
    await pumpHost(tester, CategoryFormSheet.show);

    await tester.enterText(find.byType(TextField), 'Mascotas');
    await _tap(tester, find.text('Crear categoría'));
    await tester.pumpAndSettle();

    expect(
      find.text('Necesitas conexión para crear, editar o borrar categorías.'),
      findsOneWidget,
    );
  });

  testWidgets('mientras guarda no deja volver a enviar', (tester) async {
    final pending = Completer<SyncedCategory>();
    when(() => actions.create(any())).thenAnswer((_) => pending.future);
    await pumpHost(tester, CategoryFormSheet.show);

    await tester.enterText(find.byType(TextField), 'Mascotas');
    await _tap(tester, find.text('Crear categoría'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(_created);
    await tester.pumpAndSettle();
    verify(() => actions.create(any())).called(1);
  });

  testWidgets('editar llega prellenado y guarda con update', (tester) async {
    const existing = OwnCategory(
      id: 'c-1',
      name: 'Gimnasio',
      fiscalTag: 'deducible_salud',
      transactionCount: 4,
      icon: 'fitness',
      color: '#45617A',
    );
    await pumpHost(
      tester,
      (context) => CategoryFormSheet.show(context, existing: existing),
    );

    expect(find.text('Editar categoría'), findsOneWidget);
    expect(find.text('Gimnasio'), findsOneWidget);
    expect(find.text('Salud prepagada o seguros de salud'), findsOneWidget);
    await _tap(tester, find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    final draft =
        verify(() => actions.update('c-1', captureAny())).captured.single
            as CategoryDraft;
    expect(draft.icon, 'fitness');
    expect(draft.fiscalTag, 'deducible_salud');
  });

  testWidgets('"+ Nueva categoría" del selector deja elegida la nueva', (
    tester,
  ) async {
    await pumpHost(
      tester,
      (context) => CategorySheet.show(context, selectedId: null),
    );

    await _tap(tester, find.text('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mascotas');
    await _tap(tester, find.text('Crear categoría'));
    await tester.pumpAndSettle();

    expect(find.text('resultado: (id: c-1, name: Mascotas)'), findsOneWidget);
  });

  testWidgets('en el filtro no se ofrece crear', (tester) async {
    await pumpHost(
      tester,
      (context) =>
          CategorySheet.show(context, selectedId: null, allowAll: true),
    );

    expect(find.text('Nueva categoría'), findsNothing);
  });
}
