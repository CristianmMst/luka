import 'package:finanzia/features/categories/application/category_actions.dart';
import 'package:finanzia/features/categories/domain/categories_ports.dart';
import 'package:finanzia/features/categories/presentation/my_categories_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _Actions extends Mock implements CategoryActions {}

class _Store extends Mock implements CategoriesStore {}

const _mascotas = OwnCategory(
  id: 'c-1',
  name: 'Mascotas',
  fiscalTag: 'no_deducible',
  transactionCount: 12,
  icon: 'pets',
  color: '#6B4C9A',
);

const _arriendo = OwnCategory(
  id: 'c-2',
  name: 'Arriendo apartaestudio',
  fiscalTag: 'ingreso_capital',
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

  Future<void> pumpPage(
    WidgetTester tester,
    List<OwnCategory> own,
  ) async {
    when(() => store.watchOwn()).thenAnswer((_) => Stream.value(own));
    await tester.pumpApp(
      const MyCategoriesPage(),
      overrides: [
        categoryActionsProvider.overrideWithValue(actions),
        categoriesStoreProvider.overrideWithValue(store),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista las propias con su etiqueta y conteo', (tester) async {
    await pumpPage(tester, const [_arriendo, _mascotas]);

    expect(find.text('Mascotas'), findsOneWidget);
    expect(find.text('Gasto personal · 12 movimientos'), findsOneWidget);
    expect(
      find.text('Arriendos, intereses o rendimientos · 1 movimiento'),
      findsOneWidget,
    );
    expect(find.byTooltip('Editar Mascotas'), findsOneWidget);
    expect(find.byTooltip('Borrar Mascotas'), findsOneWidget);
  });

  testWidgets('sin propias muestra cómo empezar', (tester) async {
    await pumpPage(tester, const []);

    expect(find.textContaining('Aún no tienes categorías propias'), findsOne);
    expect(find.text('Nueva categoría'), findsOneWidget);
  });

  testWidgets('borrar pide confirmación con el conteo y borra', (
    tester,
  ) async {
    await pumpPage(tester, const [_mascotas]);

    await tester.tap(find.byTooltip('Borrar Mascotas'));
    await tester.pumpAndSettle();
    expect(find.text('¿Borrar «Mascotas»?'), findsOneWidget);
    expect(
      find.textContaining('Sus 12 movimientos pasan a Sin categoría.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Borrar categoría'));
    await tester.pumpAndSettle();

    verify(() => actions.delete('c-1')).called(1);
    expect(find.text('Categoría borrada'), findsOneWidget);
  });

  testWidgets('cancelar no borra', (tester) async {
    await pumpPage(tester, const [_mascotas]);

    await tester.tap(find.byTooltip('Borrar Mascotas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(() => actions.delete(any()));
  });

  testWidgets('si borrar falla sin conexión, lo dice', (tester) async {
    when(() => actions.delete(any())).thenThrow(const CategoryOffline());
    await pumpPage(tester, const [_mascotas]);

    await tester.tap(find.byTooltip('Borrar Mascotas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar categoría'));
    await tester.pumpAndSettle();

    expect(
      find.text('Necesitas conexión para crear, editar o borrar categorías.'),
      findsOneWidget,
    );
  });

  testWidgets('las acciones miden 48 dp o más', (tester) async {
    await pumpPage(tester, const [_mascotas]);

    for (final icon in [Icons.edit_outlined, Icons.delete_outline_rounded]) {
      final size = tester.getSize(find.widgetWithIcon(IconButton, icon));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.text('Nueva categoría'),
              matching: find.byWidgetPredicate((w) => w is OutlinedButton),
            ),
          )
          .height,
      greaterThanOrEqualTo(48),
    );
  });
}
